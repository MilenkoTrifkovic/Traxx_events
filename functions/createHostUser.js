import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { Timestamp, FieldValue } from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";
import { randomBytes } from "crypto";
import postmark from "postmark";
import { db } from "./admin.js";

const POSTMARK_SERVER_TOKEN = defineSecret("POSTMARK_SERVER_TOKEN");

const FROM_EMAIL = "developer@trax-event.com";
const FROM_NAME = process.env.FROM_NAME || "Trax Events";
const APP_BASE_URL = process.env.APP_BASE_URL || "https://trax-event.app";
const HOST_PORTAL_URL = process.env.HOST_PORTAL_URL || "https://host.trax-event.app";

function normalizeEmail(email) {
  return (email || "").toString().trim();
}
function emailLower(email) {
  return normalizeEmail(email).toLowerCase();
}

/**
 * Extracts the oobCode from a Firebase password reset link and builds
 * a custom URL pointing to our app's reset-password page.
 * @param {string} firebaseLink - The original Firebase password reset link
 * @returns {string} - Custom reset password URL with oobCode
 */
function buildCustomPasswordResetLink(firebaseLink) {
  try {
    const url = new URL(firebaseLink);
    const oobCode = url.searchParams.get("oobCode");
    if (!oobCode) {
      console.warn("No oobCode found in Firebase link:", firebaseLink);
      return firebaseLink; // fallback to original
    }
    return `${APP_BASE_URL}/reset-password?oobCode=${encodeURIComponent(oobCode)}`;
  } catch (e) {
    console.error("Error parsing Firebase link:", e);
    return firebaseLink; // fallback to original
  }
}

async function requireAdminForOrg(request, organisationId) {
  if (!request.auth?.uid) throw new HttpsError("unauthenticated", "Sign in required.");

  const adminUid = request.auth.uid;
  const snap = await db.collection("users").doc(adminUid).get();
  if (!snap.exists) throw new HttpsError("permission-denied", "User profile not found.");

  const u = snap.data() || {};
  const role = (u.role || "").toString();

  const isSuper =
    role === "superAdmin" || role === "super_admin" || role === "superadmin";
  const isAdmin = role === "admin";
  const isHost = role === "host";

  // Allow superAdmin, admin, or host to create host users
  if (!isSuper && !isAdmin && !isHost) {
    throw new HttpsError("permission-denied", "Only admins or hosts can create other hosts.");
  }

  // SuperAdmin can create hosts for any organisation
  if (isSuper) {
    return;
  }

  // Admin must match organisationId
  if (isAdmin) {
    const myOrg = (u.organisationId || "").toString();
    if (!myOrg || myOrg !== organisationId) {
      throw new HttpsError("permission-denied", "You can only create hosts for your organisation.");
    }
    return;
  }

  // Host must be managed by the organisation
  if (isHost) {
    const managedByOrgIds = u.managedByOrgIds || [];
    if (!Array.isArray(managedByOrgIds) || !managedByOrgIds.includes(organisationId)) {
      throw new HttpsError("permission-denied", "You can only create hosts for organisations that manage you.");
    }
    return;
  }
}

export const createHostUser = onCall(
  { secrets: [POSTMARK_SERVER_TOKEN] },
  async (request) => {
  try {
    const {
      organisationId,
      email,
      name,
      address,
      country,
      isDisabled = false,
      sendEmail = false,
    } = request.data || {};

    const orgId = (organisationId || "").toString().trim();
    const emLower = (email || "").toString().trim().toLowerCase();
    const displayName = (name || "").toString().trim();
    const addr = (address || "").toString().trim();
    const ctry = (country || "").toString().trim();

    if (!orgId) throw new HttpsError("invalid-argument", "organisationId is required");
    if (!displayName) throw new HttpsError("invalid-argument", "name is required");
    if (!emLower || !emLower.includes("@"))
      throw new HttpsError("invalid-argument", "Valid email is required");

    await requireAdminForOrg(request, orgId);

    const auth = getAuth();

    let authUser;
    let created = false;

    try {
      authUser = await auth.getUserByEmail(emLower);
    } catch (e) {
      const tempPassword = randomBytes(12).toString("hex");
      authUser = await auth.createUser({
        email: emLower,
        password: tempPassword,
        displayName: displayName || undefined,
        disabled: !!isDisabled,
        emailVerified: true, // Mark as verified - email ownership proven when they receive the invite
      });
      created = true;
    }

    const uid = authUser.uid;

    const userRef = db.collection("users").doc(uid);
    const userSnap = await userRef.get();

    if (userSnap.exists) {
      const existingRole = (userSnap.data()?.role || "").toString();
      if (existingRole && existingRole !== "host") {
        throw new HttpsError(
          "failed-precondition",
          `This email is already used by a non-host account (role: ${existingRole}).`
        );
      }
    }

    const now = Timestamp.now();

    await userRef.set(
      {
        userId: uid,
        email: emLower,
        emailLower: emLower,
        role: "host",
        isDisabled: !!isDisabled,
        name: displayName,
        ...(addr ? { address: addr } : {}),
        ...(ctry ? { country: ctry } : {}),
        managedByOrgIds: FieldValue.arrayUnion(orgId),
        modifiedAt: now,
        ...(userSnap.exists ? {} : { createdAt: now }),
      },
      { merge: true }
    );

    const orgHostRef = db
      .collection("organisations")
      .doc(orgId)
      .collection("hosts")
      .doc(uid);

    await orgHostRef.set(
      {
        hostUid: uid,
        email: emLower,
        emailLower: emLower,
        name: displayName,
        ...(addr ? { address: addr } : {}),
        ...(ctry ? { country: ctry } : {}),
        isDisabled: !!isDisabled,
        updatedAt: now,
        ...(created ? { createdAt: now } : {}),
      },
      { merge: true }
    );

    let emailSent = false;
    let passwordResetLink = null;

    // Send setup email with password reset link if requested
    if (sendEmail) {
      try {
        const token = (POSTMARK_SERVER_TOKEN.value() || "").trim();
        if (!token) {
          console.warn("POSTMARK_SERVER_TOKEN missing, skipping email.");
        } else {
          // Generate Firebase password reset link
          const firebaseResetLink = await auth.generatePasswordResetLink(emLower);
          // Convert to our custom app URL
          passwordResetLink = buildCustomPasswordResetLink(firebaseResetLink);

          const client = new postmark.ServerClient(token);
          const safeName = displayName || "there";

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
            From: `${FROM_NAME} <${FROM_EMAIL}>`,
            To: emLower,
            Subject: "Welcome to Trax Host Portal - Set Up Your Password",
            HtmlBody: html,
          });

          emailSent = true;

          // Update Firestore with email sent timestamp
          await orgHostRef.set(
            {
              setupEmailSentAt: now,
              updatedAt: now,
            },
            { merge: true }
          );
        }
      } catch (emailErr) {
        console.error("Failed to send setup email:", emailErr);
        // Don't fail the whole operation if email fails
      }
    }

    return { 
      uid, 
      email: emLower, 
      created, 
      alreadyVerified: authUser.emailVerified === true,
      emailSent,
    };
    } catch (err) {
    console.error("createHostUser error:", err);

    // ✅ Do NOT rely on instanceof (can fail across bundles/ESM).
    const httpsCodes = new Set([
      "cancelled","unknown","invalid-argument","deadline-exceeded","not-found",
      "already-exists","permission-denied","resource-exhausted","failed-precondition",
      "aborted","out-of-range","unimplemented","internal","unavailable","data-loss","unauthenticated"
    ]);

    // 1) If it's already an HttpsError-like object, rethrow as-is
    if (err && typeof err.code === "string" && httpsCodes.has(err.code)) {
      throw err;
    }

    // 2) Map Firebase Auth errors to readable HttpsError codes
    const code = (err && err.code ? String(err.code) : "");
    const msg = (err && err.message ? String(err.message) : String(err));

    if (code.startsWith("auth/")) {
      if (code === "auth/email-already-exists") {
        throw new HttpsError("already-exists", "Email already exists.");
      }
      if (code === "auth/invalid-email") {
        throw new HttpsError("invalid-argument", "Invalid email.");
      }
      if (code === "auth/user-not-found") {
        throw new HttpsError("not-found", "User not found.");
      }
      // fallback for other auth errors
      throw new HttpsError("failed-precondition", msg);
    }

    // 3) Anything else -> internal, but include details so Flutter can show it
    throw new HttpsError("internal", "createHostUser failed", {
      rawCode: code,
      rawMessage: msg,
      stack: err?.stack || null,
    });
  }

});

