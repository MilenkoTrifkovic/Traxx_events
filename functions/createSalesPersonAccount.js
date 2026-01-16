import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import postmark from "postmark";

// Secret for Postmark API
const POSTMARK_SERVER_TOKEN = defineSecret("POSTMARK_SERVER_TOKEN");

// Email configuration
const FROM_EMAIL = "developer@trax-event.com";
const FROM_NAME = "Trax Sales Portal";

/**
 * Cloud function to create a sales person account
 * Creates Firebase Auth user and sends password reset email
 * 
 * Expected request data:
 * - email: string (required)
 * - name: string (required)
 * - salesPersonId: string (required) - from Firestore doc
 * 
 * Returns:
 * - uid: Firebase Auth user ID
 * - message: Success message
 */
export const createSalesPersonAccount = onCall(
  { secrets: [POSTMARK_SERVER_TOKEN] },
  async (request) => {
  const { auth, data } = request;

  // Security: Only super admins can create sales person accounts
  if (!auth) {
    throw new HttpsError("unauthenticated", "Authentication required");
  }

  try {
    const db = getFirestore();
    const userDoc = await db.collection("users").doc(auth.uid).get();

    if (!userDoc.exists || userDoc.data()?.role !== "super_admin") {
      throw new HttpsError(
        "permission-denied",
        "Only super admins can create sales person accounts"
      );
    }
  } catch (error) {
    logger.error("Error checking admin permissions:", error);
    throw new HttpsError("internal", "Failed to verify permissions");
  }

  // Validate input
  const { email, name, salesPersonId } = data;

  if (!email || typeof email !== "string") {
    throw new HttpsError("invalid-argument", "Valid email is required");
  }

  if (!name || typeof name !== "string") {
    throw new HttpsError("invalid-argument", "Valid name is required");
  }

  if (!salesPersonId || typeof salesPersonId !== "string") {
    throw new HttpsError("invalid-argument", "Valid salesPersonId is required");
  }

  // Validate email format
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    throw new HttpsError("invalid-argument", "Invalid email format");
  }

  try {
    const authService = getAuth();

    // Get Postmark token
    const token = (POSTMARK_SERVER_TOKEN.value() || "").trim();
    if (!token) {
      throw new HttpsError(
        "failed-precondition",
        "POSTMARK_SERVER_TOKEN missing/empty at runtime."
      );
    }

    const postmarkClient = new postmark.ServerClient(token);

    // Check if user already exists
    let userRecord;
    let resetLink;
    let isExistingUser = false;

    try {
      const existingUser = await authService.getUserByEmail(email);
      logger.info(`User already exists with email: ${email}`);
      
      userRecord = existingUser;
      isExistingUser = true;

      // Update their custom claims to include sales person role
      await authService.setCustomUserClaims(existingUser.uid, {
        role: "sales_person",
        salesPersonId: salesPersonId,
      });

      // Generate password reset link
      resetLink = await authService.generatePasswordResetLink(email);
      logger.info(`Password reset link generated for existing user: ${email}`);
    } catch (userNotFoundError) {
      // User doesn't exist, create new one
      logger.info(`Creating new user for: ${email}`);

      // Create Firebase Auth user
      userRecord = await authService.createUser({
        email: email,
        displayName: name,
        emailVerified: false,
      });

      logger.info(`Created Firebase Auth user: ${userRecord.uid}`);

      // Set custom claims for role-based access
      await authService.setCustomUserClaims(userRecord.uid, {
        role: "sales_person",
        salesPersonId: salesPersonId,
      });

      logger.info(`Set custom claims for user: ${userRecord.uid}`);

      // Generate password reset link
      resetLink = await authService.generatePasswordResetLink(email);
      logger.info(`Password reset link generated for: ${email}`);
    }

    // Send email via Postmark
    const subject = "Set Up Your Trax Sales Portal Password";
    
    const textBody =
      `Hello ${name},\n\n` +
      `Your Trax Sales Portal account has been created. Please click the link below to set up your password:\n\n` +
      `${resetLink}\n\n` +
      `This link will expire in 1 hour.\n\n` +
      `Once you've set your password, you'll be able to log in to the sales portal.\n\n` +
      `— ${FROM_NAME}`;

    const htmlBody = `
      <div style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
        <h2 style="color: #2563eb;">Welcome to Trax Sales Portal</h2>
        <p>Hello ${name},</p>
        <p>Your Trax Sales Portal account has been created as a Sales Person. Please click the button below to set up your password:</p>
        
        <p style="margin: 24px 0;">
          <a href="${resetLink}" style="display:inline-block;padding:12px 24px;background:#2563eb;color:#fff;text-decoration:none;border-radius:6px;font-weight:bold;">
            Set Up Password
          </a>
        </p>
        
        <p style="color:#6b7280;font-size:14px;">
          If the button doesn't work, copy and paste this link into your browser:<br/>
          <a href="${resetLink}" style="color:#2563eb;">${resetLink}</a>
        </p>
        
        <hr style="border:none;border-top:1px solid #e5e7eb;margin:24px 0;">
        
        <p>After setting up your password, access the Sales Portal here:</p>
        
        <p style="margin: 24px 0;">
          <a href="https://trax-admin-portal.web.app" style="display:inline-block;padding:12px 24px;background:#10b981;color:#fff;text-decoration:none;border-radius:6px;font-weight:bold;">
            Open Sales Portal
          </a>
        </p>
        
        <p style="color:#6b7280;font-size:14px;">
          If the button doesn't work, copy and paste this link into your browser:<br/>
          <a href="https://trax-admin-portal.web.app" style="color:#2563eb;">https://trax-admin-portal.web.app</a>
        </p>
        
        <p style="color:#6b7280;font-size:13px;margin-top:20px;">
          <strong>Note:</strong> This link will expire in 1 hour for security reasons.
        </p>
        
        <p style="margin-top:24px;">Once you've set your password, you'll be able to log in to the sales portal and start managing your assignments.</p>
        
        <hr style="border:none;border-top:1px solid #e5e7eb;margin:24px 0;">
        
        <p style="color:#6b7280;font-size:12px;">
          — ${FROM_NAME}<br/>
          <a href="mailto:${FROM_EMAIL}" style="color:#2563eb;">${FROM_EMAIL}</a>
        </p>
      </div>
    `;

    try {
      const emailResult = await postmarkClient.sendEmail({
        From: FROM_EMAIL,
        To: email,
        Subject: subject,
        TextBody: textBody,
        HtmlBody: htmlBody,
        MessageStream: "outbound",
      });

      logger.info(`Password setup email sent successfully to ${email}`, {
        messageId: emailResult.MessageID,
      });
    } catch (emailError) {
      logger.error(`Failed to send email to ${email}:`, emailError);
      throw new HttpsError(
        "internal",
        `Account created but failed to send email: ${emailError.message}`
      );
    }

    return {
      uid: userRecord.uid,
      message: isExistingUser 
        ? "User already exists. Password setup email sent."
        : "Sales person account created successfully. Password setup email sent.",
      alreadyExists: isExistingUser,
    };
  } catch (error) {
    logger.error("Error creating sales person account:", error);

    // Handle specific Firebase Auth errors
    if (error.code === "auth/email-already-exists") {
      throw new HttpsError(
        "already-exists",
        "An account with this email already exists"
      );
    }

    if (error.code === "auth/invalid-email") {
      throw new HttpsError("invalid-argument", "Invalid email format");
    }

    if (error.code === "auth/operation-not-allowed") {
      throw new HttpsError(
        "failed-precondition",
        "Email/password accounts are not enabled"
      );
    }

    throw new HttpsError(
      "internal",
      `Failed to create sales person account: ${error.message}`
    );
  }
});