import { onCall, HttpsError } from "firebase-functions/v2/https";
import { initializeApp, getApps } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";


if (!getApps().length) initializeApp();
const db = getFirestore();

export const submitMenuSelection = onCall(async (request) => {
  try {
    const { invitationId, token, selectedMenuItemIds } = request.data || {};

    if (!invitationId || !token) {
      throw new HttpsError("invalid-argument", "invitationId and token are required");
    }
    if (!Array.isArray(selectedMenuItemIds)) {
      throw new HttpsError("invalid-argument", "selectedMenuItemIds must be an array");
    }

    const invRef = db.collection("invitations").doc(invitationId);
    const respRef = db.collection("menuSelectedItemsResponses").doc(invitationId); // unique per invitation

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

      // ✅ Must complete demographics first
      if (inv.used !== true) {
        throw new HttpsError("failed-precondition", "Demographic questions not submitted yet");
      }

      // already submitted menu?
      const existing = await tx.get(respRef);
      if (existing.exists) {
        return { ok: true, alreadySubmitted: true };
      }

      // normalize ids
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

      tx.set(respRef, {
        eventId: inv.eventId || "",
        organisationId: inv.organisationId || "",
        invitationId,
        guestId: inv.guestId || null,
        guestEmail: inv.guestEmail || "",
        selectedMenuItemIds: cleaned,
        createdAt: FieldValue.serverTimestamp(),
      });

      tx.update(invRef, {
        menuSelectionSubmitted: true,
        menuSelectionSubmittedAt: FieldValue.serverTimestamp(),
      });

      return { ok: true, alreadySubmitted: false };
    });

    return result;
  } catch (err) {
    console.error("submitMenuSelection error:", err);
    throw err instanceof HttpsError
      ? err
      : new HttpsError("internal", err?.message ?? "Unknown error");
  }
});
