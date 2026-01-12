// functions/saveCompanyInfo.js
import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { v4 as uuidv4 } from "uuid";
import { validateCompanyInfo } from "./validators/organisationValidator.js";

const db = getFirestore();

export const saveCompanyInfo = onCall(async (request) => {
  try {
    // 1️⃣ Auth check
    if (!request.auth || !request.auth.uid) {
      throw new HttpsError("unauthenticated", "You must be signed in.");
    }

    const userId = request.auth.uid;

    // 2️⃣ Enforce: one organisation per user (admin role)
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

    // 3️⃣ Validate incoming payload
    validateCompanyInfo(request.data);

    // 4️⃣ Generate UUIDs *without hyphens*
    // e.g. "8a21b09dec5f4734865cd7d194f0af6f"
    const organisationId = uuidv4().replace(/-/g, "");
    const roleId = uuidv4().replace(/-/g, "");

    const now = FieldValue.serverTimestamp();

    const organisationData = {
      organisationId, // no hyphens
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
      currency: request.data.currency || "USD", // Default to USD if not provided
      logo: request.data.logo || null,
      isDisabled: false,
      createdAt: now,
      modifiedAt: now,
    };

    const roleData = {
      roleId,        // no hyphens
      userId,
      organisationId,
      role: "admin",
      isDisabled: false,
      createdAt: now,
      modifiedAt: now,
    };

    const result = await db.runTransaction(async (transaction) => {
      // 5️⃣ Use hyphen-less organisationId as Firestore document ID
      const organisationRef = db
        .collection("organisations")
        .doc(organisationId);
      transaction.set(organisationRef, organisationData);

      // Use hyphen-less roleId as Firestore document ID
      const roleRef = db.collection("roles").doc(roleId);
      transaction.set(roleRef, roleData);

      // 6️⃣ Update users/{userId} with organisationId + role
      const userRef = db.collection("users").doc(userId);
      transaction.set(
        userRef,
        {
          organisationId, // 👈 hyphen-less UUID string
          role: "admin",
          modifiedAt: now,
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
      organisationDocumentId: result.organisationDocId, // == organisationId (no hyphens)
      roleDocumentId: result.roleDocId,                 // == roleId (no hyphens)
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
