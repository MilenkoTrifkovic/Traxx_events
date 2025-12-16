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



// functions/sendInvitationForEvent.js


import { onCall, HttpsError } from "firebase-functions/v2/https";
import { setGlobalOptions } from "firebase-functions/v2";
import admin from "firebase-admin";
import nodemailer from "nodemailer";
import { randomBytes } from "crypto";

setGlobalOptions({ timeoutSeconds: 120, memory: "256MB" });

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

/* ========= ENV CONFIG ========= */
const SMTP_HOST = process.env.SMTP_HOST;
const SMTP_PORT = Number(process.env.SMTP_PORT || 465);
const SMTP_USER = process.env.SMTP_USER;
const SMTP_PASS = process.env.SMTP_PASS;

const FROM_EMAIL = process.env.FROM_EMAIL;
const FROM_NAME = process.env.FROM_NAME || "Traxx Events";

const APP_BASE_URL = (process.env.APP_BASE_URL || "").replace(/\/$/, "");
const INV_EXPIRY_DAYS = Number(process.env.INV_EXPIRY_DAYS || 14);
/* ============================== */

/* Fail only when function is CALLED (not during deploy) */
function validateEnv() {
  if (!SMTP_HOST || !SMTP_USER || !SMTP_PASS) {
    throw new HttpsError(
      "failed-precondition",
      "SMTP configuration missing"
    );
  }
  if (!FROM_EMAIL) {
    throw new HttpsError("failed-precondition", "FROM_EMAIL missing");
  }
  if (!APP_BASE_URL) {
    throw new HttpsError("failed-precondition", "APP_BASE_URL missing");
  }
}

const transporter = nodemailer.createTransport({
  host: SMTP_HOST,
  port: SMTP_PORT,
  secure: SMTP_PORT === 465,
  auth: {
    user: SMTP_USER,
    pass: SMTP_PASS,
  },
});

function makeToken() {
  return randomBytes(24).toString("hex");
}

export const sendInvitations = onCall(async (request) => {
  try {
    validateEnv();

    const {
      eventId,
      organisationId,
      invitations,
      demographicQuestionSetId,
      staticLink,
    } = request.data || {};

    if (!eventId) {
      throw new HttpsError("invalid-argument", "eventId is required");
    }

    if (!Array.isArray(invitations) || invitations.length === 0) {
      throw new HttpsError("invalid-argument", "invitations array required");
    }

    const createdAt = admin.firestore.Timestamp.now();
    const expiresAt = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + INV_EXPIRY_DAYS * 24 * 60 * 60 * 1000)
    );

    const results = [];

    for (const guest of invitations) {
      const guestEmail = (guest?.guestEmail || "").trim();
      const guestName = guest?.guestName || "";

      if (!guestEmail) continue;

      const ref = db.collection("invitations").doc();
      const token = makeToken();

      await ref.set({
        invitationId: ref.id,
        eventId,
        organisationId: organisationId || null,
        guestId: guest?.guestId || null,
        guestEmail,
        guestName,
        demographicQuestionSetId: demographicQuestionSetId || null,
        token,
        used: false,
        createdAt,
        expiresAt,
      });

      const link =
        staticLink ||
        `${APP_BASE_URL}/demographics?invitationId=${ref.id}&token=${token}`;

      const mail = {
        from: `"${FROM_NAME}" <${FROM_EMAIL}>`,
        to: guestEmail,
        subject: "You are invited",
        text: `Please open this link:\n${link}`,
        html: `
          <p>Hello ${guestName},</p>
          <p>You are invited to an event.</p>
          <p><a href="${link}">Click here to continue</a></p>
          <p>This link expires in ${INV_EXPIRY_DAYS} days.</p>
          <p>— ${FROM_NAME}</p>
        `,
      };

      try {
        await transporter.sendMail(mail);

        await ref.update({
          sent: true,
          sentAt: admin.firestore.Timestamp.now(),
        });

        results.push({ guestEmail, status: "sent" });
      } catch (err) {
        await ref.update({
          sent: false,
          sentAt: admin.firestore.Timestamp.now(),
          sendError: err.message,
        });

        results.push({ guestEmail, status: "failed", error: err.message });
      }
    }

    await db.collection("invitationLogs").add({
      eventId,
      organisationId,
      createdAt,
      results,
    });

    return {
      ok: true,
      invited: results.filter(r => r.status === "sent").length,
      results,
    };
  } catch (err) {
    console.error("sendInvitations error:", err);
    throw err instanceof HttpsError
      ? err
      : new HttpsError("internal", err.message);
  }
});
