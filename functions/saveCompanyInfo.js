import { onCall, HttpsError } from "firebase-functions/v2/https";
import logger from "firebase-functions/logger";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { v4 as uuidv4 } from "uuid";
import { validateCompanyInfo } from "./validators/organisationValidator.js";

const db = getFirestore();

// Save company info function
export const saveCompanyInfo = onCall(async (request) => {
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
});