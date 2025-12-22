// functions/submitDemographics.js
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "./admin.js";

// if (!getApps().length) initializeApp();
// const db = getFirestore();

export const submitDemographics = onCall(async (request) => {
  try {
    const { invitationId, token, answers } = request.data || {};

    if (!invitationId || !token) {
      throw new HttpsError("invalid-argument", "invitationId and token are required");
    }
    if (!Array.isArray(answers)) {
      throw new HttpsError("invalid-argument", "answers must be an array");
    }

    const invRef = db.collection("invitations").doc(invitationId);

    const result = await db.runTransaction(async (tx) => {
      const invSnap = await tx.get(invRef);
      if (!invSnap.exists) {
        throw new HttpsError("not-found", "Invitation not found");
      }

      const inv = invSnap.data();

      // token check
      if ((inv.token || "") !== token) {
        throw new HttpsError("permission-denied", "Invalid token");
      }

      // expiry check
      const expiresAt = inv.expiresAt?.toDate ? inv.expiresAt.toDate() : null;
      if (expiresAt && expiresAt.getTime() < Date.now()) {
        throw new HttpsError("failed-precondition", "Invitation expired");
      }

      // already used?
      if (inv.used === true) {
        return { ok: true, alreadySubmitted: true };
      }

      // Write response
      const respRef = db.collection("demographicQuestionsResponses").doc();
      tx.set(respRef, {
        eventId: inv.eventId || "",
        organisationId: inv.organisationId || "",
        invitationId,
        guestId: inv.guestId || null,
        guestEmail: inv.guestEmail || "",
        demographicQuestionSetId: inv.demographicQuestionSetId || null,
        answers,
        createdAt: FieldValue.serverTimestamp(),
      });

      // Mark invitation used (prevents second submit)
      tx.update(invRef, {
        used: true,
        usedAt: FieldValue.serverTimestamp(),
        responseId: respRef.id,
      });

      return { ok: true, alreadySubmitted: false, responseId: respRef.id };
    });

    return result;
  } catch (err) {
    console.error("submitDemographics error:", err);
    throw err instanceof HttpsError
      ? err
      : new HttpsError("internal", err?.message ?? "Unknown error");
  }
});
