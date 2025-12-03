/* /* eslint-disable 
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { v4: uuidv4 } = require("uuid");

// Initialize Firebase Admin once
if (admin.apps.length === 0) {
    admin.initializeApp();
}

const db = admin.firestore();
const auth = admin.auth();

const SUPER_ADMIN_EMAILS = [
    "rahulross23@gmail.com", // update as needed
];
function validateCompanyInfo(data) {
    const HttpsError = functions.https.HttpsError;

    if (!data) {
        throw new HttpsError("invalid-argument", "Company data is required.");
    }

    if (!data.name || typeof data.name !== "string") {
        throw new HttpsError("invalid-argument", "Company name is required.");
    }

    if (!data.phone) {
        throw new HttpsError("invalid-argument", "Company phone is required.");
    }

    if (!data.address) {
        throw new HttpsError("invalid-argument", "Company address is required.");
    }

    const { street, city, state, zip, country } = data.address;
    if (!street || !city || !state || !zip || !country) {
        throw new HttpsError(
            "invalid-argument",
            "Address must include street, city, state, zip and country."
        );
    }

    if (!data.timezone) {
        throw new HttpsError("invalid-argument", "timezone is required.");
    }
}

// Convenience helper (so we don't repeat)
function getHttpsError() {
    return functions.https.HttpsError;
}
exports.saveCompanyInfo = functions.https.onCall(async (data, context) => {
    const HttpsError = getHttpsError();

    try {
        if (!context.auth || !context.auth.uid) {
            throw new HttpsError("unauthenticated", "You must be signed in.");
        }

        const userId = context.auth.uid;

        // Load caller
        const userRef = db.collection("users").doc(userId);
        const userSnap = await userRef.get();
        if (!userSnap.exists) {
            throw new HttpsError(
                "failed-precondition",
                "User document does not exist for this account."
            );
        }

        const userData = userSnap.data() || {};
        const currentRole = userData.role || "guest";
        const currentOrgId = userData.organisationId || null;
        const isPlatformSuperAdmin =
            currentRole === "superAdmin" && !currentOrgId;

        // Normal users: only one organisation
        if (!isPlatformSuperAdmin && currentOrgId) {
            throw new HttpsError(
                "permission-denied",
                "You already belong to an organisation."
            );
        }

        // Each user can only be superAdmin of one org
        const existingSuperAdminRole = await db
            .collection("roles")
            .where("userId", "==", userId)
            .where("role", "==", "superAdmin")
            .where("isDisabled", "==", false)
            .limit(1)
            .get();

        if (!existingSuperAdminRole.empty && !isPlatformSuperAdmin) {
            const existingRole = existingSuperAdminRole.docs[0].data();
            console.log(
                "User " +
                userId +
                " already has a superAdmin role for organisation " +
                existingRole.organisationId
            );

            throw new HttpsError(
                "already-exists",
                "You have already created an organisation. Each user can only create one organisation."
            );
        }

        // Validate incoming data (from `data`, not `request.data` anymore)
        validateCompanyInfo(data);

        const organisationId = uuidv4();
        const roleId = uuidv4();

        const organisationData = {
            organisationId,
            name: data.name,
            phone: data.phone.toString(),
            website: data.website || null,
            address: {
                street: data.address.street,
                city: data.address.city,
                state: data.address.state,
                zip: data.address.zip.toString(),
                country: data.address.country,
            },
            timezone: data.timezone,
            logo: data.logo || null,
            isDisabled: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            modifiedAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        const roleData = {
            roleId,
            userId,
            organisationId,
            role: "superAdmin", // company owner
            isDisabled: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            modifiedAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        // Create organisation + superAdmin role in a transaction
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

        // Make this user SUPERADMIN of the new company
        await userRef.set(
            {
                role: "superAdmin",
                organisationId,
                modifiedAt: admin.firestore.FieldValue.serverTimestamp(),
            },
            { merge: true }
        );

        // Custom claims for auth
        await admin.auth().setCustomUserClaims(userId, {
            role: "superAdmin",
            organisationId,
        });

        console.log(
            "Company info and superAdmin role saved. OrgUUID: " +
            organisationId +
            ", RoleUUID: " +
            roleId
        );

        return {
            success: true,
            message:
                "Company information and super admin role created successfully",
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
exports.attachUserToExistingOrganisation = functions.https.onCall(
    async (data, context) => {
        const HttpsError = getHttpsError();

        if (!context.auth || !context.auth.uid) {
            throw new HttpsError("unauthenticated", "You must be signed in.");
        }

        const userId = context.auth.uid;
        const orgId = data && data.organisationId;

        if (!orgId) {
            throw new HttpsError("invalid-argument", "organisationId is required.");
        }

        const userRef = db.collection("users").doc(userId);
        const userSnap = await userRef.get();
        if (!userSnap.exists) {
            throw new HttpsError(
                "failed-precondition",
                "User document does not exist."
            );
        }

        const userData = userSnap.data() || {};
        const currentOrgId = userData.organisationId || null;

        if (currentOrgId && currentOrgId !== orgId) {
            throw new HttpsError(
                "permission-denied",
                "User already belongs to an organisation."
            );
        }

        await userRef.set(
            {
                organisationId: orgId,
                modifiedAt: admin.firestore.FieldValue.serverTimestamp(),
            },
            { merge: true }
        );

        return { success: true };
    }
);
exports.inviteOrganisationUser = functions.https.onCall(
    async (data, context) => {
        const HttpsError = getHttpsError();

        const authContext = context.auth;
        if (!authContext) {
            throw new HttpsError("unauthenticated", "You must be signed in.");
        }

        data = data || {};
        const email = data.email;
        const organisationId = data.organisationId;
        const role = data.role;

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

        const callerUid = authContext.uid;
        const callerDoc = await db.collection("users").doc(callerUid).get();
        if (!callerDoc.exists) {
            throw new HttpsError(
                "permission-denied",
                "Caller user document does not exist."
            );
        }

        const caller = callerDoc.data() || {};
        const callerRole = caller.role;
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
    }
);
exports.handleNewUser = functions.auth.user().onCreate(async (user) => {
    const email = (user.email || "").toLowerCase();

    // New simple logic: everyone who signs up is an admin, no organisation yet.
    const role = "admin";
    const organisationId = null;

    const userDoc = {
        userId: user.uid,
        email,
        role,               // "admin"
        organisationId,     // null initially
        isDisabled: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        modifiedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    // Create /users/{uid} doc
    await db.collection("users").doc(user.uid).set(userDoc);

    // Optional: keep custom claims in sync
    await admin.auth().setCustomUserClaims(user.uid, {
        role,
        organisationId,
    });

    return;
});
exports.updateOrganisationUserRole = functions.https.onCall(
    async (data, context) => {
        const HttpsError = getHttpsError();

        const authContext = context.auth;
        if (!authContext) {
            throw new HttpsError("unauthenticated", "You must be signed in.");
        }

        data = data || {};
        const userId = data.userId;
        const organisationId = data.organisationId;
        const newRole = data.newRole;

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

        const callerUid = authContext.uid;
        const callerSnap = await db.collection("users").doc(callerUid).get();
        if (!callerSnap.exists) {
            throw new HttpsError(
                "permission-denied",
                "Caller user document does not exist."
            );
        }

        const caller = callerSnap.data() || {};
        const callerRole = caller.role;
        const callerOrgId = caller.organisationId || null;
        const callerIsSuperAdmin = callerRole === "superAdmin";

        if (!callerRole) {
            throw new HttpsError("permission-denied", "Caller has no role.");
        }

        // Only superAdmin OR admin of this org may change roles
        if (
            !callerIsSuperAdmin &&
            !(
                callerRole === "admin" &&
                callerOrgId != null &&
                callerOrgId === organisationId
            )
        ) {
            throw new HttpsError(
                "permission-denied",
                "Only admins of this organisation or super admins can change user roles."
            );
        }

        // Target user
        const targetRef = db.collection("users").doc(userId);
        const targetSnap = await targetRef.get();
        if (!targetSnap.exists) {
            throw new HttpsError("not-found", "Target user does not exist.");
        }
        const target = targetSnap.data() || {};

        if (target.role === "superAdmin") {
            throw new HttpsError(
                "permission-denied",
                "Cannot change role of a super admin with this function."
            );
        }

        const targetOrgId = target.organisationId || null;
        if (!callerIsSuperAdmin && targetOrgId !== organisationId) {
            throw new HttpsError(
                "permission-denied",
                "Admins may only update users that belong to their own organisation."
            );
        }

        await targetRef.set(
            {
                role: newRole,
                organisationId,
                modifiedAt: admin.firestore.FieldValue.serverTimestamp(),
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
                modifiedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        } else {
            await db.collection("roles").add({
                userId,
                organisationId,
                role: newRole,
                isDisabled: false,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                modifiedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        }

        await admin.auth().setCustomUserClaims(userId, {
            role: newRole,
            organisationId,
        });

        return { success: true };
    }
);
exports.signupAdmin = functions.https.onCall(async (data, context) => {
    const HttpsError = getHttpsError();

    data = data || {};
    const email = (data.email || "").toString().trim();
    const password = (data.password || "").toString();

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
            throw new HttpsError(
                "already-exists",
                "The account already exists for this email."
            );
        } catch (err) {
            if (err && err.code === "auth/user-not-found") {
                userRecord = await auth.createUser({
                    email,
                    password,
                    emailVerified: false,
                    disabled: false,
                });
            } else {
                if (err && err.code !== "auth/user-not-found") {
                    console.error("Auth error while checking/creating user:", err);
                    throw new HttpsError("internal", err.message || "Auth error");
                }
            }
        }

        // /users/{uid} document is created by handleNewUser (auth trigger)

        return {
            uid: userRecord.uid,
            email,
        };
    } catch (err) {
        if (err instanceof functions.https.HttpsError) {
            throw err;
        }

        console.error("Unexpected error in signupAdmin:", err);
        throw new HttpsError(
            "internal",
            "Failed to create account. Please try again."
        );
    }
});
 */