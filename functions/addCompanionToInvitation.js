import { onCall, HttpsError } from "firebase-functions/v2/https";
import { Timestamp } from "firebase-admin/firestore";
import { db } from "./admin.js";

export const addCompanionToInvitation = onCall(async (request) => {
  try {
    const { invitationId, token, companion } = request.data || {};

    if (!invitationId || !token) {
      throw new HttpsError("invalid-argument", "invitationId and token are required");
    }
    if (!companion || typeof companion !== "object") {
      throw new HttpsError("invalid-argument", "companion is required");
    }

    function makeBatchId() {
      return String(Math.floor(100000 + Math.random() * 900000)); // 6 digits
    }


    const name = (companion.name ?? "").toString().trim();
    const email = (companion.email ?? "").toString().trim();
    if (!name || !email) {
      throw new HttpsError("invalid-argument", "Companion name and email are required");
    }
    const emailLower = email.toLowerCase();

    const invRef = db.collection("invitations").doc(invitationId);

    const result = await db.runTransaction(async (tx) => {
      const invSnap = await tx.get(invRef);
      if (!invSnap.exists) throw new HttpsError("not-found", "Invitation not found");

      const inv = invSnap.data() || {};
      if ((inv.token || "") !== token) {
        throw new HttpsError("permission-denied", "Invalid token");
      }

      const expiresAt = inv.expiresAt?.toDate ? inv.expiresAt.toDate() : null;
      if (expiresAt && expiresAt.getTime() < Date.now()) {
        throw new HttpsError("failed-precondition", "Invitation expired");
      }

      const eventId = (inv.eventId || "").toString().trim();
      const organisationId = (inv.organisationId || "").toString().trim();
      const mainGuestId = (inv.guestId || "").toString().trim();

      if (!eventId) throw new HttpsError("failed-precondition", "Invitation missing eventId");
      if (!mainGuestId) throw new HttpsError("failed-precondition", "Invitation missing guestId");

      const companionsCount = Number(inv.companionsCount || 0);
      if (companionsCount <= 0) {
        throw new HttpsError("failed-precondition", "companionsCount is 0");
      }

      const existing = Array.isArray(inv.companions) ? inv.companions : [];
      const already = existing.some((c) => {
        const cEmail = (c?.guestEmailLower ?? c?.guestEmail ?? "").toString().trim().toLowerCase();
        return cEmail === emailLower;
      });
      if (already) {
        throw new HttpsError("already-exists", "A companion with this email already exists");
      }

      // ✅ groupId: keep it stable and easy (use main guest id)
      const groupId = mainGuestId;

      // Ensure main guest has groupId (helps your existing "getGroupIdForMainGuest")
      const mainGuestRef = db.collection("guests").doc(mainGuestId);
      tx.set(mainGuestRef, { groupId }, { merge: true });

      // Create companion guest doc
      const guestRef = db.collection("guests").doc();
      const now = Timestamp.now();

      const companionBatchId = makeBatchId();

      tx.set(guestRef, {
        guestId: guestRef.id,          // ✅ add this too (helps your models)
        batchId: companionBatchId,  
        name,
        email,
        guestEmailLower: emailLower,
        eventId,
        organisationId: organisationId || null,
        maxGuestInvite: 0,
        isDisabled: false,
        isInvited: false,
        isCompanion: true,
        groupId,
        invitationId,
        createdAt: now,
        modifiedAt: now,

        address: companion.address ?? null,
        city: companion.city ?? null,
        state: companion.state ?? null,
        country: companion.country ?? null,
        gender: companion.gender ?? null,
      });

      const newCompanions = [
        ...existing,
        {
          guestId: guestRef.id,
          guestName: name,
          guestEmail: email,
          guestEmailLower: emailLower,
          groupId,
          createdAt: now,
        },
      ];

      const savedCount = newCompanions.length;
      const remaining = Math.max(0, companionsCount - savedCount);

      tx.update(invRef, {
        companions: newCompanions,
        savedCompanionsCount: savedCount,
        remainingCompanionsToCreate: remaining,
        modifiedAt: now,
        updatedAt: now,
      });

      return {
        guestId: guestRef.id,
        batchId: companionBatchId, 
        groupId,
        savedCompanionsCount: savedCount,
        remainingCompanionsToCreate: remaining,
      };
    });

    return { ok: true, ...result };
  } catch (err) {
    console.error("addCompanionToInvitation error:", err);
    throw err instanceof HttpsError
      ? err
      : new HttpsError("internal", err?.message ?? "Unknown error");
  }
});
