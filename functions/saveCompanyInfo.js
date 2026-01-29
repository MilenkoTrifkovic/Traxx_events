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

    // inside saveCompanyInfo, replace ONLY the "already exists" block with this:

    if (!existingAdminRole.empty) {
      const existingRole = existingAdminRole.docs[0].data();
      const organisationId = (existingRole.organisationId ?? "").toString().trim() || null;

      // ✅ Patch user doc (best-effort)
      try {
        await db.collection("users").doc(userId).set(
          {
            organisationId,
            role: "admin",
            modifiedAt: FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
      } catch (e) {
        logger.warn(`Could not patch users/${userId} on existing org`, e);
      }

      return {
        success: true,
        message: "Organisation already exists for this user",
        organisationId,
        role: "admin",
      };
    }



    // 3️⃣ ✅ Sanitize payload (Option A: ignore unexpected fields)
    const d = request.data || {};

    const sanitized = {
      name: d.name,
      phone: d.phone,
      website: d.website ?? null,
      timezone: d.timezone,
      currency: d.currency ?? "USD",
      logo: d.logo ?? null,
      assignedSalesPersonId:
        typeof d.assignedSalesPersonId === "string" && d.assignedSalesPersonId.trim()
          ? d.assignedSalesPersonId.trim()
          : null,
      address: d.address
        ? {
            street: d.address.street,
            city: d.address.city,
            state: d.address.state ?? null,
            zip: d.address.zip,
            country: d.address.country,
          }
        : null,
    };

    // 4️⃣ Validate incoming payload (now only the allowed shape is checked)
    validateCompanyInfo(sanitized);

    // 5️⃣ Generate UUIDs *without hyphens*
    const organisationId = uuidv4().replace(/-/g, "");
    const roleId = uuidv4().replace(/-/g, "");

    const now = FieldValue.serverTimestamp();

    const organisationData = {
      organisationId,
      name: sanitized.name,
      phone: String(sanitized.phone),
      website: sanitized.website || null,
      address: {
        street: sanitized.address.street,
        city: sanitized.address.city,

        // Only include state for USA
        ...(sanitized.address.country === "United States" &&
          sanitized.address.state && { state: sanitized.address.state }),

        zip: String(sanitized.address.zip),
        country: sanitized.address.country,
      },
      timezone: sanitized.timezone,
      currency: sanitized.currency || "USD",
      logo: sanitized.logo || null,
      assignedSalesPersonId: sanitized.assignedSalesPersonId || null,
      isDisabled: false,
      createdAt: now,
      modifiedAt: now,
    };

    const roleData = {
      roleId,
      userId,
      organisationId,
      role: "admin",
      isDisabled: false,
      createdAt: now,
      modifiedAt: now,
    };

    const result = await db.runTransaction(async (transaction) => {
      // 6️⃣ Use hyphen-less organisationId as Firestore document ID
      const organisationRef = db.collection("organisations").doc(organisationId);
      transaction.set(organisationRef, organisationData);

      // Use hyphen-less roleId as Firestore document ID
      const roleRef = db.collection("roles").doc(roleId);
      transaction.set(roleRef, roleData);

      // 7️⃣ Update users/{userId} with organisationId + role
      const userRef = db.collection("users").doc(userId);
      transaction.set(
        userRef,
        {
          organisationId,
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
      organisationDocumentId: result.organisationDocId,
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

