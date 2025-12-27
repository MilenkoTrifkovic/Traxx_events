// functions/submitMenuSelection.js
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "./admin.js";


// if (!getApps().length) initializeApp();
// const db = getFirestore();

/**
 * Submit menu selection for either the main guest or a companion.
 * 
 * Request data:
 * - invitationId: string (required)
 * - token: string (required)
 * - selectedMenuItemIds: array of strings (required)
 * - companionIndex: number | null (optional - null/undefined = main guest, 0+ = companion index)
 * 
 * Requires demographics to be submitted first (for the same person).
 */
export const submitMenuSelection = onCall(async (request) => {
  try {
    const { invitationId, token, selectedMenuItemIds, companionIndex } = request.data || {};

    if (!invitationId || !token) {
      throw new HttpsError("invalid-argument", "invitationId and token are required");
    }
    if (!Array.isArray(selectedMenuItemIds)) {
      throw new HttpsError("invalid-argument", "selectedMenuItemIds must be an array");
    }

    // Determine if this is for main guest or companion
    const isMainGuest = companionIndex === null || companionIndex === undefined;
    const compIdx = isMainGuest ? null : parseInt(companionIndex, 10);

    if (!isMainGuest && (isNaN(compIdx) || compIdx < 0)) {
      throw new HttpsError("invalid-argument", "companionIndex must be a non-negative integer");
    }

    const invRef = db.collection("invitations").doc(invitationId);
    
    // Response document ID: unique per invitation + person
    const respDocId = isMainGuest 
      ? invitationId 
      : `${invitationId}_companion_${compIdx}`;
    const respRef = db.collection("menuSelectedItemsResponses").doc(respDocId);

    const result = await db.runTransaction(async (tx) => {
      const invSnap = await tx.get(invRef);
      if (!invSnap.exists) throw new HttpsError("not-found", "Invitation not found");
      const inv = invSnap.data();

      if ((inv.token || "") !== token) {
        throw new HttpsError("permission-denied", "Invalid token");
      }

      const expiresAt = inv.expiresAt?.toDate ? inv.expiresAt.toDate() : null;
      if (expiresAt && expiresAt.getTime() < Date.now()) {
        throw new HttpsError("failed-precondition", "Invitation expired");
      }

      // Get companions array
      const companions = Array.isArray(inv.companions) ? [...inv.companions] : [];

      // Validate companion index
      if (!isMainGuest && compIdx >= companions.length) {
        throw new HttpsError("invalid-argument", `Companion index ${compIdx} is out of range.`);
      }

      // Check if demographics were submitted first
      if (isMainGuest) {
        if (inv.used !== true) {
          throw new HttpsError("failed-precondition", "Demographic questions not submitted yet");
        }
        // Check if already submitted menu
        if (inv.menuSelectionSubmitted === true) {
          return { ok: true, alreadySubmitted: true, companionIndex: null };
        }
      } else {
        const companion = companions[compIdx];
        if (companion.demographicSubmitted !== true) {
          throw new HttpsError("failed-precondition", `Companion ${compIdx} has not submitted demographics yet`);
        }
        // Check if companion already submitted menu
        if (companion.menuSubmitted === true) {
          return { ok: true, alreadySubmitted: true, companionIndex: compIdx };
        }
      }

      // Check if response doc already exists (extra safety)
      const existing = await tx.get(respRef);
      if (existing.exists) {
        return { ok: true, alreadySubmitted: true, companionIndex: compIdx };
      }

      // Normalize selected IDs
      const cleaned = [];
      const seen = new Set();
      for (const x of selectedMenuItemIds) {
        const id = (x || "").toString().trim();
        if (!id) continue;
        if (!seen.has(id)) {
          seen.add(id);
          cleaned.push(id);
        }
      }

      // Get guest info
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

      // Write menu response
      tx.set(respRef, {
        eventId: inv.eventId || "",
        organisationId: inv.organisationId || "",
        invitationId,
        guestId,
        guestEmail,
        guestName,
        isCompanion: !isMainGuest,
        companionIndex: compIdx,
        selectedMenuItemIds: cleaned,
        createdAt: FieldValue.serverTimestamp(),
      });

      // Update invitation
      if (isMainGuest) {
        tx.update(invRef, {
          menuSelectionSubmitted: true,
          menuSelectionSubmittedAt: FieldValue.serverTimestamp(),
        });
      } else {
        companions[compIdx] = {
          ...companions[compIdx],
          menuSubmitted: true,
          menuResponseId: respRef.id,
          menuSubmittedAt: new Date().toISOString(),
        };
        
        tx.update(invRef, {
          companions: companions,
        });
      }

      return { ok: true, alreadySubmitted: false, companionIndex: compIdx };
    });

    return result;
  } catch (err) {
    console.error("submitMenuSelection error:", err);
    throw err instanceof HttpsError
      ? err
      : new HttpsError("internal", err?.message ?? "Unknown error");
  }
});
