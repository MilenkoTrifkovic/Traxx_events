import { onCall, HttpsError } from "firebase-functions/v2/https";
import {
  normalizeIds,
  collectGroupItemIds,
  getEventDataByEventId,
  sanitizeMenuItemGroups,
  fetchMenuItemsByIds,
} from "./menuSelectionHelpers.js";

export const getSelectedMenuItemsForInvitation = onCall(async (request) => {
  try {
    const { invitationId, token } = request.data || {};
    if (!invitationId || !token) {
      throw new HttpsError("invalid-argument", "invitationId and token are required");
    }

    const invSnap = await (await import("./admin.js")).db.collection("invitations").doc(invitationId).get();
    if (!invSnap.exists) throw new HttpsError("not-found", "Invitation not found");

    const inv = invSnap.data() || {};
    if ((inv.token || "") !== token) throw new HttpsError("permission-denied", "Invalid token");

    const expiresAt = inv.expiresAt?.toDate ? inv.expiresAt.toDate() : null;
    if (expiresAt && expiresAt.getTime() < Date.now()) {
      throw new HttpsError("failed-precondition", "Invitation expired");
    }

    const eventId = (inv.eventId || "").toString();
    if (!eventId) throw new HttpsError("failed-precondition", "Invitation missing eventId");

    const eventObj = await getEventDataByEventId(eventId);
    if (!eventObj) throw new HttpsError("not-found", "Event not found");

    const eventData = eventObj.data || {};
    const rawGroups = Array.isArray(eventData.menuItemGroups) ? eventData.menuItemGroups : [];

    const ungroupedIds = normalizeIds(eventData.selectedMenuItemIds);
    const groupedIds = collectGroupItemIds(rawGroups);
    const allIds = normalizeIds([...ungroupedIds, ...groupedIds]);

    if (!allIds.length) {
      return { ok: true, eventId, eventName: eventData.name || "Event", groups: [], items: [] };
    }

    const mapById = await fetchMenuItemsByIds(allIds);

    const allowedSet = new Set(allIds);
    const { groups: sanitizedGroups, groupedSet } = sanitizeMenuItemGroups(rawGroups, allowedSet, mapById);

    const groups = sanitizedGroups.map((g) => ({
      groupId: g.groupId,
      name: g.name,
      categoryKey: g.categoryKey,
      categoryLabel: g.categoryLabel,
      maxPick: g.maxPick,
      items: g.itemIds.map((id) => mapById[id]).filter(Boolean),
    }));

    const items = [];
    for (const id of ungroupedIds) {
      if (groupedSet.has(id)) continue;
      const item = mapById[id];
      if (item) items.push(item);
    }

    return { ok: true, eventId, eventName: eventData.name || "Event", groups, items };
  } catch (err) {
    console.error("getSelectedMenuItemsForInvitation error:", err);
    throw err instanceof HttpsError ? err : new HttpsError("internal", err?.message ?? "Unknown error");
  }
});
