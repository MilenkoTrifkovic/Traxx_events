// functions/methods/handleNewUser.js
import * as functions from "firebase-functions";
import { initializeApp, getApps } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

// Ensure default Admin app exists
if (!getApps().length) {
    initializeApp();
}

// Modular Admin SDK
const auth = getAuth();
const db = getFirestore();

/**
 * Auth trigger – runs whenever a Firebase Auth user is created.
 *
 * New simple logic:
 *  - Everyone is created as role: "admin"
 *  - organisationId starts as null
 *  - /users/{uid} doc is created
 *  - custom claims are set
 */
export const handleNewUser = functions.auth.user().onCreate(async (user) => {
    const email = (user.email || "").toLowerCase();

    const role = "admin";
    const organisationId = null;

    const userDoc = {
        userId: user.uid,
        email,
        role, // "admin"
        organisationId, // null initially
        isDisabled: false,
        createdAt: FieldValue.serverTimestamp(),
        modifiedAt: FieldValue.serverTimestamp(),
    };

    // Create /users/{uid} doc
    await db.collection("users").doc(user.uid).set(userDoc);

    // Keep custom claims in sync
    await auth.setCustomUserClaims(user.uid, {
        role,
        organisationId,
    });

    return;
});
