import { onCall, HttpsError } from "firebase-functions/v2/https";
import logger from "firebase-functions/logger";
import { getFirestore } from "firebase-admin/firestore";

const db = getFirestore();

// Check organisation info function
export const checkOrganisationInfo = onCall(async (request) => {
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

        const hasOrganisation = !existingAdminRole.empty;

        if (hasOrganisation) {
            const existingRole = existingAdminRole.docs[0].data();
            logger.info(`User ${userId} has existing admin role for organisation ${existingRole.organisationId}`);

            return {
                hasOrganisation: true,
                organisationId: existingRole.organisationId,
                role: existingRole.role
            };
        } else {
            logger.info(`User ${userId} does not have an existing organisation`);

            return {
                hasOrganisation: false,
                organisationId: null,
                role: null
            };
        }

    } catch (error) {
        logger.error("Error checking organisation info:", error);

        // If it's already an HttpsError (from validation), re-throw it
        if (error.code && error.message) {
            throw error;
        }

        // Generic error for unexpected issues
        throw new HttpsError(
            "internal",
            "An error occurred while checking the organisation information."
        );
    }
});