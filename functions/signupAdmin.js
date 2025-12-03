import { onCall, HttpsError } from "firebase-functions/v2/https";
import logger from "firebase-functions/logger";
import { initializeApp, getApps } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
// Optional – only use if you actually call it:
// import { validateUserCredentials } from "./validators/userCredentialValidator.js";

// Ensure default app exists (safe in ESM)
if (!getApps().length) {
    initializeApp();
}

// Use modular admin SDK
const auth = getAuth();
const db = getFirestore();

export const signupAdmin = onCall(async (request) => {
    const data = request.data || {};

    const email = (data.email || "").toString().trim();
    const password = (data.password || "").toString();

    // ── Basic validation (must match Flutter ValidationHelper) ────────────────
    if (!email || !password) {
        throw new HttpsError(
            "invalid-argument",
            "Email and password are required."
        );
    }

    const emailRegex = /^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$/;
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
            // Check if user already exists
            userRecord = await auth.getUserByEmail(email);

            // If we got a user, the account already exists
            throw new HttpsError(
                "already-exists",
                "The account already exists for this email."
            );
        } catch (err) {
            if (err && err.code === "auth/user-not-found") {
                // Safe to create a new user
                userRecord = await auth.createUser({
                    email,
                    password,
                    emailVerified: false,
                    disabled: false,
                });
            } else if (err instanceof HttpsError) {
                // The "already-exists" error we just threw above
                throw err;
            } else if (err && err.code) {
                logger.error("Auth error while checking/creating user:", err);
                throw new HttpsError("internal", err.message || "Auth error");
            }
        }

        // /users/{uid} will be created by handleNewUser (auth trigger).

        return {
            uid: userRecord.uid,
            email,
        };
    } catch (err) {
        if (err instanceof HttpsError) {
            throw err;
        }

        logger.error("Unexpected error in signupAdmin:", err);
        throw new HttpsError(
            "internal",
            "Failed to create account. Please try again."
        );
    }
});

/**
 * Callable function used by the Flutter client to sign up a new admin user.
 * Expected payload: { email: string, password: string }
 */
/* export const signupAdmin = onCall(async (request) => {

    const data = request.data || {};

    const email = (data.email || "").toString().trim();
    const password = (data.password || "").toString();

    // ── Basic validation (must match Flutter ValidationHelper) ────────────────
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

    // If you want to use your own validator:
    // const validationError = validateUserCredentials(email, password);
    // if (validationError) {
    //   throw new HttpsError("invalid-argument", validationError);
    // }

    try {
        // ── Create the Firebase Auth user ──────────────────────────────────────
        let userRecord;
        try {
            // Check if the user already exists
            userRecord = await auth.getUserByEmail(email);
            throw new HttpsError(
                "already-exists",
                "The account already exists for this email."
            );
        } catch (err) {
            if (err.code === "auth/user-not-found") {
                userRecord = await auth.createUser({
                    email,
                    password,
                    emailVerified: false,
                    disabled: false,
                });
            } else {
                logger.error("Auth error while checking/creating user:", err);
                throw new HttpsError("internal", err.message || "Auth error");
            }
        }

        // ── Create Firestore user document ─────────────────────────────────────
        await db.collection("users").add({
            email,
            userId: userRecord.uid,
            isDisabled: false,
            createdAt: FieldValue.serverTimestamp(),
            modifiedAt: FieldValue.serverTimestamp(),
        });

        // Response back to Flutter
        return {
            uid: userRecord.uid,
            email,
        };
    } catch (err) {
        if (err instanceof HttpsError) {
            throw err;
        }

        logger.error("Unexpected error in signupAdmin:", err);
        throw new HttpsError(
            "internal",
            "Failed to create account. Please try again."
        );
    }
}); */