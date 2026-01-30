import { onCall, HttpsError } from "firebase-functions/v2/https";
import { Timestamp, FieldValue } from "firebase-admin/firestore";
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

    const name = (companion.name ?? "").toString().trim();
    const email = (companion.email ?? "").toString().trim();
    const emailLower = email.toLowerCase();

    if (!name) throw new HttpsError("invalid-argument", "Companion name is required");
    if (!email) throw new HttpsError("invalid-argument", "Companion email is required");

    // ✅ attendance comes from AttendChips
    if (typeof companion.isAttending !== "boolean") {
      throw new HttpsError("invalid-argument", "isAttending must be boolean");
    }
    const isAttending = companion.isAttending;

    const invRef = db.collection("invitations").doc(invitationId);

    const result = await db.runTransaction(async (tx) => {
      const invSnap = await tx.get(invRef);
      if (!invSnap.exists) throw new HttpsError("not-found", "Invitation not found");

      const inv = invSnap.data() || {};
      if ((inv.token || "") !== token) throw new HttpsError("permission-denied", "Invalid token");

      const expiresAt = inv.expiresAt?.toDate ? inv.expiresAt.toDate() : null;
      if (expiresAt && expiresAt.getTime() < Date.now()) {
        throw new HttpsError("failed-precondition", "Invitation expired");
      }

      const eventId = (inv.eventId || "").toString().trim();
      const organisationId = (inv.organisationId || "").toString().trim();
      const mainGuestId = (inv.guestId || "").toString().trim();

      if (!eventId) throw new HttpsError("failed-precondition", "Invitation missing eventId");
      if (!mainGuestId) throw new HttpsError("failed-precondition", "Invitation missing guestId");

      const companionsTarget = Number(inv.companionsCount || 0);
      const existing = Array.isArray(inv.companions) ? [...inv.companions] : [];

      // ✅ enforce max companions
      if (companionsTarget <= 0) throw new HttpsError("failed-precondition", "companionsCount is 0");
      if (existing.length >= companionsTarget) {
        throw new HttpsError("failed-precondition", "All companions already added");
      }

      // ✅ duplicates among companions are NOT allowed
      const already = existing.some((c) => {
        const cEmail = (c?.guestEmailLower ?? c?.guestEmail ?? c?.email ?? "")
          .toString().trim().toLowerCase();
        return cEmail && cEmail === emailLower;
      });
      if (already) throw new HttpsError("already-exists", "A companion with this email already exists");

      const companionIndex = existing.length;
      const now = Timestamp.now();

      // create companion guest doc
      const guestRef = db.collection("guests").doc();
      tx.set(guestRef, {
        guestId: guestRef.id,
        name,
        email,
        guestEmailLower: emailLower,
        eventId,
        organisationId: organisationId || null,
        maxGuestInvite: 0,
        isDisabled: false,
        isInvited: false,
        isCompanion: true,

        parentInvitationId: invitationId,
        parentInvitationToken: token,
        companionIndex,

        // ✅ attendance is confirmed here
        isAttending,
        attendingSubmitted: true,
        attendingSubmittedAt: new Date().toISOString(),

        address: companion.address ?? null,
        city: companion.city ?? null,
        state: companion.state ?? null,
        country: companion.country ?? null,
        gender: companion.gender ?? null,

        createdAt: now,
        modifiedAt: now,
      });

      const newCompanions = [
        ...existing,
        {
          guestId: guestRef.id,
          guestName: name,
          guestEmail: email,
          guestEmailLower: emailLower,
          companionIndex,

          // ✅ attendance confirmed
          isAttending,
          attendingSubmitted: true,
          attendingSubmittedAt: new Date().toISOString(),

          createdAt: now,
        },
      ];

      const savedCount = newCompanions.length;
      const remaining = Math.max(0, companionsTarget - savedCount);

      tx.update(invRef, {
        companions: newCompanions,
        savedCompanionsCount: savedCount,
        remainingCompanionsToCreate: remaining,
        modifiedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });

      return { guestId: guestRef.id, companionIndex, savedCount, remaining };
    });

    return { ok: true, ...result };
  } catch (err) {
    console.error("addCompanionToInvitation error:", err);
    throw err instanceof HttpsError ? err : new HttpsError("internal", err?.message ?? "Unknown error");
  }
});
