import { onCall, HttpsError } from "firebase-functions/v2/https";
import { initializeApp, getApps } from "firebase-admin/app";
import { getFirestore, FieldPath } from "firebase-admin/firestore";


if (!getApps().length) initializeApp();
const db = getFirestore();

function chunk(arr, size) {
  const out = [];
  for (let i = 0; i < arr.length; i += size) out.push(arr.slice(i, i + size));
  return out;
}

async function getEventDataByEventId(eventId) {
  // 1) try doc id
  const byDoc = await db.collection("events").doc(eventId).get();
  if (byDoc.exists) return { id: byDoc.id, data: byDoc.data() };

  // 2) fallback query
  const q = await db.collection("events").where("eventId", "==", eventId).limit(1).get();
  if (q.empty) return null;
  return { id: q.docs[0].id, data: q.docs[0].data() };
}

export const getSelectedMenuItemsForInvitation = onCall(async (request) => {
  try {
    const { invitationId, token } = request.data || {};
    if (!invitationId || !token) {
      throw new HttpsError("invalid-argument", "invitationId and token are required");
    }

    const invSnap = await db.collection("invitations").doc(invitationId).get();
    if (!invSnap.exists) throw new HttpsError("not-found", "Invitation not found");

    const inv = invSnap.data();

    if ((inv.token || "") !== token) {
      throw new HttpsError("permission-denied", "Invalid token");
    }

    const expiresAt = inv.expiresAt?.toDate ? inv.expiresAt.toDate() : null;
    if (expiresAt && expiresAt.getTime() < Date.now()) {
      throw new HttpsError("failed-precondition", "Invitation expired");
    }

    const eventId = (inv.eventId || "").toString();
    if (!eventId) throw new HttpsError("failed-precondition", "Invitation missing eventId");

    const eventObj = await getEventDataByEventId(eventId);
    if (!eventObj) throw new HttpsError("not-found", "Event not found");

    const eventData = eventObj.data || {};
    const selectedIds = Array.isArray(eventData.selectedMenuItemIds)
      ? eventData.selectedMenuItemIds.filter((x) => typeof x === "string" && x.trim().length > 0)
      : [];

    if (!selectedIds.length) {
      return {
        ok: true,
        eventId,
        eventName: eventData.name || "Event",
        items: [],
      };
    }

    // fetch menu_items by documentId in chunks of 10
    const mapById = {};
    for (const batch of chunk(selectedIds, 10)) {
      const snap = await db
        .collection("menu_items")
        .where(FieldPath.documentId(), "in", batch)
        .get();

      snap.forEach((doc) => {
        const d = doc.data() || {};
        if (d.isDisabled === true) return;

        mapById[doc.id] = {
          id: doc.id,
          name: d.name || d.title || "Menu item",
          description: d.description || "",
          category: d.category || "",
          price: d.price ?? null,
          isVeg: d.isVeg ?? null,
        };
      });
    }

    // preserve event-selected order
    const items = [];
    for (const id of selectedIds) {
      if (mapById[id]) items.push(mapById[id]);
    }

    return {
      ok: true,
      eventId,
      eventName: eventData.name || "Event",
      items,
    };
  } catch (err) {
    console.error("getSelectedMenuItemsForInvitation error:", err);
    throw err instanceof HttpsError
      ? err
      : new HttpsError("internal", err?.message ?? "Unknown error");
  }
});
