import { defineSecret } from "firebase-functions/params";
import { Timestamp } from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";
import postmark from "postmark";
import { db } from "./admin.js";

export const POSTMARK_SERVER_TOKEN = defineSecret("POSTMARK_SERVER_TOKEN");

const FROM_EMAIL = process.env.FROM_EMAIL || "developer@trax-event.com";
const FROM_NAME = process.env.FROM_NAME || "Trax Events";
const APP_BASE_URL = process.env.APP_BASE_URL || "https://trax-event.app";
const MESSAGE_STREAM = process.env.POSTMARK_MESSAGE_STREAM || "outbound";

function escapeHtml(s) {
  const str = (s ?? "").toString();
  return str
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function encodeGcsPath(path) {
  return String(path).split("/").map(encodeURIComponent).join("/");
}

async function resolveImageUrl(pathOrUrl, { signedDays = 30 } = {}) {
  const raw = (pathOrUrl ?? "").toString().trim();
  if (!raw) return "";
  if (raw.startsWith("http://") || raw.startsWith("https://")) return raw;

  const bucket = getStorage().bucket();
  const file = bucket.file(raw);

  const [exists] = await file.exists();
  if (!exists) return "";

  try {
    await file.makePublic();
    return `https://storage.googleapis.com/${bucket.name}/${encodeGcsPath(raw)}`;
  } catch (_) {
    const [signedUrl] = await file.getSignedUrl({
      action: "read",
      expires: Date.now() + signedDays * 24 * 60 * 60 * 1000,
    });
    return signedUrl;
  }
}

function formatEventDate(timestamp) {
  if (!timestamp || !timestamp.toDate) return "";
  const date = timestamp.toDate();
  return date.toLocaleString("en-US", {
    weekday: "long",
    year: "numeric",
    month: "long",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
    timeZoneName: "short",
  });
}

function buildDetailsLink(invId, invToken) {
  return (
    `${APP_BASE_URL}/guest-response?invitationId=${encodeURIComponent(invId)}` +
    `&token=${encodeURIComponent(invToken)}` +
    `&view=details&v=${Date.now()}`
  );
}

// ✅ “done” = RSVP yes + (demo if required) + (menu if required) for main and all attending companions
function isFlowComplete(inv) {
  if (!inv) return false;

  // declined counts as complete
  if (inv.hasResponded === true && inv.isAttending === false) return true;

  // must RSVP yes
  if (inv.hasResponded !== true || inv.isAttending !== true) return false;

  // must finish creating companions
  if ((inv.remainingCompanionsToCreate ?? 0) > 0) return false;

  const requiresDemo = !!inv.demographicQuestionSetId;

  // main
  if (requiresDemo && inv.used !== true) return false;
  if (inv.menuSelectionSubmitted !== true) return false;

  const comps = Array.isArray(inv.companions) ? inv.companions : [];
  for (const c of comps) {
    // attendance must be known
    if (c?.attendingSubmitted !== true) return false;

    // not attending -> skip demo/menu
    if (c?.isAttending === false) continue;

    if (requiresDemo && c?.demographicSubmitted !== true) return false;
    if (c?.menuSubmitted !== true) return false;
  }

  return true;
}

// ✅ Acquire a lock to avoid multiple sends in parallel
async function acquireThankYouLock(invRef) {
  return await db.runTransaction(async (tx) => {
    const snap = await tx.get(invRef);
    if (!snap.exists) return { status: "missing" };

    const inv = snap.data() || {};
    if (inv.thankYouEmailSent === true) return { status: "already_sent" };
    if (!isFlowComplete(inv)) return { status: "not_complete" };

    const lock = inv.thankYouEmailLock;
    const lockMs = lock?.toMillis?.() ?? 0;

    // if locked within last 5 minutes, skip
    if (lockMs && Date.now() - lockMs < 5 * 60 * 1000) {
      return { status: "locked" };
    }

    tx.update(invRef, { thankYouEmailLock: Timestamp.now() });
    return { status: "acquired", inv };
  });
}

export async function sendThankYouEmailsForInvitation(invitationId) {
  const invRef = db.collection("invitations").doc(invitationId);

  const lockRes = await acquireThankYouLock(invRef);
  if (lockRes.status !== "acquired") return;

  const inv = lockRes.inv || {};
  const invToken = (inv.token || "").toString().trim();
  if (!invToken) {
    await invRef.update({ thankYouEmailLock: null });
    return;
  }

  const pmToken = (POSTMARK_SERVER_TOKEN.value() || "").trim();
  if (!pmToken) {
    await invRef.update({ thankYouEmailLock: null });
    return;
  }

  const client = new postmark.ServerClient(pmToken);

  // event details + images
  let eventName = "Event";
  let eventAddress = "";
  let formattedStart = "";
  let formattedEnd = "";
  let eventImageUrl = "";

  try {
    const eventId = (inv.eventId || "").toString().trim();
    if (eventId) {
      const eventDoc = await db.collection("events").doc(eventId).get();
      if (eventDoc.exists) {
        const e = eventDoc.data() || {};
        eventName = (e.name || eventName).toString();
        eventAddress = (e.address || "").toString();
        formattedStart = formatEventDate(e.startDateTime);
        formattedEnd = formatEventDate(e.endDateTime);

        const coverPathOrUrl =
          (e.coverImagePath || "").toString().trim() ||
          (e.coverImageUrl || "").toString().trim() ||
          "";
        eventImageUrl = await resolveImageUrl(coverPathOrUrl, { signedDays: 30 });
      }
    }
  } catch (_) {}

  const logoUrl = await resolveImageUrl("app_images/light-logo.png", { signedDays: 365 });

  const invitationCode = (inv.invitationCode || "").toString().trim();
  const batchId = (inv.batchId || "").toString().trim();

  const link = buildDetailsLink(invitationId, invToken);

  const eventImageHtml = eventImageUrl
    ? `<img src="${eventImageUrl}" alt="${escapeHtml(eventName)}" style="width:100%;max-width:600px;max-height:150px;object-fit:cover;border-radius:8px;display:block;margin:0 auto 24px;" />`
    : "";

  const logoHtml = logoUrl
    ? `<img src="${logoUrl}" alt="Trax Event Logo" style="max-width:150px;height:auto;margin-bottom:15px;" />`
    : "";

  let eventDetailsHtml = "";
  if (formattedStart || formattedEnd || eventAddress) {
    eventDetailsHtml = `
      <div style="background:#f9fafb;border-left:4px solid #2563eb;padding:16px;margin:20px 0;border-radius:4px;">
        <h3 style="margin:0 0 12px;color:#1f2937;font-size:16px;font-weight:600;">Event Details</h3>
        ${formattedStart ? `<p style="margin:6px 0;color:#4b5563;font-size:14px;"><strong>Start:</strong> ${escapeHtml(formattedStart)}</p>` : ""}
        ${formattedEnd ? `<p style="margin:6px 0;color:#4b5563;font-size:14px;"><strong>End:</strong> ${escapeHtml(formattedEnd)}</p>` : ""}
        ${eventAddress ? `<p style="margin:6px 0;color:#4b5563;font-size:14px;"><strong>Location:</strong> ${escapeHtml(eventAddress)}</p>` : ""}
      </div>`;
  }

  let referenceHtml = "";
  if (invitationCode || batchId) {
    referenceHtml = `
      <div style="color:#6b7280;font-size:13px;margin-top:30px;padding-top:20px;border-top:1px solid #e5e7eb;">
        <strong>Reference Information:</strong><br/>
        ${invitationCode ? `Invitation Code: <strong>${escapeHtml(invitationCode)}</strong><br/>` : ""}
        ${batchId ? `Batch ID: <strong>${escapeHtml(batchId)}</strong>` : ""}
      </div>`;
  }

  // ✅ recipients: main + companions (each gets their own email + name)
  const recipients = [];

  const mainEmail = (inv.guestEmail || "").toString().trim();
  const mainName = (inv.guestName || "").toString().trim() || "Guest";
  if (mainEmail) recipients.push({ email: mainEmail, name: mainName });

  const comps = Array.isArray(inv.companions) ? inv.companions : [];
  for (const c of comps) {
    const e = (c?.guestEmail || c?.email || "").toString().trim();
    const n = (c?.guestName || c?.name || "Companion").toString().trim();
    if (e) recipients.push({ email: e, name: n });
  }

  try {
    for (const r of recipients) {
      const safeName = escapeHtml(r.name);
      const safeEvent = escapeHtml(eventName);

      const htmlBody = `
        <div style="font-family:'Segoe UI',Tahoma,Geneva,Verdana,sans-serif;line-height:1.6;color:#1f2937;max-width:600px;margin:0 auto;background:#ffffff;">
          ${eventImageHtml}
          <div style="padding:0 20px;">
            <h1 style="color:#1f2937;font-size:24px;margin:0 0 10px;font-weight:700;">Thank you!</h1>

            <p style="font-size:16px;color:#4b5563;margin:10px 0;">
              Hello ${safeName},
            </p>

            <p style="font-size:16px;color:#1f2937;margin:16px 0;">
              Your responses for <strong>${safeEvent}</strong> were submitted successfully.
            </p>

            ${eventDetailsHtml}

            <div style="text-align:center;margin:30px 0;">
              <a href="${link}" style="display:inline-block;padding:14px 28px;background:#2563eb;color:#ffffff;text-decoration:none;border-radius:8px;font-weight:600;font-size:16px;box-shadow:0 2px 4px rgba(0,0,0,0.1);">
                View Event Details
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

            ${referenceHtml}

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
        </div>`;

      const textBody =
        `Hello ${r.name},\n\n` +
        `Your responses for ${eventName} were submitted successfully.\n\n` +
        `View Event Details:\n${link}\n`;

      await client.sendEmail({
        From: `"${FROM_NAME}" <${FROM_EMAIL}>`,
        To: r.email,
        Subject: `Thank you! Your responses for ${eventName} are submitted`,
        TextBody: textBody,
        HtmlBody: htmlBody,
        MessageStream: MESSAGE_STREAM,
        Metadata: {
          invitationId,
          eventId: (inv.eventId || "").toString(),
          type: "thank_you",
          recipient: r.email,
        },
      });
    }

    // ✅ mark final success and clear lock
    await invRef.update({
      thankYouEmailSent: true,
      thankYouEmailSentAt: Timestamp.now(),
      thankYouEmailLock: null,
    });
  } catch (e) {
    // if sending fails, clear lock so it can retry next submission
    await invRef.update({ thankYouEmailLock: null });
    throw e;
  }
}
