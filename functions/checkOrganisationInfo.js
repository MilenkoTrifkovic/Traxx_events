import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { db } from "./admin.js";

export const checkOrganisationInfo = onCall(async (request) => {
  try {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "You must be signed in.");
    }

    const userId = request.auth.uid;
    logger.info(`Checking organisation info for user: ${userId}`);

    let roleSnap = await db
      .collection("roles")
      .where("userId", "==", userId)
      .where("role", "==", "admin")
      .where("isDisabled", "==", false)
      .limit(1)
      .get();

    // ─────────────────────────────────────────────
    // 2) Fallback to HOST role
    // ─────────────────────────────────────────────
    if (roleSnap.empty) {
      roleSnap = await db
        .collection("roles")
        .where("userId", "==", userId)
        .where("role", "==", "host")
        .where("isDisabled", "==", false)
        .limit(1)
        .get();
    }

    if (roleSnap.empty) {
      logger.info(`User ${userId} has no active organisation role`);

      return {
        hasOrganisation: false,
        organisationId: null,
        role: null,
      };
    }

    const roleData = roleSnap.docs[0].data();

    const organisationId =
      (roleData.organisationId ?? "").toString().trim() || null;
    const role = (roleData.role ?? "admin").toString();

    logger.info(
      `User ${userId} has active role=${role} for org=${organisationId}`
    );
    
    if (organisationId) {
      await db
        .collection("users")
        .doc(userId)
        .set(
          {
            organisationId,
            role,
            modifiedAt: FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
    }

    return {
      hasOrganisation: true,
      organisationId,
      role,
    };
  } catch (error) {
    logger.error("Error checking organisation info:", error);

    if (error instanceof HttpsError) {
      throw error;
    }

    throw new HttpsError(
      "internal",
      "An error occurred while checking the organisation information."
    );
  }
});

