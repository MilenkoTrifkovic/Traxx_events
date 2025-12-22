// functions/checkOrganisationInfo.js
import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { db } from "./admin.js";

// const db = getFirestore();

/**
 * Callable function to check if the current user already has an organisation.
 * Returns:
 *  {
 *    hasOrganisation: boolean,
 *    organisationId: string | null,
 *    role: string | null
 *  }
 */
export const checkOrganisationInfo = onCall(async (request) => {
  try {
    // Must be authenticated
    if (!request.auth || !request.auth.uid) {
      throw new HttpsError("unauthenticated", "You must be signed in.");
    }

    const userId = request.auth.uid;
    logger.info(`Checking organisation info for user: ${userId}`);

    // Look up active admin role
    const existingAdminRole = await db
      .collection("roles")
      .where("userId", "==", userId)
      .where("role", "==", "admin")
      .where("isDisabled", "==", false)
      .limit(1)
      .get();

    const hasOrganisation = !existingAdminRole.empty;

    if (hasOrganisation) {
      const existingRole = existingAdminRole.docs[0].data();
      logger.info(
        `User ${userId} has existing admin role for organisation ${existingRole.organisationId}`
      );

      return {
        hasOrganisation: true,
        organisationId: existingRole.organisationId ?? null,
        role: existingRole.role ?? "admin",
      };
    } else {
      logger.info(`User ${userId} does NOT have an existing organisation`);

      return {
        hasOrganisation: false,
        organisationId: null,
        role: null,
      };
    }
  } catch (error) {
    logger.error("Error checking organisation info:", error);

    // Only rethrow if it's really an HttpsError
    if (error instanceof HttpsError) {
      throw error;
    }

    throw new HttpsError(
      "internal",
      "An error occurred while checking the organisation information."
    );
  }
});
