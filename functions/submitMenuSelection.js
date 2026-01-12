import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "./admin.js";
import {
  normalizeIds,
  collectGroupItemIds,
  getEventDataByEventIdTx,
  sanitizeMenuItemGroups,
} from "./menuSelectionHelpers.js";

export const submitMenuSelection = onCall(async (request) => {
  try {
    const { invitationId, token, selectedMenuItemIds, companionIndex } = request.data || {};

    if (!invitationId || !token) {
      throw new HttpsError("invalid-argument", "invitationId and token are required");
    }
    if (!Array.isArray(selectedMenuItemIds)) {
      throw new HttpsError("invalid-argument", "selectedMenuItemIds must be an array");
    }

    const isMainGuest = companionIndex === null || companionIndex === undefined;
    const compIdx = isMainGuest ? null : parseInt(companionIndex, 10);
    if (!isMainGuest && (isNaN(compIdx) || compIdx < 0)) {
      throw new HttpsError("invalid-argument", "companionIndex must be a non-negative integer");
    }

    const invRef = db.collection("invitations").doc(invitationId);
    const respDocId = isMainGuest ? invitationId : `${invitationId}_companion_${compIdx}`;
    const respRef = db.collection("menuSelectedItemsResponses").doc(respDocId);

    const result = await db.runTransaction(async (tx) => {
      const invSnap = await tx.get(invRef);
      if (!invSnap.exists) throw new HttpsError("not-found", "Invitation not found");
      const inv = invSnap.data() || {};

      if ((inv.token || "") !== token) throw new HttpsError("permission-denied", "Invalid token");

      const expiresAt = inv.expiresAt?.toDate ? inv.expiresAt.toDate() : null;
      if (expiresAt && expiresAt.getTime() < Date.now()) throw new HttpsError("failed-precondition", "Invitation expired");

      const companions = Array.isArray(inv.companions) ? [...inv.companions] : [];
      if (!isMainGuest && compIdx >= companions.length) {
        throw new HttpsError("invalid-argument", `Companion index ${compIdx} is out of range.`);
      }

      // prerequisites + already submitted
      if (isMainGuest) {
        if (inv.used !== true) throw new HttpsError("failed-precondition", "Demographic questions not submitted yet");
        if (inv.menuSelectionSubmitted === true) return { ok: true, alreadySubmitted: true, companionIndex: null };
      } else {
        const companion = companions[compIdx];
        if (companion.demographicSubmitted !== true) {
          throw new HttpsError("failed-precondition", `Companion ${compIdx} has not submitted demographics yet`);
        }
        if (companion.menuSubmitted === true) return { ok: true, alreadySubmitted: true, companionIndex: compIdx };
      }

      // extra safety
      const existing = await tx.get(respRef);
      if (existing.exists) return { ok: true, alreadySubmitted: true, companionIndex: compIdx };

      const cleaned = normalizeIds(selectedMenuItemIds);
      const cleanedSet = new Set(cleaned);

      const eventId = (inv.eventId || "").toString();
      if (!eventId) throw new HttpsError("failed-precondition", "Invitation missing eventId");

      const eventObj = await getEventDataByEventIdTx(tx, eventId);
      if (!eventObj) throw new HttpsError("not-found", "Event not found");
      const eventData = eventObj.data || {};

      const rawGroups = Array.isArray(eventData.menuItemGroups) ? eventData.menuItemGroups : [];
      const ungroupedAllowed = normalizeIds(eventData.selectedMenuItemIds);
      const groupedAllowed = collectGroupItemIds(rawGroups);
      const allowedIds = normalizeIds([...ungroupedAllowed, ...groupedAllowed]);
      const allowedSet = new Set(allowedIds);

      // subset validation
      for (const id of cleaned) {
        if (!allowedSet.has(id)) throw new HttpsError("invalid-argument", "Invalid menu item selected");
      }

      // enforce group maxPick
      const { groups: safeGroups } = sanitizeMenuItemGroups(rawGroups, allowedSet, null);
      const groupSelections = {};

      for (const g of safeGroups) {
        let count = 0;
        let picked = null;

        for (const id of g.itemIds) {
          if (cleanedSet.has(id)) {
            count += 1;
            if (picked == null) picked = id;
            if (count > g.maxPick) {
              throw new HttpsError("invalid-argument", `You can select only ${g.maxPick} item(s) from "${g.name}".`);
            }
          }
        }

        groupSelections[g.groupId] = picked;
      }

      // guest identity
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
        groupSelections,
        createdAt: FieldValue.serverTimestamp(),
      });

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
        tx.update(invRef, { companions });
      }

      return { ok: true, alreadySubmitted: false, companionIndex: compIdx };
    });

    return result;
  } catch (err) {
    console.error("submitMenuSelection error:", err);
    throw err instanceof HttpsError ? err : new HttpsError("internal", err?.message ?? "Unknown error");
  }
});
