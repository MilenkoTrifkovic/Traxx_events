// functions/sendInvitationForEvent.js
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
// const FROM_NAME = process.env.FROM_NAME || "Trax Events";
const FROM_NAME = "Trax Events";
const APP_BASE_URL = "https://trax-event.app";
const INV_EXPIRY_DAYS = (() => {
  const raw = process.env.INV_EXPIRY_DAYS; // could be "0" or "0.01"
  const n = Number.parseInt(String(raw ?? "14"), 10);
  return Number.isFinite(n) && n >= 1 ? n : 14; // ✅ never less than 1 day
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
  // Alphanumeric (no confusing chars like 0/O/1/I)
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
  let chosenMs = chosen.data()?.createdAt?.toMillis?.() ?? Number.MAX_SAFE_INTEGER;

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
  // safe for UUIDs; if you ever use other ids, sanitize here
  return `${eventId}_${guestId}`;
}

async function getPublicUrlFromStoragePath(storagePath) {
  if (!storagePath || typeof storagePath !== "string") {
    console.warn("⚠️ getPublicUrlFromStoragePath: Empty or invalid storagePath", { storagePath });
    return "";
  }
  
  try {
    console.log(`🔍 Getting URL for storage path: ${storagePath}`);
    
    const bucket = getStorage().bucket();
    const file = bucket.file(storagePath);
    
    // Check if file exists
    const [exists] = await file.exists();
    if (!exists) {
      console.error(`❌ Storage file not found: ${storagePath}`);
      return "";
    }
    
    console.log(`✅ File exists: ${storagePath}`);
    
    // Make file publicly accessible
    await file.makePublic();
    
    // Get the public URL (no signature needed)
    const bucketName = bucket.name;
    const publicUrl = `https://storage.googleapis.com/${bucketName}/${encodeURIComponent(storagePath)}`;
    
    console.log(`✅ Public URL generated: ${publicUrl}`);
    
    return publicUrl;
  } catch (err) {
    console.error(`❌ Error getting public URL for ${storagePath}:`, err);
    console.error(`Error details:`, {
      message: err.message,
      code: err.code,
    });
    return "";
  }
}

/**
 * Format date for display in email
 */
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

        // 🔸 This is event-level (same for all guests). We keep it if you want it.
        // 🔸 Per-guest unique code will be stored as `invitationCode` on each invite doc.
        invitationCode: eventInvitationCode,
      } = request.data || {};

      if (!eventId) throw new HttpsError("invalid-argument", "eventId is required");
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

      // ✅ Fetch event details once (used for all invitations)
      const eventDoc = await db.collection("events").doc(eventId).get();
      if (!eventDoc.exists) {
        throw new HttpsError("not-found", `Event ${eventId} not found`);
      }

      const eventData = eventDoc.data();
      const eventName = eventData?.name || "Event";
      const eventAddress = eventData?.address || "";
      const eventStartDateTime = eventData?.startDateTime;
      const eventEndDateTime = eventData?.endDateTime;
      const eventCoverImagePath = eventData?.coverImageUrl || "";

      // Convert storage path to public URL
      const eventImageUrl = await getPublicUrlFromStoragePath(eventCoverImagePath);

      // Format event dates
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

        // ✅ NEW: per-guest invitation code (stable on resend)
        let guestInvitationCode = null;

        // ✅ CASE A: guestId exists -> uniqueness = (eventId + guestId)
        if (gid) {
          const ptrRef = db.collection(POINTERS_COL).doc(pointerId(eventId, gid));

          await db.runTransaction(async (tx) => {
            const ptrSnap = await tx.get(ptrRef);

            // 1) Pointer exists -> reuse invitationId
            if (ptrSnap.exists) {
              invId = (ptrSnap.data()?.invitationId || "").toString().trim();
              if (!invId) throw new Error("Pointer has empty invitationId");

              invRef = db.collection("invitations").doc(invId);
              const snap = await tx.get(invRef);
              invData = snap.exists ? (snap.data() || {}) : {};

            } else {
              // 2) No pointer yet -> try to find existing invitation by (eventId+guestId)
              const q = db.collection("invitations")
                .where("eventId", "==", eventId)
                .where("guestId", "==", gid)
                .limit(10);

              const qSnap = await tx.get(q);

              if (!qSnap.empty) {
                const chosen = pickEarliestByCreatedAt(qSnap.docs);
                invRef = chosen.ref;
                invId = chosen.id;
                invData = chosen.data() || {};

                // create pointer to the existing invite
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
                // 3) Create brand-new invitation with RANDOM id (old structure)
                invRef = db.collection("invitations").doc();
                invId = invRef.id;
                invData = {};

                // create pointer to the new invite
                tx.set(ptrRef, {
                  eventId,
                  guestId: gid,
                  invitationId: invId,
                  createdAt: Timestamp.now(),
                });
              }
            }

            // SAFETY: never allow a reuse collision
            const storedGid = (invData?.guestId ?? "").toString().trim();
            if (storedGid && storedGid !== gid) {
              throw new HttpsError(
                "failed-precondition",
                `Invitation collision: invitationId=${invId} belongs to guestId=${storedGid}, attempted guestId=${gid}`
              );
            }

            // Token must stay stable for same invitation
            invToken = (invData?.token || "").toString().trim() || makeToken();

            // ✅ NEW: invitationCode must stay stable for same invitation
            guestInvitationCode =
              (invData?.invitationCode || "").toString().trim() || makeInvitationCode();

            // Ensure invitation doc has correct core fields (merge)
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

                // ✅ per-guest unique code
                invitationCode: guestInvitationCode,

                // optional: keep event-level code if you want it for reporting/filtering
                ...(eventInvitationCode && { eventInvitationCode }),

                // preserve createdAt if already exists
                createdAt: invData?.createdAt ?? Timestamp.now(),
                expiresAt,

                // reset send flags for this attempt
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

          // ✅ NEW: unique invitation code for this guest
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

              // ✅ per-guest unique code
              invitationCode: guestInvitationCode,

              // optional: keep event-level code if you want it
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

        // ✅ Build link
        const link =
          `${APP_BASE_URL}/guest-response?invitationId=${encodeURIComponent(invId)}` +
          `&token=${encodeURIComponent(invToken)}` +
          `&v=${Date.now()}`;

        const subject = `You're Invited to ${eventName}!`;

        const textBody =
          `Hello${guestName ? " " + guestName : ""},\n\n` +
          `You're invited to ${eventName}!\n\n` +
          (eventAddress ? `Location: ${eventAddress}\n` : "") +
          (formattedStartDate ? `Start: ${formattedStartDate}\n` : "") +
          (formattedEndDate ? `End: ${formattedEndDate}\n` : "") +
          `\n` +
          `Please open this link to RSVP, complete your details, and select your menu preferences:\n${link}\n\n` +
          `This link expires in ${INV_EXPIRY_DAYS} days.\n\n` +
          (guestInvitationCode ? `Invitation Code: ${guestInvitationCode}\n` : "") +
          `\nThank you,\nTrax Event`;

        const safeName = guestName ? escapeHtml(guestName) : "";
        const safeEventName = escapeHtml(eventName);
        const safeAddress = escapeHtml(eventAddress);

        // Build event image header
        const eventImageHtml = eventImageUrl
          ? `<img src="${eventImageUrl}" alt="${safeEventName}" style="width:100%;max-width:600px;max-height:105px;object-fit:cover;border-radius:8px;display:block;margin:0 auto 30px;" />`
          : "";

        // Build logo for footer
        const logoUrl = await getPublicUrlFromStoragePath('app_images/light-logo.png');
        const logoHtml = logoUrl
          ? `<img src="${logoUrl}" alt="Trax Event Logo" style="max-width:150px;height:auto;margin-bottom:15px;" />`
          : '';

        // Build event details section
        let eventDetailsHtml = "";
        if (formattedStartDate || formattedEndDate || eventAddress) {
          eventDetailsHtml = `
            <div style="background:#f9fafb;border-left:4px solid #2563eb;padding:16px;margin:20px 0;border-radius:4px;">
              <h3 style="margin:0 0 12px;color:#1f2937;font-size:16px;font-weight:600;">Event Details</h3>`;
          
          if (formattedStartDate) {
            eventDetailsHtml += `<p style="margin:6px 0;color:#4b5563;font-size:14px;"><strong>Start:</strong> ${escapeHtml(formattedStartDate)}</p>`;
          }
          if (formattedEndDate) {
            eventDetailsHtml += `<p style="margin:6px 0;color:#4b5563;font-size:14px;"><strong>End:</strong> ${escapeHtml(formattedEndDate)}</p>`;
          }
          if (eventAddress) {
            eventDetailsHtml += `<p style="margin:6px 0;color:#4b5563;font-size:14px;"><strong>Location:</strong> ${safeAddress}</p>`;
          }
          
          eventDetailsHtml += `</div>`;
        }

        // ✅ Show per-guest invitation code in email
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
            
            <!-- Event Image Header -->
            ${eventImageHtml}
            
            <!-- Main Content -->
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

              <!-- CTA Button -->
              <div style="text-align:center;margin:30px 0;">
                <a href="${link}" style="display:inline-block;padding:14px 28px;background:#2563eb;color:#ffffff;text-decoration:none;border-radius:8px;font-weight:600;font-size:16px;box-shadow:0 2px 4px rgba(0,0,0,0.1);">
                  Accept Invitation & RSVP
                </a>
              </div>

              <!-- Alternative Link -->
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

              <!-- Thank You -->
              <div style="margin:40px 0 20px;padding:20px 0;border-top:1px solid #e5e7eb;">
                <p style="font-size:15px;color:#4b5563;margin:0;">
                  Thank you,<br/>
                  <strong>Trax Event</strong>
                </p>
              </div>
            </div>

            <!-- Footer with Logo -->
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

          results.push({
            guestEmail,
            guestId: gid || null,
            invitationId: invId,
            invitationCode: guestInvitationCode || null,
            status: "sent",
          });
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

      return {
        ok: true,
        invited: results.filter((r) => r.status === "sent").length,
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
