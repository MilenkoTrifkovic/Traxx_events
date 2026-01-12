// functions/submitDemographics.js
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "./admin.js";

// if (!getApps().length) initializeApp();
// const db = getFirestore();

/**
 * Submit demographic responses for either the main guest or a companion.
 * 
 * Request data:
 * - invitationId: string (required)
 * - token: string (required)
 * - answers: array (required)
 * - companionIndex: number | null (optional - null/undefined = main guest, 0+ = companion index)
 * 
 * Invitation document structure for tracking:
 * - used: boolean (main guest demographics submitted)
 * - responseId: string (main guest response document ID)
 * - companions: array of objects, each with:
 *   - guestId: string
 *   - name: string
 *   - email: string
 *   - demographicSubmitted: boolean
 *   - demographicResponseId: string
 *   - menuSubmitted: boolean
 *   - menuResponseId: string
 */
export const submitDemographics = onCall(async (request) => {
  try {
    const { invitationId, token, answers, companionIndex } = request.data || {};

    if (!invitationId || !token) {
      throw new HttpsError("invalid-argument", "invitationId and token are required");
    }
    if (!Array.isArray(answers)) {
      throw new HttpsError("invalid-argument", "answers must be an array");
    }

    // Determine if this is for main guest or companion
    const isMainGuest = companionIndex === null || companionIndex === undefined;
    const compIdx = isMainGuest ? null : parseInt(companionIndex, 10);

    if (!isMainGuest && (isNaN(compIdx) || compIdx < 0)) {
      throw new HttpsError("invalid-argument", "companionIndex must be a non-negative integer");
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

      // Get companions array (may be empty or not exist)
      const companions = Array.isArray(inv.companions) ? [...inv.companions] : [];

      // Validate companion index if submitting for a companion
      if (!isMainGuest) {
        if (compIdx >= companions.length) {
          throw new HttpsError("invalid-argument", `Companion index ${compIdx} is out of range. Only ${companions.length} companions exist.`);
        }
        
        // Check if this companion already submitted demographics
        if (companions[compIdx].demographicSubmitted === true) {
          return { 
            ok: true, 
            alreadySubmitted: true, 
            responseId: companions[compIdx].demographicResponseId || null,
            companionIndex: compIdx 
          };
        }
      } else {
        // Main guest - check if already submitted
        if (inv.used === true) {
          return { ok: true, alreadySubmitted: true, responseId: inv.responseId || null };
        }
      }

      // Determine guest info for the response
      let guestId, guestEmail, guestName;
      if (isMainGuest) {
        guestId = inv.guestId || null;
        guestEmail = inv.guestEmail || "";
        guestName = inv.guestName || "";
      } else {
        const companion = companions[compIdx];
        guestId = companion.guestId || null;
        guestEmail = companion.email || "";
        guestName = companion.name || "";
      }

      // Write response document
      const respRef = db.collection("demographicQuestionsResponses").doc();
      tx.set(respRef, {
        eventId: inv.eventId || "",
        organisationId: inv.organisationId || "",
        invitationId,
        guestId,
        guestEmail,
        guestName,
        isCompanion: !isMainGuest,
        companionIndex: compIdx,
        demographicQuestionSetId: inv.demographicQuestionSetId || null,
        answers,
        createdAt: FieldValue.serverTimestamp(),
      });

      // Update invitation document based on who submitted
      if (isMainGuest) {
        // Mark main guest demographics as submitted
        tx.update(invRef, {
          used: true,
          usedAt: FieldValue.serverTimestamp(),
          responseId: respRef.id,
        });
      } else {
        // Update the specific companion's status in the array
        companions[compIdx] = {
          ...companions[compIdx],
          demographicSubmitted: true,
          demographicResponseId: respRef.id,
          demographicSubmittedAt: new Date().toISOString(),
        };
        
        tx.update(invRef, {
          companions: companions,
        });
      }

      return { 
        ok: true, 
        alreadySubmitted: false, 
        responseId: respRef.id,
        companionIndex: compIdx,
      };
    });

    return result;
  } catch (err) {
    console.error("submitDemographics error:", err);
    throw err instanceof HttpsError
      ? err
      : new HttpsError("internal", err?.message ?? "Unknown error");
  }
});
