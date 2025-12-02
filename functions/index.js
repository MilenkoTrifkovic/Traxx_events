import * as logger from "firebase-functions/logger";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onAuthUserCreated } from "firebase-functions/v2/auth";

import { initializeApp, getApps } from "firebase-admin/app";
import * as admin from "firebase-admin";
import { FieldValue } from "firebase-admin/firestore";

import { v4 as uuidv4 } from "uuid";

// Initialize Firebase Admin exactly once
if (!getApps().length) {
    initializeApp();
}

// Firestore & Auth handles
const db = admin.firestore();
const auth = admin.auth();

const SUPER_ADMIN_EMAILS = [
    "rahulross23@gmail.com", // example, change to your real emails
];

export const saveCompanyInfo = onCall(async (request) => {
    try {
        if (!request.auth || !request.auth.uid) {
            throw new HttpsError("unauthenticated", "You must be signed in.");
        }

        const userId = request.auth.uid;

        // Load caller
        const userRef = db.collection("users").doc(userId);
        const userSnap = await userRef.get();
        if (!userSnap.exists) {
            throw new HttpsError(
                "failed-precondition",
                "User document does not exist for this account."
            );
        }
        const userData = userSnap.data();
        const currentRole = userData.role || "guest";
        const currentOrgId = userData.organisationId || null;
        const isSuperAdmin = currentRole === "superAdmin";

        // Normal users: only one organisation
        if (!isSuperAdmin && currentOrgId) {
            throw new HttpsError(
                "permission-denied",
                "You already belong to an organisation."
            );
        }

        // Each user can only be admin of one org (optional extra guard)
        const existingAdminRole = await db
            .collection("roles")
            .where("userId", "==", userId)
            .where("role", "==", "admin")
            .where("isDisabled", "==", false)
            .limit(1)
            .get();

        if (!existingAdminRole.empty && !isSuperAdmin) {
            const existingRole = existingAdminRole.docs[0].data();
            console.log(
                `User ${userId} already has an admin role for organisation ${existingRole.organisationId}`
            );

            throw new HttpsError(
                "already-exists",
                "You have already created an organisation. Each user can only create one organisation."
            );
        }

        // Your existing validation
        validateCompanyInfo(request.data);

        const organisationId = uuidv4();
        const roleId = uuidv4();

        const organisationData = {
            organisationId,
            name: request.data.name,
            phone: request.data.phone.toString(),
            website: request.data.website || null,
            address: {
                street: request.data.address.street,
                city: request.data.address.city,
                state: request.data.address.state,
                zip: request.data.address.zip.toString(),
                country: request.data.address.country,
            },
            timezone: request.data.timezone,
            logo: request.data.logo || null,
            isDisabled: false,
            createdAt: FieldValue.serverTimestamp(),
            modifiedAt: FieldValue.serverTimestamp(),
        };

        const roleData = {
            roleId,
            userId,
            organisationId,
            role: "admin",
            isDisabled: false,
            createdAt: FieldValue.serverTimestamp(),
            modifiedAt: FieldValue.serverTimestamp(),
        };

        // Create organisation + role in a transaction
        const result = await db.runTransaction(async (transaction) => {
            const organisationRef = db.collection("organisations").doc();
            transaction.set(organisationRef, organisationData);

            const roleRef = db.collection("roles").doc();
            transaction.set(roleRef, roleData);

            return {
                organisationDocId: organisationRef.id,
                roleDocId: roleRef.id,
                organisationId,
                roleId,
            };
        });

        // 🔑 KEY PART: make this user admin of the new company
        await userRef.set(
            {
                role: "admin",
                organisationId,
                modifiedAt: FieldValue.serverTimestamp(),
            },
            { merge: true }
        );

        // And set Auth custom claims as well
        await admin.auth().setCustomUserClaims(userId, {
            role: "admin",
            organisationId,
        });

        console.log(
            `Company info and admin role saved. OrgUUID: ${organisationId}, RoleUUID: ${roleId}`
        );

        return {
            success: true,
            message: "Company information and admin role created successfully",
            organisationId,
            roleId,
            roleDocumentId: result.roleDocId,
        };
    } catch (error) {
        console.error("Error saving company info:", error);

        if (error.code && error.message) {
            throw error;
        }

        throw new HttpsError(
            "internal",
            "An error occurred while saving the company information."
        );
    }
});

export const attachUserToExistingOrganisation = onCall(async (request) => {
    if (!request.auth || !request.auth.uid) {
        throw new HttpsError("unauthenticated", "You must be signed in.");
    }

    const userId = request.auth.uid;
    const orgId = request.data?.organisationId;

    if (!orgId) {
        throw new HttpsError(
            "invalid-argument",
            "organisationId is required."
        );
    }

    const userRef = db.collection("users").doc(userId);
    const userSnap = await userRef.get();
    if (!userSnap.exists) {
        throw new HttpsError(
            "failed-precondition",
            "User document does not exist."
        );
    }

    const userData = userSnap.data();
    const currentOrgId = userData.organisationId || null;

    // Allow attaching only if user has no organisation yet
    if (currentOrgId && currentOrgId !== orgId) {
        throw new HttpsError(
            "permission-denied",
            "User already belongs to an organisation."
        );
    }

    await userRef.set(
        {
            organisationId: orgId,
            modifiedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
    );

    // Optionally keep role as-is (guest/user/admin), we don't change it here
    // Or set to 'user' if you want every attached user to be normal user:
    // await userRef.set({ role: "user" }, { merge: true });

    return { success: true };
});


export const inviteOrganisationUser = onCall(async (request) => {
    const auth = request.auth;
    if (!auth) {
        throw new HttpsError("unauthenticated", "You must be signed in.");
    }

    const { email, organisationId, role } = request.data || {};
    if (!email) {
        throw new HttpsError("invalid-argument", "email is required.");
    }

    const validRoles = ["user", "admin"];
    if (!validRoles.includes(role)) {
        throw new HttpsError(
            "invalid-argument",
            "role must be 'user' or 'admin'."
        );
    }

    const callerUid = auth.uid;
    const callerDoc = await db.collection("users").doc(callerUid).get();
    if (!callerDoc.exists) {
        throw new HttpsError(
            "permission-denied",
            "Caller user document does not exist."
        );
    }

    const caller = callerDoc.data();
    const callerRole = caller.role; // guest/user/admin/superAdmin
    const callerOrgId = caller.organisationId || null;

    if (!callerRole) {
        throw new HttpsError("permission-denied", "Caller has no role.");
    }

    const isSuperAdmin = callerRole === "superAdmin";

    // Only SUPER ADMIN can invite new ADMINS directly
    if (role === "admin" && !isSuperAdmin) {
        throw new HttpsError(
            "permission-denied",
            "Only super admins can invite admins directly. Admins should invite as 'user' and then promote."
        );
    }

    // Only ADMIN or SUPER ADMIN can invite normal org users
    if (role === "user" && !["admin", "superAdmin"].includes(callerRole)) {
        throw new HttpsError(
            "permission-denied",
            "Only admins or super admins can invite organisation users."
        );
    }

    // Determine target organisation
    let targetOrgId = organisationId || callerOrgId;
    if (!targetOrgId) {
        throw new HttpsError(
            "invalid-argument",
            "organisationId is required for this invite."
        );
    }

    // Admins can only invite into *their* organisation
    if (callerRole === "admin" && targetOrgId !== callerOrgId) {
        throw new HttpsError(
            "permission-denied",
            "Admins can only invite into their own organisation."
        );
    }

    const inviteRef = await db.collection("organisationInvites").add({
        email: email.toLowerCase(),
        organisationId: targetOrgId,
        role, // 'user' or 'admin'
        status: "pending",
        createdByUserId: callerUid,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { inviteId: inviteRef.id };
});

export const handleNewUser = onAuthUserCreated(async (event) => {
    const user = event.data;
    const email = (user.email || "").toLowerCase();

    let role = "guest";
    let organisationId = null;

    // Super admin shortcut
    if (SUPER_ADMIN_EMAILS.includes(email)) {
        role = "superAdmin";
    } else {
        // Check if this email was invited
        const inviteSnap = await db
            .collection("organisationInvites")
            .where("email", "==", email)
            .where("status", "==", "pending")
            .limit(1)
            .get();

        if (!inviteSnap.empty) {
            const inviteDoc = inviteSnap.docs[0];
            const invite = inviteDoc.data();

            role = invite.role || "user"; // 'user' or 'admin'
            organisationId = invite.organisationId || null;

            await inviteDoc.ref.update({
                status: "accepted",
                acceptedUserId: user.uid,
                acceptedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        }
    }

    const userDoc = {
        userId: user.uid,
        email,
        role,
        organisationId,
        isDisabled: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        modifiedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await db.collection("users").doc(user.uid).set(userDoc);

    if (organisationId) {
        await db.collection("roles").add({
            userId: user.uid,
            organisationId,
            role, // 'admin' or 'user'
            isDisabled: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            modifiedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    }

    await admin.auth().setCustomUserClaims(user.uid, {
        role,
        organisationId,
    });

    return;
});

export const updateOrganisationUserRole = onCall(async (request) => {
    const auth = request.auth;
    if (!auth) {
        throw new HttpsError("unauthenticated", "You must be signed in.");
    }

    const { userId, organisationId, newRole } = request.data || {};
    if (!userId || !organisationId || !newRole) {
        throw new HttpsError(
            "invalid-argument",
            "userId, organisationId and newRole are required."
        );
    }

    const allowedRoles = ["user", "admin"];
    if (!allowedRoles.includes(newRole)) {
        throw new HttpsError(
            "invalid-argument",
            "newRole must be 'user' or 'admin'."
        );
    }

    // ───────── Caller (who is trying to change someone) ─────────
    const callerUid = auth.uid;
    const callerSnap = await db.collection("users").doc(callerUid).get();
    if (!callerSnap.exists) {
        throw new HttpsError(
            "permission-denied",
            "Caller user document does not exist."
        );
    }

    const caller = callerSnap.data();
    const callerRole = caller.role;              // guest/user/admin/superAdmin
    const callerOrgId = caller.organisationId || null;
    const callerIsSuperAdmin = callerRole === "superAdmin";

    if (!callerRole) {
        throw new HttpsError("permission-denied", "Caller has no role.");
    }

    // ✅ ONLY superAdmin OR admin of *this* org may change roles
    if (
        !callerIsSuperAdmin &&              // not superAdmin
        !(
            callerRole === "admin" &&
            callerOrgId != null &&
            callerOrgId === organisationId    // must match the org being edited
        )
    ) {
        throw new HttpsError(
            "permission-denied",
            "Only admins of this organisation or super admins can change user roles."
        );
    }

    // ───────── Target user (the one whose role will change) ─────────
    const targetRef = db.collection("users").doc(userId);
    const targetSnap = await targetRef.get();
    if (!targetSnap.exists) {
        throw new HttpsError("not-found", "Target user does not exist.");
    }
    const target = targetSnap.data();

    // Never allow this function to touch superAdmin accounts
    if (target.role === "superAdmin") {
        throw new HttpsError(
            "permission-denied",
            "Cannot change role of a super admin with this function."
        );
    }

    const targetOrgId = target.organisationId || null;

    // ✅ Extra safety: an admin can ONLY update users from THEIR company
    if (!callerIsSuperAdmin && targetOrgId !== organisationId) {
        throw new HttpsError(
            "permission-denied",
            "Admins may only update users that belong to their own organisation."
        );
    }

    // ───────── Perform updates ─────────
    await targetRef.set(
        {
            role: newRole,
            organisationId,
            modifiedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
    );

    // Keep roles collection in sync
    const rolesSnap = await db
        .collection("roles")
        .where("userId", "==", userId)
        .where("organisationId", "==", organisationId)
        .where("isDisabled", "==", false)
        .limit(1)
        .get();

    if (!rolesSnap.empty) {
        await rolesSnap.docs[0].ref.update({
            role: newRole,
            modifiedAt: FieldValue.serverTimestamp(),
        });
    } else {
        await db.collection("roles").add({
            userId,
            organisationId,
            role: newRole,
            isDisabled: false,
            createdAt: FieldValue.serverTimestamp(),
            modifiedAt: FieldValue.serverTimestamp(),
        });
    }

    await admin.auth().setCustomUserClaims(userId, {
        role: newRole,
        organisationId,
    });

    return { success: true };
});

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
});

