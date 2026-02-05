import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getAuth } from "firebase-admin/auth";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "./admin.js";

const auth = getAuth();

export const signupAdmin = onCall(async (request) => {
  const data = request.data || {};

  const email = (data.email || "").toString().trim();
  const password = (data.password || "").toString();

  const name = (data.name || "").toString().trim() || null;
  const country = (data.country || "").toString().trim() || null;

  const role = "admin";

  const emailRegex = /^[\w.+-]+@([\w-]+\.)+[\w-]{2,}$/;

  if (!email || !password) {
    throw new HttpsError("invalid-argument", "Email and password are required.");
  }
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
    let userRecord;
    try {
      userRecord = await auth.createUser({
        email,
        password,
        emailVerified: false,
        disabled: false,
        // ✅ ok to set for Auth profile, but NOT stored in Firestore
        displayName: name || undefined,
      });
    } catch (err) {
      if (err?.code === "auth/email-already-exists") {
        throw new HttpsError("already-exists", "The account already exists for this email.");
      }
      throw new HttpsError("internal", err?.message || "Auth error while creating user.");
    }

    const uid = userRecord.uid;

    await db.collection("users").doc(uid).set(
      {
        userId: uid,
        name: name,
        email: email,

        role: role,
        country: country,

        isDisabled: false,
        managedByOrgIds: null,
        organisationId: null,

        // ✅ exists but null for admins
        refCode: null,

        createdAt: FieldValue.serverTimestamp(),
        modifiedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    return {
      ok: true,
      userId: uid,
      email,
      role,
      organisationId: null,
    };
  } catch (err) {
    if (err instanceof HttpsError) throw err;
    throw new HttpsError(
      "internal",
      err?.message || "Failed to create account. Please try again."
    );
  }
});




