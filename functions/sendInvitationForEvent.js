import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { Timestamp, FieldValue } from "firebase-admin/firestore";
import { db } from "./admin.js";
import { getStorage } from "firebase-admin/storage";

import postmark from "postmark";
import { randomBytes } from "crypto";

const POSTMARK_SERVER_TOKEN = defineSecret("POSTMARK_SERVER_TOKEN");

// Config
const FROM_EMAIL = "developer@trax-event.com";
const FROM_NAME = "Trax Events";
const APP_BASE_URL = "https://trax-event.app";
const INV_EXPIRY_DAYS = (() => {
  const raw = process.env.INV_EXPIRY_DAYS; // could be "0" or "0.01"
  const n = Number.parseInt(String(raw ?? "14"), 10);
  return Number.isFinite(n) && n >= 1 ? n : 14;
})();
const MESSAGE_STREAM = process.env.POSTMARK_MESSAGE_STREAM || "outbound";
const POINTERS_COL = "invitationPointers";

function emailLower(s) {
  return (s ?? "").toString().trim().toLowerCase();
}

function makeToken() {
  return randomBytes(24).toString("hex");
}

function makeInvitationCode(len = 8) {
  const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  const bytes = randomBytes(len);
  let out = "";
  for (let i = 0; i < len; i++) out += alphabet[bytes[i] % alphabet.length];
  return out;
}

function escapeHtml(s) {
  const str = (s ?? "").toString();
  return str
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function pickEarliestByCreatedAt(docs) {
  let chosen = docs[0];
  let chosenMs =
    chosen.data()?.createdAt?.toMillis?.() ?? Number.MAX_SAFE_INTEGER;

  for (const d of docs) {
    const ms = d.data()?.createdAt?.toMillis?.() ?? Number.MAX_SAFE_INTEGER;
    if (ms < chosenMs) {
      chosen = d;
      chosenMs = ms;
    }
  }
  return chosen;
}

function pointerId(eventId, guestId) {
  return `${eventId}_${guestId}`;
}

function buildCompanionRsvpLink(invId, invToken, companionIndex) {
  return (
    `${APP_BASE_URL}/companion-rsvp?invitationId=${encodeURIComponent(invId)}` +
    `&token=${encodeURIComponent(invToken)}` +
    `&companionIndex=${encodeURIComponent(String(companionIndex))}` +
    `&v=${Date.now()}`
  );
}


// ✅ Encode a GCS path but KEEP slashes.
// uploads/my photo.jpg -> uploads/my%20photo.jpg
function encodeGcsPath(path) {
  return String(path)
    .split("/")
    .map((seg) => encodeURIComponent(seg))
    .join("/");
}

// ✅ Robust URL resolver (URL passthrough, storage path -> public or signed)
async function resolveImageUrl(pathOrUrl, { signedDays = 30 } = {}) {
  const raw = (pathOrUrl ?? "").toString().trim();
  if (!raw) return "";

  // already a URL
  if (raw.startsWith("http://") || raw.startsWith("https://")) return raw;

  const storagePath = raw;
  const bucket = getStorage().bucket();
  const file = bucket.file(storagePath);

  const [exists] = await file.exists();
  if (!exists) {
    console.error(`❌ Storage file not found: ${storagePath}`);
    return "";
  }

  // Try makePublic (may fail if UBLA enabled)
  try {
    await file.makePublic();
    const publicUrl = `https://storage.googleapis.com/${bucket.name}/${encodeGcsPath(
      storagePath
    )}`;
    console.log(`✅ Public URL generated: ${publicUrl}`);
    return publicUrl;
  } catch (e) {
    console.warn("⚠️ makePublic failed, using signed URL:", e?.message ?? e);

    const [signedUrl] = await file.getSignedUrl({
      action: "read",
      expires: Date.now() + signedDays * 24 * 60 * 60 * 1000,
    });

    console.log(`✅ Signed URL generated for ${storagePath}`);
    return signedUrl;
  }
}

// Format date for display in email
function formatEventDate(timestamp) {
  if (!timestamp || !timestamp.toDate) return "";

  const date = timestamp.toDate();
  const options = {
    weekday: "long",
    year: "numeric",
    month: "long",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
    timeZoneName: "short",
  };

  return date.toLocaleString("en-US", options);
}

function personKeyFromIndex(idx) {
  if (idx === null || idx === undefined) return "main";
  return `c${idx}`;
}

function hasDemoForPerson(inv, key) {
  // Try common structures (keep this flexible)
  const byPerson =
    inv.demographicsByPerson?.[key] ||
    inv.demographicByPerson?.[key] ||
    inv.demographicResponsesByPerson?.[key] ||
    null;

  const t =
    byPerson?.submittedAt ||
    byPerson?.demographicsSubmittedAt ||
    null;

  return !!t;
}

function hasMenuForPerson(inv, key) {
  const m = inv.menuSelectionByPerson?.[key] || null;
  const t = m?.submittedAt || m?.menuSubmittedAt || null;
  return !!t;
}

function buildDetailsLink(invId, invToken) {
  return (
    `${APP_BASE_URL}/guest-response?invitationId=${encodeURIComponent(invId)}` +
    `&token=${encodeURIComponent(invToken)}` +
    `&forceDetails=1&v=${Date.now()}`
  );
}

function buildDemoLink(invId, invToken, companionIndex) {
  return (
    `${APP_BASE_URL}/demographics?invitationId=${encodeURIComponent(invId)}` +
    `&token=${encodeURIComponent(invToken)}` +
    `&companionIndex=${encodeURIComponent(String(companionIndex))}` +
    `&v=${Date.now()}`
  );
}

function buildMenuLink(invId, invToken, companionIndex) {
  return (
    `${APP_BASE_URL}/menu-selection?invitationId=${encodeURIComponent(invId)}` +
    `&token=${encodeURIComponent(invToken)}` +
    `&companionIndex=${encodeURIComponent(String(companionIndex))}` +
    `&v=${Date.now()}`
  );
}


export const sendInvitations = onCall(
  { secrets: [POSTMARK_SERVER_TOKEN] },
  async (request) => {
    try {
      if (!APP_BASE_URL) {
        throw new HttpsError("failed-precondition", "APP_BASE_URL missing");
      }

      const {
        eventId,
        organisationId,
        invitations,
        demographicQuestionSetId,
        invitationCode: eventInvitationCode,
      } = request.data || {};

      if (!eventId) throw new HttpsError("invalid-argument", "eventId is required");
      if (!Array.isArray(invitations) || invitations.length === 0) {
        throw new HttpsError("invalid-argument", "invitations array required");
      }

      const pmToken = (POSTMARK_SERVER_TOKEN.value() || "").trim();
      if (!pmToken) {
        throw new HttpsError(
          "failed-precondition",
          "POSTMARK_SERVER_TOKEN missing/empty at runtime."
        );
      }

      const client = new postmark.ServerClient(pmToken);
      const results = [];

      // ✅ Fetch event details once
      const eventDoc = await db.collection("events").doc(eventId).get();
      if (!eventDoc.exists) {
        throw new HttpsError("not-found", `Event ${eventId} not found`);
      }

      const eventData = eventDoc.data() || {};
      const eventName = eventData?.name || "Event";
      const eventAddress = eventData?.address || "";
      const eventStartDateTime = eventData?.startDateTime;
      const eventEndDateTime = eventData?.endDateTime;

      const coverPathOrUrl =
        (eventData?.coverImagePath || "").toString().trim() ||
        (eventData?.coverImageUrl || "").toString().trim() ||
        "";

      const eventImageUrl = await resolveImageUrl(coverPathOrUrl, { signedDays: 30 });

      const logoUrl = await resolveImageUrl("app_images/light-logo.png", {
        signedDays: 365,
      });

      const formattedStartDate = formatEventDate(eventStartDateTime);
      const formattedEndDate = formatEventDate(eventEndDateTime);

      function buildNormalLink(invId, invToken) {
        return (
          `${APP_BASE_URL}/guest-response?invitationId=${encodeURIComponent(invId)}` +
          `&token=${encodeURIComponent(invToken)}` +
          `&v=${Date.now()}`
        );
      }

      function buildDetailsLink(invId, invToken) {
        return (
          `${APP_BASE_URL}/guest-response?invitationId=${encodeURIComponent(invId)}` +
          `&token=${encodeURIComponent(invToken)}` +
          `&forceDetails=1&v=${Date.now()}`
        );
      }

      function buildCompanionRsvpLink(invId, invToken, companionIndex) {
        return (
          `${APP_BASE_URL}/companion-rsvp?invitationId=${encodeURIComponent(invId)}` +
          `&token=${encodeURIComponent(invToken)}` +
          `&companionIndex=${encodeURIComponent(String(companionIndex))}` +
          `&v=${Date.now()}`
        );
      }

      for (const guest of invitations) {
        const guestEmail = (guest?.guestEmail || "").trim();
        const guestName = (guest?.guestName || "").trim();
        const gid = (guest?.guestId ?? "").toString().trim();

        const maxGuestInvite =
          typeof guest?.maxGuestInvite === "number" ? guest.maxGuestInvite : 0;

        const batchId = guest?.batchId || null;

        if (!guestEmail) continue;

        const expiresAt = Timestamp.fromMillis(
          Date.now() + INV_EXPIRY_DAYS * 24 * 60 * 60 * 1000
        );

        let invRef = null;
        let invId = null;
        let invData = null;
        let invToken = null;
        let guestInvitationCode = null;

        let isCompanionInvite = false;
        let companionIndex = null;

        let finalLink = "";
        let ctaLabel = "Accept Invitation & RSVP";
        let headline = "You're Invited!";
        let bodyLine =
          "Please click the button below to confirm your attendance, complete your details, and select your menu preferences.";

        // ─────────────────────────────────────────────
        // ✅ 1) Detect companion guest
        // ─────────────────────────────────────────────
        if (gid) {
          try {
            const gSnap = await db.collection("guests").doc(gid).get();
            if (gSnap.exists) {
              const g = gSnap.data() || {};
              const parentInvId =
                (g.parentInvitationId || g.invitationId || "").toString().trim();

              if (g.isCompanion === true && parentInvId) {
                isCompanionInvite = true;

                const parentInvRef = db.collection("invitations").doc(parentInvId);
                const parentInvSnap = await parentInvRef.get();
                if (!parentInvSnap.exists) {
                  throw new Error(`Parent invitation ${parentInvId} not found`);
                }

                const parentInv = parentInvSnap.data() || {};
                invRef = parentInvRef;
                invId = parentInvId;
                invData = parentInv;

                invToken =
                  (g.parentInvitationToken || parentInv.token || "").toString().trim();

                if (!invToken) {
                  throw new Error(`Parent invitation token missing for ${parentInvId}`);
                }

                // companionIndex
                if (typeof g.companionIndex === "number") {
                  companionIndex = g.companionIndex;
                } else {
                  const comps = Array.isArray(parentInv.companions)
                    ? parentInv.companions
                    : [];
                  const idx = comps.findIndex((c) => (c?.guestId || "") === gid);
                  if (idx >= 0) companionIndex = idx;
                }
                if (companionIndex === null || companionIndex === undefined) {
                  companionIndex = 0;
                }

                guestInvitationCode =
                  (parentInv.invitationCode || "").toString().trim() || null;

                const invitingByEmail = parentInv.isInvitingCompanionsByEmail === true;

                if (!invitingByEmail) {
                  // ✅ main guest already added details → details-only link
                  finalLink = buildDetailsLink(invId, invToken);
                  ctaLabel = "View Event Details";
                  headline = "Event Details";
                  bodyLine =
                    "Your details were already submitted. Click below to view the event details and your responses.";
                } else {
                  // ✅ companion answers themselves → go to attendance page first
                  finalLink = buildCompanionRsvpLink(invId, invToken, companionIndex);
                  ctaLabel = "RSVP for Yourself";
                  headline = "You're Invited as a Companion!";
                  bodyLine =
                    "Please confirm whether you will attend, then complete your preferences.";
                }
              }
            }
          } catch (e) {
            console.error("⚠️ companion detection failed:", e);
            isCompanionInvite = false;
          }
        }

        // ─────────────────────────────────────────────
        // ✅ 2) Normal flow: create/reuse invitation
        // ─────────────────────────────────────────────
        if (!isCompanionInvite) {
          // CASE A: guestId exists (use pointer uniqueness)
          if (gid) {
            const ptrRef = db.collection(POINTERS_COL).doc(pointerId(eventId, gid));

            await db.runTransaction(async (tx) => {
              const ptrSnap = await tx.get(ptrRef);

              if (ptrSnap.exists) {
                invId = (ptrSnap.data()?.invitationId || "").toString().trim();
                if (!invId) throw new Error("Pointer has empty invitationId");

                invRef = db.collection("invitations").doc(invId);
                const snap = await tx.get(invRef);
                invData = snap.exists ? snap.data() || {} : {};
              } else {
                const q = db
                  .collection("invitations")
                  .where("eventId", "==", eventId)
                  .where("guestId", "==", gid)
                  .limit(10);

                const qSnap = await tx.get(q);

                if (!qSnap.empty) {
                  const chosen = pickEarliestByCreatedAt(qSnap.docs);
                  invRef = chosen.ref;
                  invId = chosen.id;
                  invData = chosen.data() || {};

                  tx.set(
                    ptrRef,
                    { eventId, guestId: gid, invitationId: invId, createdAt: Timestamp.now() },
                    { merge: true }
                  );
                } else {
                  invRef = db.collection("invitations").doc();
                  invId = invRef.id;
                  invData = {};

                  tx.set(ptrRef, {
                    eventId,
                    guestId: gid,
                    invitationId: invId,
                    createdAt: Timestamp.now(),
                  });
                }
              }

              const storedGid = (invData?.guestId ?? "").toString().trim();
              if (storedGid && storedGid !== gid) {
                throw new HttpsError(
                  "failed-precondition",
                  `Invitation collision: invitationId=${invId} belongs to guestId=${storedGid}, attempted guestId=${gid}`
                );
              }

              invToken = (invData?.token || "").toString().trim() || makeToken();
              guestInvitationCode =
                (invData?.invitationCode || "").toString().trim() || makeInvitationCode();

              tx.set(
                invRef,
                {
                  invitationId: invId,
                  eventId,
                  organisationId: organisationId || null,
                  guestId: gid,
                  guestEmail,
                  guestEmailLower: emailLower(guestEmail),
                  guestName,
                  maxGuestInvite,
                  demographicQuestionSetId: demographicQuestionSetId || null,
                  token: invToken,
                  invitationCode: guestInvitationCode,
                  ...(eventInvitationCode && { eventInvitationCode }),
                  createdAt: invData?.createdAt ?? Timestamp.now(),
                  expiresAt,
                  sent: false,
                  lastSendAttemptAt: Timestamp.now(),
                  ...(batchId && { batchId }),
                },
                { merge: true }
              );
            });

            finalLink = buildNormalLink(invId, invToken);
          } else {
            // CASE B: guestId missing -> always create new invitation
            invRef = db.collection("invitations").doc();
            invId = invRef.id;
            invToken = makeToken();
            guestInvitationCode = makeInvitationCode();

            await invRef.set(
              {
                invitationId: invId,
                eventId,
                organisationId: organisationId || null,
                guestId: null,
                guestEmail,
                guestEmailLower: emailLower(guestEmail),
                guestName,
                maxGuestInvite,
                demographicQuestionSetId: demographicQuestionSetId || null,
                token: invToken,
                invitationCode: guestInvitationCode,
                ...(eventInvitationCode && { eventInvitationCode }),
                createdAt: Timestamp.now(),
                expiresAt,
                sent: false,
                lastSendAttemptAt: Timestamp.now(),
                ...(batchId && { batchId }),
              },
              { merge: true }
            );

            finalLink = buildNormalLink(invId, invToken);
          }
        }

        // ✅ Subject depends on companion mode
        const subject = isCompanionInvite
          ? (ctaLabel === "View Event Details"
              ? `Event details for ${eventName}`
              : `You're invited as a companion to ${eventName}!`)
          : `You're Invited to ${eventName}!`;

        const formattedStart = formattedStartDate;
        const formattedEnd = formattedEndDate;

        // Text body uses bodyLine
        const textBody =
          `Hello${guestName ? " " + guestName : ""},\n\n` +
          `${isCompanionInvite ? "You have been invited as a companion" : "You're invited"} to ${eventName}!\n\n` +
          (eventAddress ? `Location: ${eventAddress}\n` : "") +
          (formattedStart ? `Start: ${formattedStart}\n` : "") +
          (formattedEnd ? `End: ${formattedEnd}\n` : "") +
          `\n` +
          `${bodyLine}\n${finalLink}\n\n` +
          `This link expires in ${INV_EXPIRY_DAYS} days.\n\n` +
          (guestInvitationCode ? `Invitation Code: ${guestInvitationCode}\n` : "") +
          `\nThank you,\nTrax Event`;

        const safeName = guestName ? escapeHtml(guestName) : "";
        const safeEventName = escapeHtml(eventName);
        const safeAddress = escapeHtml(eventAddress);

        const eventImageHtml = eventImageUrl
          ? `<img src="${eventImageUrl}" alt="${safeEventName}" style="width:100%;max-width:600px;max-height:150px;object-fit:cover;border-radius:8px;display:block;margin:0 auto 24px;" />`
          : "";

        const logoHtml = logoUrl
          ? `<img src="${logoUrl}" alt="Trax Event Logo" style="max-width:150px;height:auto;margin-bottom:15px;" />`
          : "";

        let eventDetailsHtml = "";
        if (formattedStart || formattedEnd || eventAddress) {
          eventDetailsHtml = `
            <div style="background:#f9fafb;border-left:4px solid #2563eb;padding:16px;margin:20px 0;border-radius:4px;">
              <h3 style="margin:0 0 12px;color:#1f2937;font-size:16px;font-weight:600;">Event Details</h3>`;
          if (formattedStart) {
            eventDetailsHtml += `<p style="margin:6px 0;color:#4b5563;font-size:14px;"><strong>Start:</strong> ${escapeHtml(formattedStart)}</p>`;
          }
          if (formattedEnd) {
            eventDetailsHtml += `<p style="margin:6px 0;color:#4b5563;font-size:14px;"><strong>End:</strong> ${escapeHtml(formattedEnd)}</p>`;
          }
          if (eventAddress) {
            eventDetailsHtml += `<p style="margin:6px 0;color:#4b5563;font-size:14px;"><strong>Location:</strong> ${safeAddress}</p>`;
          }
          eventDetailsHtml += `</div>`;
        }

        let htmlReferenceInfo = "";
        if (guestInvitationCode || batchId) {
          htmlReferenceInfo = `
            <div style="color:#6b7280;font-size:13px;margin-top:30px;padding-top:20px;border-top:1px solid #e5e7eb;">
              <strong>Reference Information:</strong><br/>`;
          if (guestInvitationCode) {
            htmlReferenceInfo += `Invitation Code: <strong>${escapeHtml(guestInvitationCode)}</strong><br/>`;
          }
          if (batchId) {
            htmlReferenceInfo += `Batch ID: <strong>${escapeHtml(batchId)}</strong>`;
          }
          htmlReferenceInfo += `</div>`;
        }

        const htmlBody = `
          <div style="font-family:'Segoe UI',Tahoma,Geneva,Verdana,sans-serif;line-height:1.6;color:#1f2937;max-width:600px;margin:0 auto;background:#ffffff;">
            ${eventImageHtml}
            <div style="padding:0 20px;">
              <h1 style="color:#1f2937;font-size:24px;margin:0 0 10px;font-weight:700;">${escapeHtml(headline)}</h1>

              <p style="font-size:16px;color:#4b5563;margin:10px 0;">
                Hello${safeName ? " " + safeName : ""},
              </p>

              <p style="font-size:16px;color:#1f2937;margin:16px 0;">
                ${isCompanionInvite ? "You are invited as a <strong>companion</strong> to " : "You have been invited to "}
                <strong>${safeEventName}</strong>!
              </p>

              ${eventDetailsHtml}

              <p style="font-size:15px;color:#4b5563;margin:20px 0;">
                ${escapeHtml(bodyLine)}
              </p>

              <div style="text-align:center;margin:30px 0;">
                <a href="${finalLink}" style="display:inline-block;padding:14px 28px;background:#2563eb;color:#ffffff;text-decoration:none;border-radius:8px;font-weight:600;font-size:16px;box-shadow:0 2px 4px rgba(0,0,0,0.1);">
                  ${escapeHtml(ctaLabel)}
                </a>
              </div>

              <div style="background:#f9fafb;padding:16px;border-radius:6px;margin:20px 0;">
                <p style="color:#6b7280;font-size:13px;margin:0 0 8px;">
                  If the button doesn't work, copy and paste this link into your browser:
                </p>
                <p style="margin:0;">
                  <a href="${finalLink}" style="color:#2563eb;font-size:13px;word-break:break-all;">${finalLink}</a>
                </p>
              </div>

              <p style="color:#9ca3af;font-size:13px;margin:20px 0 10px;">
                ⏱️ This invitation link expires in ${INV_EXPIRY_DAYS} days.
              </p>

              ${htmlReferenceInfo}

              <div style="margin:40px 0 20px;padding:20px 0;border-top:1px solid #e5e7eb;">
                <p style="font-size:15px;color:#4b5563;margin:0;">
                  Thank you,<br/>
                  <strong>Trax Event</strong>
                </p>
              </div>
            </div>

            <div style="background:#f9fafb;padding:30px 20px;text-align:center;border-top:2px solid #e5e7eb;">
              ${logoHtml}
              <p style="color:#6b7280;font-size:12px;margin:10px 0 0;">
                © ${new Date().getFullYear()} Trax Event. All rights reserved.
              </p>
            </div>
          </div>
        `;

        try {
          const resp = await client.sendEmail({
            From: `"${FROM_NAME}" <${FROM_EMAIL}>`,
            To: guestEmail,
            Subject: subject,
            TextBody: textBody,
            HtmlBody: htmlBody,
            MessageStream: MESSAGE_STREAM,
            Metadata: {
              invitationId: invId,
              eventId,
              guestId: gid || "",
              invitationCode: guestInvitationCode || "",
              isCompanion: isCompanionInvite ? "1" : "0",
              companionIndex: isCompanionInvite ? String(companionIndex ?? "") : "",
            },
          });

          results.push({
            guestEmail,
            guestId: gid || null,
            invitationId: invId,
            invitationCode: guestInvitationCode || null,
            status: "sent",
            isCompanion: isCompanionInvite,
            companionIndex: isCompanionInvite ? companionIndex : null,
          });

          // ✅ Update invitation send flags ONLY for normal invites
          if (!isCompanionInvite && invRef) {
            try {
              await invRef.update({
                sent: true,
                sentAt: Timestamp.now(),
                postmarkMessageId: resp.MessageID,
                sendError: null,
                sendErrorStatus: null,
                sendErrorBody: null,
                sendAttemptCount: FieldValue.increment(1),
                sendSuccessCount: FieldValue.increment(1),
              });
            } catch (e) {
              console.error("⚠️ invRef.update failed AFTER email sent:", e);
            }
          }

          // ✅ Always update guest doc
          try {
            if (gid) {
              await db.collection("guests").doc(gid).set(
                {
                  isInvited: true,
                  modifiedAt: Timestamp.now(),
                  lastInvitedAt: Timestamp.now(),
                  inviteSentCount: FieldValue.increment(1),
                },
                { merge: true }
              );
            }
          } catch (e) {
            console.error("⚠️ guest update failed AFTER email sent:", e);
          }
        } catch (err) {
          const status = err?.statusCode ?? err?.code ?? null;
          const msg = err?.message ?? String(err);
          const body = err?.response?.body ?? err?.body ?? null;

          if (!isCompanionInvite && invRef) {
            await invRef.update({
              sent: false,
              sentAt: Timestamp.now(),
              sendError: msg,
              sendErrorStatus: status,
              sendErrorBody: body,
              sendAttemptCount: FieldValue.increment(1),
            });
          }

          results.push({
            guestEmail,
            guestId: gid || null,
            invitationId: invId,
            invitationCode: guestInvitationCode || null,
            status: "failed",
            error: msg,
            statusCode: status,
            isCompanion: isCompanionInvite,
            companionIndex: isCompanionInvite ? companionIndex : null,
          });
        }
      }

      await db.collection("invitationLogs").add({
        eventId,
        organisationId: organisationId || null,
        createdAt: Timestamp.now(),
        results,
      });

      const sentUnique = new Set(
        results.filter((r) => r.status === "sent").map((r) => r.invitationId)
      );

      return { ok: true, invited: sentUnique.size, results };
    } catch (err) {
      console.error("sendInvitations error:", err);
      throw err instanceof HttpsError
        ? err
        : new HttpsError("internal", err?.message ?? "Unknown error");
    }
  }
);
