// functions/signupAdmin.js

import { onCall, HttpsError } from "firebase-functions/v2/https";
// import * as logger from "firebase-functions/logger";
import { initializeApp, getApps } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

if (!getApps().length) {
  initializeApp();
}

const auth = getAuth();
const db = getFirestore();

/**
 * Callable function used by the Flutter client to sign up a new admin user.
 * Expected payload: { email: string, password: string }
 */
export const signupAdmin = onCall(async (request) => {
  const data = request.data || {};

  const email = (data.email || "").toString().trim();
  const password = (data.password || "").toString();

  // ── Basic validation ────────────────────────────────────────────────────────
  if (!email || !password) {
    throw new HttpsError(
      "invalid-argument",
      "Email and password are required."
    );
  }

  const emailRegex = /^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/;
  if (!emailRegex.test(email)) {
    throw new HttpsError("invalid-argument", "Invalid email format.");
  }

  if (password.length < 6) {
    throw new HttpsError(
      "invalid-argument",
      "Password must be at least 6 characters long."
    );
  }

  try {
    // ── Create the Firebase Auth user ────────────────────────────────────────
    let userRecord;
    try {
      userRecord = await auth.createUser({
        email,
        password,
        emailVerified: false,
        disabled: false,
      });
    } catch (err) {
      // If the email already exists in Firebase Auth
      if (err?.code === "auth/email-already-exists") {
        throw new HttpsError(
          "already-exists",
          "The account already exists for this email."
        );
      }

    //   logger.error("Error creating user in Firebase Auth:", err);
      throw new HttpsError(
        "internal",
        err?.message || "Auth error while creating user."
      );
    }

    // ── Create / upsert Firestore user document ──────────────────────────────
    await db.collection("users").doc(userRecord.uid).set(
      {
        email,
        userId: userRecord.uid,
        isDisabled: false,
        createdAt: FieldValue.serverTimestamp(),
        modifiedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    // ── Success response back to Flutter ─────────────────────────────────────
    return {
      uid: userRecord.uid,
      email,
    };
  } catch (err) {
    if (err instanceof HttpsError) {
      // Let known HttpsErrors bubble up to the client
      throw err;
    }

    // logger.error("Unexpected error in signupAdmin:", err);
    throw new HttpsError(
      "internal",
      "Failed to create account. Please try again."
    );
  }
});

