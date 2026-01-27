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

      if (!eventId)
        throw new HttpsError("invalid-argument", "eventId is required");
      if (!Array.isArray(invitations) || invitations.length === 0) {
        throw new HttpsError("invalid-argument", "invitations array required");
      }

      const token = (POSTMARK_SERVER_TOKEN.value() || "").trim();
      if (!token) {
        throw new HttpsError(
          "failed-precondition",
          "POSTMARK_SERVER_TOKEN missing/empty at runtime."
        );
      }

      const client = new postmark.ServerClient(token);
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

      // ✅ Prefer coverImagePath; fallback to coverImageUrl
      const coverPathOrUrl =
        (eventData?.coverImagePath || "").toString().trim() ||
        (eventData?.coverImageUrl || "").toString().trim() ||
        "";

      // ✅ Resolve ONCE
      const eventImageUrl = await resolveImageUrl(coverPathOrUrl, {
        signedDays: 30,
      });

      const logoUrl = await resolveImageUrl("app_images/light-logo.png", {
        signedDays: 365,
      });

      const formattedStartDate = formatEventDate(eventStartDateTime);
      const formattedEndDate = formatEventDate(eventEndDateTime);

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

        // ✅ CASE A: guestId exists -> uniqueness = (eventId + guestId)
        if (gid) {
          const ptrRef = db
            .collection(POINTERS_COL)
            .doc(pointerId(eventId, gid));

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
                  {
                    eventId,
                    guestId: gid,
                    invitationId: invId,
                    createdAt: Timestamp.now(),
                  },
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

            invToken =
              (invData?.token || "").toString().trim() || makeToken();

            guestInvitationCode =
              (invData?.invitationCode || "").toString().trim() ||
              makeInvitationCode();

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
        } else {
          // ✅ CASE B: guestId missing -> ALWAYS create new invitation
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
        }

        const link =
          `${APP_BASE_URL}/guest-response?invitationId=${encodeURIComponent(
            invId
          )}` +
          `&token=${encodeURIComponent(invToken)}` +
          `&v=${Date.now()}`;

        const subject = `You're Invited to ${eventName}!`;

        const formattedStart = formattedStartDate;
        const formattedEnd = formattedEndDate;

        const textBody =
          `Hello${guestName ? " " + guestName : ""},\n\n` +
          `You're invited to ${eventName}!\n\n` +
          (eventAddress ? `Location: ${eventAddress}\n` : "") +
          (formattedStart ? `Start: ${formattedStart}\n` : "") +
          (formattedEnd ? `End: ${formattedEnd}\n` : "") +
          `\n` +
          `Please open this link to RSVP, complete your details, and select your menu preferences:\n${link}\n\n` +
          `This link expires in ${INV_EXPIRY_DAYS} days.\n\n` +
          (guestInvitationCode
            ? `Invitation Code: ${guestInvitationCode}\n`
            : "") +
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
            eventDetailsHtml += `<p style="margin:6px 0;color:#4b5563;font-size:14px;"><strong>Start:</strong> ${escapeHtml(
              formattedStart
            )}</p>`;
          }
          if (formattedEnd) {
            eventDetailsHtml += `<p style="margin:6px 0;color:#4b5563;font-size:14px;"><strong>End:</strong> ${escapeHtml(
              formattedEnd
            )}</p>`;
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
            htmlReferenceInfo += `Invitation Code: <strong>${escapeHtml(
              guestInvitationCode
            )}</strong><br/>`;
          }
          if (batchId) {
            htmlReferenceInfo += `Batch ID: <strong>${escapeHtml(
              batchId
            )}</strong>`;
          }
          htmlReferenceInfo += `</div>`;
        }

        const htmlBody = `
          <div style="font-family:'Segoe UI',Tahoma,Geneva,Verdana,sans-serif;line-height:1.6;color:#1f2937;max-width:600px;margin:0 auto;background:#ffffff;">
            ${eventImageHtml}
            <div style="padding:0 20px;">
              <h1 style="color:#1f2937;font-size:24px;margin:0 0 10px;font-weight:700;">You're Invited!</h1>

              <p style="font-size:16px;color:#4b5563;margin:10px 0;">
                Hello${safeName ? " " + safeName : ""},
              </p>

              <p style="font-size:16px;color:#1f2937;margin:16px 0;">
                You have been invited to <strong>${safeEventName}</strong>!
              </p>

              ${eventDetailsHtml}

              <p style="font-size:15px;color:#4b5563;margin:20px 0;">
                Please click the button below to confirm your attendance, complete your details, and select your menu preferences.
              </p>

              <div style="text-align:center;margin:30px 0;">
                <a href="${link}" style="display:inline-block;padding:14px 28px;background:#2563eb;color:#ffffff;text-decoration:none;border-radius:8px;font-weight:600;font-size:16px;box-shadow:0 2px 4px rgba(0,0,0,0.1);">
                  Accept Invitation & RSVP
                </a>
              </div>

              <div style="background:#f9fafb;padding:16px;border-radius:6px;margin:20px 0;">
                <p style="color:#6b7280;font-size:13px;margin:0 0 8px;">
                  If the button doesn't work, copy and paste this link into your browser:
                </p>
                <p style="margin:0;">
                  <a href="${link}" style="color:#2563eb;font-size:13px;word-break:break-all;">${link}</a>
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
            },
          });

          results.push({
            guestEmail,
            guestId: gid || null,
            invitationId: invId,
            invitationCode: guestInvitationCode || null,
            status: "sent",
          });

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

          await invRef.update({
            sent: false,
            sentAt: Timestamp.now(),
            sendError: msg,
            sendErrorStatus: status,
            sendErrorBody: body,
            sendAttemptCount: FieldValue.increment(1),
          });

          results.push({
            guestEmail,
            guestId: gid || null,
            invitationId: invId,
            invitationCode: guestInvitationCode || null,
            status: "failed",
            error: msg,
            statusCode: status,
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

      return {
        ok: true,
        invited: sentUnique.size,
        results,
      };
    } catch (err) {
      console.error("sendInvitations error:", err);
      throw err instanceof HttpsError
        ? err
        : new HttpsError("internal", err?.message ?? "Unknown error");
    }
  }
);
