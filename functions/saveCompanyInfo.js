// functions/saveCompanyInfo.js
import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { v4 as uuidv4 } from "uuid";
import { validateCompanyInfo } from "./validators/organisationValidator.js";

const db = getFirestore();

export const saveCompanyInfo = onCall(async (request) => {
  try {
    if (!request.auth || !request.auth.uid) {
      throw new HttpsError("unauthenticated", "You must be signed in.");
    }

    const userId = request.auth.uid;

    // Check if user already has an active admin role
    const existingAdminRole = await db
      .collection("roles")
      .where("userId", "==", userId)
      .where("role", "==", "admin")
      .where("isDisabled", "==", false)
      .limit(1)
      .get();

    if (!existingAdminRole.empty) {
      const existingRole = existingAdminRole.docs[0].data();
      logger.info(
        `User ${userId} already has an admin role for organisation ${existingRole.organisationId}`
      );

      throw new HttpsError(
        "already-exists",
        "You have already created an organisation. Each user can only create one organisation."
      );
    }

    // Validate request
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

    const result = await db.runTransaction(async (transaction) => {
      // organisations/{autoId}
      const organisationRef = db.collection("organisations").doc();
      transaction.set(organisationRef, organisationData);

      // roles/{autoId}
      const roleRef = db.collection("roles").doc();
      transaction.set(roleRef, roleData);

      // 🔥 NEW: update users/{userId} with organisationId + role
      const userRef = db.collection("users").doc(userId);
      transaction.set(
        userRef,
        {
          organisationId: organisationId, // 👈 this is what your AuthController reads
          role: "admin",
          modifiedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      return {
        organisationDocId: organisationRef.id,
        roleDocId: roleRef.id,
        organisationId,
        roleId,
      };
    });

    logger.info(
      `Company info + role saved. OrgDoc=${result.organisationDocId}, RoleDoc=${result.roleDocId}, OrgUUID=${organisationId}, RoleUUID=${roleId}`
    );

    return {
      success: true,
      message: "Company information and admin role created successfully",
      roleDocumentId: result.roleDocId,
      organisationId,
      roleId,
      role: "admin",
    };
  } catch (error) {
    logger.error("Error saving company info:", error);

    if (error instanceof HttpsError) {
      throw error;
    }

    throw new HttpsError(
      "internal",
      "An error occurred while saving the company information."
    );
  }
});



