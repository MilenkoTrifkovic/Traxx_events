import { onCall, HttpsError } from "firebase-functions/v2/https";
import logger from "firebase-functions/logger";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { v4 as uuidv4 } from "uuid";
import { validateCompanyInfo } from "./validators/organisationValidator.js";

const db = getFirestore();

// Save company info function
/* export const saveCompanyInfo = onCall(async (request) => {
    try {
        // Check if user is authenticated
        if (!request.auth || !request.auth.uid) {
            throw new HttpsError("unauthenticated", "You must be signed in.");
        }

        const userId = request.auth.uid;

        // Check if user already has an admin role (i.e., already created an organisation)
        const existingAdminRole = await db.collection("roles")
            .where("userId", "==", userId)
            .where("role", "==", "admin")
            .where("isDisabled", "==", false)
            .limit(1)
            .get();

        if (!existingAdminRole.empty) {
            const existingRole = existingAdminRole.docs[0].data();
            logger.info(`User ${userId} already has an admin role for organisation ${existingRole.organisationId}`);

            throw new HttpsError(
                "already-exists",
                "You have already created an organisation. Each user can only create one organisation."
            );
        }

        // Validate the company info data
        validateCompanyInfo(request.data);

        // Generate UUIDs for organisation and role
        const organisationId = uuidv4();
        const roleId = uuidv4();

        // Prepare the organisation document data
        const organisationData = {
            organisationId: organisationId,
            name: request.data.name,
            phone: request.data.phone.toString(), // Convert to string in case it's a number
            website: request.data.website || null,
            address: {
                street: request.data.address.street,
                city: request.data.address.city,
                state: request.data.address.state,
                zip: request.data.address.zip.toString(), // Convert to string in case it's a number
                country: request.data.address.country
            },
            timezone: request.data.timezone,
            logo: request.data.logo || null,
            isDisabled: false,
            createdAt: FieldValue.serverTimestamp(),
            modifiedAt: FieldValue.serverTimestamp()
        };

        // Prepare the role document data
        const roleData = {
            roleId: roleId,
            userId: userId,
            organisationId: organisationId,
            role: "admin",
            isDisabled: false,
            createdAt: FieldValue.serverTimestamp(),
            modifiedAt: FieldValue.serverTimestamp()
        };

        // Use Firestore transaction to ensure both documents are created or both fail
        const result = await db.runTransaction(async (transaction) => {
            // Create organisation document
            const organisationRef = db.collection("organisations").doc();
            transaction.set(organisationRef, organisationData);

            // Create role document
            const roleRef = db.collection("roles").doc();
            transaction.set(roleRef, roleData);

            return {
                organisationDocId: organisationRef.id,
                roleDocId: roleRef.id,
                organisationId: organisationId,
                roleId: roleId
            };
        });

        logger.info(`Company info and role saved successfully. Org: ${result.organisationDocId}, Role: ${result.roleDocId}, OrgUUID: ${organisationId}, RoleUUID: ${roleId}`);

        return {
            success: true,
            message: "Company information and admin role created successfully",
            roleDocumentId: result.roleDocId,
            organisationId: organisationId,
            roleId: roleId
        };

    } catch (error) {
        logger.error("Error saving company info:", error);

        // If it's already an HttpsError (from validation), re-throw it
        if (error.code && error.message) {
            throw error;
        }

        // Generic error for unexpected issues
        throw new HttpsError(
            "internal",
            "An error occurred while saving the company information."
        );
    }
}); */



// 👑 your super admin bootstrap list


// ------------------------------
// SAVE COMPANY INFO
// ------------------------------
export const saveCompanyInfo = onCall(async (request) => {
    try {
        if (!request.auth || !request.auth.uid) {
            throw new HttpsError("unauthenticated", "You must be signed in.");
        }

        const userId = request.auth.uid;

        // Load caller user doc
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

        // Normal users: can create at most one org (and only if they don't already belong to one)
        if (!isSuperAdmin && currentOrgId) {
            throw new HttpsError(
                "permission-denied",
                "You already belong to an organisation."
            );
        }

        // Check if this user already has an admin role somewhere
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

        // Validate the company info data (your existing helper)
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

        // Create organisation + initial admin role in a transaction
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

        // Update user document with new role and org
        await userRef.set(
            {
                role: "admin",
                organisationId,
                modifiedAt: FieldValue.serverTimestamp(),
            },
            { merge: true }
        );

        // Update custom claims
        await admin.auth().setCustomUserClaims(userId, {
            role: "admin",
            organisationId,
        });

        console.log(
            `Company info and role saved. OrgUUID: ${organisationId}, RoleUUID: ${roleId}`
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