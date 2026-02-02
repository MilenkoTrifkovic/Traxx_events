// functions/resendHostVerificationEmail.js
// Resends password setup email to a host user

import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { Timestamp } from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";
import postmark from "postmark";
import { db } from "./admin.js";

const POSTMARK_SERVER_TOKEN = defineSecret("POSTMARK_SERVER_TOKEN");

const FROM_EMAIL = "developer@trax-event.com";
const FROM_NAME = process.env.FROM_NAME || "Trax Events";
const APP_BASE_URL = process.env.APP_BASE_URL || "https://trax-event.app";
const HOST_PORTAL_URL = process.env.HOST_PORTAL_URL || "https://host.trax-event.app";

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

  if (!isSuper && !isAdmin && !isHost) {
    throw new HttpsError("permission-denied", "Only admins or hosts can resend emails.");
  }

  if (isSuper) {
    return;
  }

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

function buildCustomPasswordResetLink(firebaseLink) {
  try {
    const url = new URL(firebaseLink);
    const oobCode = url.searchParams.get("oobCode");
    if (!oobCode) {
      console.warn("No oobCode found in Firebase link:", firebaseLink);
      return firebaseLink;
    }
    return APP_BASE_URL + "/reset-password?oobCode=" + encodeURIComponent(oobCode);
  } catch (e) {
    console.error("Error parsing Firebase link:", e);
    return firebaseLink;
  }
}

export const resendHostVerificationEmail = onCall(
  { secrets: [POSTMARK_SERVER_TOKEN] },
  async (request) => {
    const { organisationId, hostUid } = request.data || {};

    const orgId = (organisationId || "").toString().trim();
    const uid = (hostUid || "").toString().trim();

    if (!orgId) {
      throw new HttpsError("invalid-argument", "organisationId is required.");
    }
    if (!uid) {
      throw new HttpsError("invalid-argument", "hostUid is required.");
    }

    await requireAdminForOrg(request, orgId);

    const orgHostRef = db
      .collection("organisations")
      .doc(orgId)
      .collection("hosts")
      .doc(uid);

    const orgHostSnap = await orgHostRef.get();
    if (!orgHostSnap.exists) {
      throw new HttpsError("not-found", "Host not found in this organisation.");
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

    // Mark user as email verified if not already
    if (!authUser.emailVerified) {
      try {
        await auth.updateUser(uid, { emailVerified: true });
      } catch (e) {
        console.warn("Could not mark user as email verified:", e);
      }
    }

    // Generate password reset link
    let passwordResetLink = null;
    try {
      const firebaseResetLink = await auth.generatePasswordResetLink(email);
      passwordResetLink = buildCustomPasswordResetLink(firebaseResetLink);
    } catch (e) {
      console.error("Failed to generate password reset link:", e);
      throw new HttpsError("failed-precondition", "Could not generate password reset link.");
    }

    const token = (POSTMARK_SERVER_TOKEN.value() || "").trim();
    if (!token) {
      throw new HttpsError("failed-precondition", "POSTMARK_SERVER_TOKEN missing/empty.");
    }
    const client = new postmark.ServerClient(token);

    const safeName = name || "there";

    const html = `
      <div style="font-family: Arial, sans-serif; line-height: 1.6; max-width: 600px; margin: 0 auto; padding: 20px;">
        <h2 style="color: #1a1a1a; margin-bottom: 24px;">Welcome to Trax Host Portal</h2>
        
        <p style="color: #374151;">Hello ${safeName},</p>
        
        <p style="color: #374151;">Your Trax Host Portal account has been created. Please click the button below to set up your password:</p>
        
        <p style="margin: 32px 0;">
          <a href="${passwordResetLink}" 
             style="display: inline-block; padding: 14px 28px; background-color: #2563eb; color: #ffffff; text-decoration: none; border-radius: 8px; font-weight: 600;">
            Set Up Password
          </a>
        </p>
        
        <p style="color: #6b7280; font-size: 14px;">
          If the button doesn't work, copy and paste this link into your browser:<br/>
          <a href="${passwordResetLink}" style="color: #2563eb; word-break: break-all;">${passwordResetLink}</a>
        </p>
        
        <hr style="border: none; border-top: 1px solid #e5e7eb; margin: 32px 0;" />
        
        <p style="color: #374151;">After setting up your password, access the Host Portal here:</p>
        
        <p style="margin: 24px 0;">
          <a href="${HOST_PORTAL_URL}" 
             style="display: inline-block; padding: 12px 24px; background-color: #16a34a; color: #ffffff; text-decoration: none; border-radius: 8px; font-weight: 600;">
            Open Host Portal
          </a>
        </p>
        
        <p style="color: #6b7280; font-size: 14px;">
          If the button doesn't work, copy and paste this link into your browser:<br/>
          <a href="${HOST_PORTAL_URL}" style="color: #2563eb;">${HOST_PORTAL_URL}</a>
        </p>
        
        <hr style="border: none; border-top: 1px solid #e5e7eb; margin: 32px 0;" />
        
        <p style="color: #dc2626; font-size: 14px; font-weight: 500;">
          Note: This link will expire in 1 hour for security reasons.
        </p>
        
        <p style="color: #374151;">
          Once you've set your password, you'll be able to log in to the Host Portal and start managing your events.
        </p>
        
        <p style="color: #6b7280; margin-top: 32px; font-size: 14px;">
          — Trax Host Portal<br/>
          <a href="mailto:${FROM_EMAIL}" style="color: #2563eb;">${FROM_EMAIL}</a>
        </p>
      </div>
    `;

    await client.sendEmail({
      From: FROM_NAME + " <" + FROM_EMAIL + ">",
      To: email,
      Subject: "Welcome to Trax Host Portal - Set Up Your Password",
      HtmlBody: html,
    });

    const now = Timestamp.now();
    await orgHostRef.set(
      {
        passwordResetEmailSentAt: now,
        updatedAt: now,
      },
      { merge: true }
    );

    return {
      ok: true,
      email,
      passwordResetLink,
    };
  }
);
