import { onCall, HttpsError } from "firebase-functions/v2/https";
import { Timestamp, FieldValue } from "firebase-admin/firestore";
import { db } from "./admin.js";


export const submitCompanionAttendance = onCall(async (request) => {
  try {
    const { invitationId, token, companionIndex, isAttending } = request.data || {};

    if (!invitationId || !token) {
      throw new HttpsError("invalid-argument", "invitationId and token are required");
    }
    const idx = parseInt(companionIndex, 10);
    if (isNaN(idx) || idx < 0) {
      throw new HttpsError("invalid-argument", "companionIndex must be non-negative");
    }
    if (typeof isAttending !== "boolean") {
      throw new HttpsError("invalid-argument", "isAttending must be boolean");
    }

    const invRef = db.collection("invitations").doc(invitationId);

    const result = await db.runTransaction(async (tx) => {
      const invSnap = await tx.get(invRef);
      if (!invSnap.exists) throw new HttpsError("not-found", "Invitation not found");

      const inv = invSnap.data() || {};
      if ((inv.token || "") !== token) throw new HttpsError("permission-denied", "Invalid token");

      const companions = Array.isArray(inv.companions) ? [...inv.companions] : [];
      if (idx >= companions.length) throw new HttpsError("invalid-argument", "companionIndex out of range");

      companions[idx] = {
        ...companions[idx],
        isAttending,
        attendingSubmitted: true,
        attendingSubmittedAt: new Date().toISOString(),
      };

      tx.update(invRef, {
        companions,
        modifiedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });

      return { ok: true, companionIndex: idx, isAttending };
    });

    return result;
  } catch (err) {
    console.error("submitCompanionAttendance error:", err);
    throw err instanceof HttpsError ? err : new HttpsError("internal", err?.message ?? "Unknown error");
  }
});

