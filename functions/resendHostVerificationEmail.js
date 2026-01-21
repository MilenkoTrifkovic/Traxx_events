// functions/resendHostVerificationEmail.js (or inside functions/index.js)

import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { Timestamp } from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";
import postmark from "postmark";
import { db } from "./admin.js";

const POSTMARK_SERVER_TOKEN = defineSecret("POSTMARK_SERVER_TOKEN");

const FROM_EMAIL = "developer@trax-event.com"; // change if needed
const FROM_NAME = process.env.FROM_NAME || "Trax Events";
const APP_BASE_URL = process.env.APP_BASE_URL || "https://trax-event.app";

async function requireAdminForOrg(request, organisationId) {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const adminUid = request.auth.uid;
  const snap = await db.collection("users").doc(adminUid).get();
  if (!snap.exists) {
    throw new HttpsError("permission-denied", "User profile not found.");
  }

  const u = snap.data() || {};
  const role = (u.role || "").toString();

  const isSuper =
    role === "superAdmin" || role === "super_admin" || role === "superadmin";
  const isAdmin = role === "admin";
  const isHost = role === "host";

  // Allow superAdmin, admin, or host to resend emails
  if (!isSuper && !isAdmin && !isHost) {
    throw new HttpsError("permission-denied", "Only admins or hosts can resend emails.");
  }

  // SuperAdmin can resend emails for any organisation
  if (isSuper) {
    return;
  }

  // Admin must match organisationId
  if (isAdmin) {
    const myOrg = (u.organisationId || "").toString();
    if (!myOrg || myOrg !== organisationId) {
      throw new HttpsError(
        "permission-denied",
        "You can only resend emails for your organisation."
      );
    }
    return;
  }

  // Host must be managed by the organisation
  if (isHost) {
    const managedByOrgIds = u.managedByOrgIds || [];
    if (!Array.isArray(managedByOrgIds) || !managedByOrgIds.includes(organisationId)) {
      throw new HttpsError(
        "permission-denied",
        "You can only resend emails for organisations that manage you."
      );
    }
    return;
  }
}

function hostActionSettings(orgId) {
  return {
    url: `${APP_BASE_URL}/host/login?org=${encodeURIComponent(orgId)}`,
    handleCodeInApp: false,
  };
}

export const resendHostVerificationEmail = onCall(
  { secrets: [POSTMARK_SERVER_TOKEN] },
  async (request) => {
    const { organisationId, hostUid, sendPasswordLink = false } =
      request.data || {};

    const orgId = (organisationId || "").toString().trim();
    const uid = (hostUid || "").toString().trim();

    if (!orgId) {
      throw new HttpsError("invalid-argument", "organisationId is required.");
    }
    if (!uid) {
      throw new HttpsError("invalid-argument", "hostUid is required.");
    }

    await requireAdminForOrg(request, orgId);

    // Ensure this host belongs to the org directory (prevents random UID spam)
    const orgHostRef = db
      .collection("organisations")
      .doc(orgId)
      .collection("hosts")
      .doc(uid);

    const orgHostSnap = await orgHostRef.get();
    if (!orgHostSnap.exists) {
      throw new HttpsError(
        "not-found",
        "Host not found in this organisation."
      );
    }

    const orgHost = orgHostSnap.data() || {};
    const email = (orgHost.email || "").toString().trim().toLowerCase();
    const name = (orgHost.name || orgHost.fullName || "").toString().trim();

    if (!email || !email.includes("@")) {
      throw new HttpsError(
        "failed-precondition",
        "Host email missing/invalid in organisation hosts directory."
      );
    }

    const auth = getAuth();
    const authUser = await auth.getUser(uid);

    // Must be a host user
    // (This is a soft check; if your auth user doesn't exist, getUser throws already.)
    if (authUser.email?.toLowerCase() !== email) {
      // keep permissive for dev; just ensure we use the directory email
    }

    const actionSettings = hostActionSettings(orgId);

    let emailVerifyLink = null;
    let passwordResetLink = null;

    // If already verified, no need to send verification link
    if (!authUser.emailVerified) {
      try {
        emailVerifyLink = await auth.generateEmailVerificationLink(
          email,
          actionSettings
        );
      } catch (e) {
        emailVerifyLink = null;
      }
    }

    // Optional: include "Set Password" link when resending
    if (sendPasswordLink) {
      try {
        passwordResetLink = await auth.generatePasswordResetLink(
          email,
          actionSettings
        );
      } catch (e) {
        passwordResetLink = null;
      }
    }

    const token = (POSTMARK_SERVER_TOKEN.value() || "").trim();
    if (!token) {
      throw new HttpsError(
        "failed-precondition",
        "POSTMARK_SERVER_TOKEN missing/empty."
      );
    }
    const client = new postmark.ServerClient(token);

    const safeName = name || "there";

    const html = `
      <div style="font-family: Arial, sans-serif; line-height: 1.5;">
        <h2>Trax Events - Host Portal Access</h2>
        <p>Hi ${safeName},</p>

        ${
          authUser.emailVerified
            ? `<p><b>Your email is already verified.</b></p>`
            : `<p>Please verify your email to access the Host Portal:</p>
               ${
                 emailVerifyLink
                   ? `<p>
                        <a href="${emailVerifyLink}"
                           style="display:inline-block;padding:10px 14px;background:#16a34a;color:#fff;border-radius:8px;text-decoration:none;">
                          Verify Email
                        </a>
                      </p>`
                   : `<p><b>Verification link could not be generated.</b> Please contact the organizer.</p>`
               }`
        }

        ${
          sendPasswordLink
            ? `${
                passwordResetLink
                  ? `<p style="margin-top:18px;">If you haven’t set your password yet:</p>
                     <p>
                       <a href="${passwordResetLink}"
                          style="display:inline-block;padding:10px 14px;background:#2563eb;color:#fff;border-radius:8px;text-decoration:none;">
                         Set Password
                       </a>
                     </p>`
                  : `<p><b>Password reset link could not be generated.</b></p>`
              }`
            : ``
        }

        <p style="color:#6b7280;font-size:12px;">
          If you didn’t expect this email, you can ignore it.
        </p>
      </div>
    `;

    await client.sendEmail({
      From: `${FROM_NAME} <${FROM_EMAIL}>`,
      To: email,
      Subject: "Verify your email for Host Portal",
      HtmlBody: html,
    });

    const now = Timestamp.now();
    await orgHostRef.set(
      {
        verificationEmailSentAt: now,
        updatedAt: now,
      },
      { merge: true }
    );

    return {
      ok: true,
      email,
      alreadyVerified: authUser.emailVerified === true,
      sentVerification: !authUser.emailVerified && !!emailVerifyLink,
      sentPasswordLink: sendPasswordLink && !!passwordResetLink,
      // For dev/debug only:
      emailVerifyLink,
      passwordResetLink,
    };
  }
);
