// import { onCall, HttpsError } from "firebase-functions/v2/https";
// import { setGlobalOptions } from "firebase-functions/v2";
// import admin from "firebase-admin";
// import sgMail from "@sendgrid/mail";
// import { randomBytes } from "crypto";

// setGlobalOptions({ timeoutSeconds: 120, memory: "256MB" });

// if (!admin.apps.length) admin.initializeApp();
// const db = admin.firestore();

// /* ENV */
// const SENDGRID_KEY = process.env.SENDGRID_KEY;
// const FROM_EMAIL = process.env.SENDGRID_FROM_EMAIL;
// const FROM_NAME = process.env.SENDGRID_FROM_NAME || "Traxx Events";
// const APP_BASE_URL = process.env.APP_BASE_URL;
// const INV_EXPIRY_DAYS = Number(process.env.INV_EXPIRY_DAYS || 14);

// if (SENDGRID_KEY) {
//   sgMail.setApiKey(SENDGRID_KEY);
// }

// function makeToken() {
//   return randomBytes(24).toString("hex");
// }

// export const sendInvitations = onCall(async (request) => {
//   // ✅ runtime validation (safe)
//   if (!SENDGRID_KEY || !FROM_EMAIL || !APP_BASE_URL) {
//     throw new HttpsError(
//       "failed-precondition",
//       "SendGrid environment variables are not configured"
//     );
//   }

//   const { eventId, organisationId, invitations, demographicQuestionSetId } =
//     request.data || {};

//   if (!eventId) {
//     throw new HttpsError("invalid-argument", "eventId is required");
//   }

//   if (!Array.isArray(invitations) || invitations.length === 0) {
//     throw new HttpsError("invalid-argument", "invitations array required");
//   }

//   const now = admin.firestore.Timestamp.now();
//   const expiresAt = admin.firestore.Timestamp.fromDate(
//     new Date(Date.now() + INV_EXPIRY_DAYS * 24 * 60 * 60 * 1000)
//   );

//   const results = [];

//   for (const g of invitations) {
//     const guestEmail = (g?.guestEmail || "").trim();
//     if (!guestEmail) continue;

//     const ref = db.collection("invitations").doc();
//     const token = makeToken();

//     await ref.set({
//       invitationId: ref.id,
//       eventId,
//       organisationId: organisationId || null,
//       guestId: g?.guestId || null,
//       guestEmail,
//       token,
//       demographicQuestionSetId: demographicQuestionSetId || null,
//       used: false,
//       createdAt: now,
//       expiresAt,
//     });

//     const link = `${APP_BASE_URL}/demographics?invitationId=${ref.id}&token=${token}`;

//     try {
//       await sgMail.send({
//         to: guestEmail,
//         from: { email: FROM_EMAIL, name: FROM_NAME },
//         subject: "You are invited to an event",
//         html: `
//           <p>Hello,</p>
//           <p>You are invited to an event.</p>
//           <p><a href="${link}">Click here to answer the questionnaire</a></p>
//           <p>This link expires in ${INV_EXPIRY_DAYS} days.</p>
//           <p>— ${FROM_NAME}</p>
//         `,
//       });

//       await ref.update({
//         sent: true,
//         sentAt: admin.firestore.Timestamp.now(),
//       });

//       results.push({ guestEmail, status: "sent" });
//     } catch (err) {
//       await ref.update({
//         sent: false,
//         sentAt: admin.firestore.Timestamp.now(),
//         sendError: err.message,
//       });

//       results.push({ guestEmail, status: "failed", error: err.message });
//     }
//   }

//   await db.collection("invitationLogs").add({
//     eventId,
//     organisationId,
//     createdAt: now,
//     results,
//   });

//   return { ok: true, invited: results.length, results };
// });



// sendInvitationForEvent.js (ESM)
import "dotenv/config";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { setGlobalOptions } from "firebase-functions/v2";
import admin from "firebase-admin";
import sgMail from "@sendgrid/mail";
import { randomBytes } from "crypto";

setGlobalOptions({ timeoutSeconds: 120, memory: "256MB" });

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

const SENDGRID_KEY = process.env.SENDGRID_KEY;
const FROM_EMAIL = process.env.SENDGRID_FROM_EMAIL;
const FROM_NAME = process.env.SENDGRID_FROM_NAME || "Traxx Events";
const APP_BASE_URL = (process.env.APP_BASE_URL || "").replace(/\/$/, "");
const INV_EXPIRY_DAYS = Number(process.env.INV_EXPIRY_DAYS || 14);

if (SENDGRID_KEY) sgMail.setApiKey(SENDGRID_KEY);

function makeToken() {
  return randomBytes(24).toString("hex");
}

function nowTs() {
  return admin.firestore.Timestamp.now();
}

export const sendInvitations = onCall(async (request) => {
  // runtime validation
  if (!SENDGRID_KEY || !FROM_EMAIL || !APP_BASE_URL) {
    throw new HttpsError(
      "failed-precondition",
      "SendGrid or FROM/APP environment variables are not configured"
    );
  }

  console.log("SENDGRID_KEY exists:", !!process.env.SENDGRID_KEY);
  console.log("FROM_EMAIL:", process.env.SENDGRID_FROM_EMAIL);

  const auth = request.auth;
  if (!auth) {
    throw new HttpsError("unauthenticated", "Login required");
  }

  const { eventId, organisationId, invitations, demographicQuestionSetId } =
    request.data || {};

  if (!eventId || !Array.isArray(invitations)) {
    throw new HttpsError("invalid-argument", "eventId + invitations required");
  }

  // load event
  const eventDoc = await db.collection("events").doc(eventId).get();
  if (!eventDoc.exists) {
    throw new HttpsError("not-found", "Event not found");
  }
  const event = eventDoc.data() || {};
  const createdAt = nowTs();
  const expiresAt = admin.firestore.Timestamp.fromDate(
    new Date(Date.now() + INV_EXPIRY_DAYS * 24 * 60 * 60 * 1000)
  );

  const results = [];

  for (const g of invitations) {
    const guestEmail = (g?.guestEmail || "").trim();
    if (!guestEmail) continue;

    const invitationRef = db.collection("invitations").doc();
    const invitationId = invitationRef.id;
    const token = makeToken();

    // initial write
    await invitationRef.set({
      invitationId,
      eventId,
      organisationId: organisationId || null,
      guestId: g?.guestId || null,
      guestEmail,
      guestName: g?.guestName || "",
      demographicQuestionSetId: demographicQuestionSetId || null,
      token,
      used: false,
      createdAt,
      expiresAt,
      sent: false,
      sendError: null,
      sendErrorFull: null,
    });

    const link = `${APP_BASE_URL}/demographics?invitationId=${invitationId}&token=${token}`;

    // prepare email - include text & html fallback
    const subject = `Invitation: ${event.name || "Your event"}`;
    const html = `
      <p>Hi ${g?.guestName || ""},</p>
      <p>You are invited to <strong>${event.name || "an event"}</strong>.</p>
      <p><a href="${link}" target="_blank" rel="noopener">Click here to open invitation & answer questions</a></p>
      <p>This link expires in ${INV_EXPIRY_DAYS} days.</p>
      <hr/>
      <p>— ${FROM_NAME}</p>
    `;
    const text = `Hi ${g?.guestName || ""},\n\nPlease open your invitation: ${link}\n\nThis link expires in ${INV_EXPIRY_DAYS} days.\n\n— ${FROM_NAME}`;

    try {
      // SendGrid's send returns a promise; can be array of responses
      const res = await sgMail.send({
        personalizations: [{ to: [{ email: guestEmail }] }],
        from: { email: FROM_EMAIL, name: FROM_NAME },
        subject,
        content: [{ type: "text/html", value: html }],
      });

      // Mark sent
      await invitationRef.update({
        sent: true,
        sentAt: nowTs(),
        sendError: null,
        sendErrorFull: null,
      });

      results.push({ guestEmail, status: "sent" });
      console.log("Invitation sent to", guestEmail, "invitationId=", invitationId, "sgRes=", Array.isArray(res) ? res.length : typeof res);
    } catch (err) {
      // capture helpful details from SendGrid error response (if present)
      let short = err?.message || "send-failed";
      let full = null;
      try {
        // many SG errors expose err.response.body
        full = err?.response?.body || JSON.stringify(err, Object.getOwnPropertyNames(err));
        // Short summary if possible
        if (err?.response?.body?.errors && Array.isArray(err.response.body.errors)) {
          short = err.response.body.errors.map((e) => e.message).join("; ");
        }
      } catch (e2) {
        full = String(err);
      }

      console.error("SendGrid send failed for", guestEmail, short, full);

      await invitationRef.update({
        sent: false,
        sentAt: nowTs(),
        sendError: short,
        sendErrorFull: full,
      });

      results.push({ guestEmail, status: "failed", error: short });
    }
  }

  // record log
  await db.collection("invitationLogs").add({
    eventId,
    organisationId: organisationId || null,
    createdAt,
    results,
    actorUid: auth?.uid || null,
  });

  return { ok: true, invited: results.filter(r => r.status === "sent").length, results };
});
