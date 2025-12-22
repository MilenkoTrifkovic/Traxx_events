// functions/signupAdmin.js
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getAuth } from "firebase-admin/auth";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "./admin.js";

// if (!getApps().length) {
//   initializeApp();
// }

const auth = getAuth();
// const db = getFirestore();

/**
 * Callable function used by the Flutter client to sign up a new admin user.
 * Expected payload: { email: string, password: string }
 */
export const signupAdmin = onCall(async (request) => {
  const data = request.data || {};

  const email = (data.email || "").toString().trim();
  const password = (data.password || "").toString();

  // ── Basic validation ───────────────────────────────────────────────────────
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
      if (err?.code === "auth/email-already-exists") {
        throw new HttpsError(
          "already-exists",
          "The account already exists for this email."
        );
      }

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

        // 🔥 Everyone who signs up is an admin by default
        role: "admin",

        // organisationId is not known yet. It will be
        // filled by saveCompanyInfo later.
        organisationId: null,
      },
      { merge: true }
    );

    // ── Success response back to Flutter ─────────────────────────────────────
    return {
      uid: userRecord.uid,
      email,
      role: "admin",
      organisationId: null,
    };
  } catch (err) {
    if (err instanceof HttpsError) {
      throw err;
    }

    throw new HttpsError(
      "internal",
      err?.message || "Failed to create account. Please try again."
    );
  }
});

