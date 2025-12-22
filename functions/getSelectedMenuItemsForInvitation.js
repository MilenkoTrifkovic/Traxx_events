// functions/getSelectedMenuItemsForInvitation.js
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldPath } from "firebase-admin/firestore";
import { db } from "./admin.js";

// if (!getApps().length) initializeApp();
// const db = getFirestore();

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
  const q = await db
    .collection("events")
    .where("eventId", "==", eventId)
    .limit(1)
    .get();

  if (q.empty) return null;
  return { id: q.docs[0].id, data: q.docs[0].data() };
}

// ✅ Canonical enum keys (MenuCategory.name in Flutter)
const CATEGORY_KEYS = new Set([
  "appetizers",
  "salads",
  "soups",
  "entrees",
  "pasta",
  "sides",
  "breads",
  "desserts",
  "beverages",
  "buffet",
  "foodStations",
  "lateNightSnacks",
  "kidsMenu",
  "culturalRegional",
  "dietSpecific",
  "brunch",
  "bbq",
  "other",
]);

function normalizeCategoryKey(raw) {
  const rawStr = (raw ?? "").toString().trim();
  if (!rawStr) return "other";

  if (CATEGORY_KEYS.has(rawStr)) return rawStr;

  const lower = rawStr.toLowerCase().trim();
  const compact = lower.replace(/[\s_-]/g, "");

  // camelCase variants
  if (compact === "foodstations") return "foodStations";
  if (compact === "latenightsnacks") return "lateNightSnacks";
  if (compact === "kidsmenu") return "kidsMenu";
  if (compact === "culturalregional") return "culturalRegional";
  if (compact === "dietspecific") return "dietSpecific";

  // old/singular → new keys
  const map = {
    appetizer: "appetizers",
    salad: "salads",
    soup: "soups",
    entree: "entrees",
    dessert: "desserts",
    drink: "beverages",
    drinks: "beverages",
    beverage: "beverages",
    appetizers: "appetizers",
    salads: "salads",
    soups: "soups",
    entrees: "entrees",
    desserts: "desserts",
    beverages: "beverages",
    buffet: "buffet",
    brunch: "brunch",
    bbq: "bbq",
    other: "other",
  };

  if (map[lower]) return map[lower];

  // label normalization (best effort)
  const cleaned = lower
    .replace(/&/g, "and")
    .replace(/[/]/g, " ")
    .replace(/[_-]/g, " ")
    .replace(/\s+/g, " ")
    .trim();

  const cleanedCompact = cleaned.replace(/\s/g, "");
  if (cleanedCompact === "foodstations") return "foodStations";
  if (cleanedCompact === "latenightsnacks") return "lateNightSnacks";
  if (cleanedCompact === "kidsmenu") return "kidsMenu";
  if (cleanedCompact === "culturalregional" || cleanedCompact === "culturalandregional")
    return "culturalRegional";
  if (cleanedCompact === "dietspecific" || cleanedCompact === "dietandspecific")
    return "dietSpecific";

  return "other";
}

function categoryLabelFromKey(key) {
  switch (key) {
    case "foodStations":
      return "Food Stations";
    case "lateNightSnacks":
      return "Late-Night Snacks";
    case "kidsMenu":
      return "Kids Menu";
    case "culturalRegional":
      return "Cultural / Regional";
    case "dietSpecific":
      return "Diet-Specific";
    case "bbq":
      return "BBQ";
    default:
      return (key || "Other")
        .toString()
        .replace(/([A-Z])/g, " $1")
        .replace(/^./, (c) => c.toUpperCase());
  }
}

function deriveIsVeg(d) {
  if (typeof d.isVeg === "boolean") return d.isVeg;

  const ft = (d.foodType ?? "").toString().trim().toLowerCase();
  if (!ft) return null;

  if (ft === "veg" || ft === "vegetarian") return true;
  if (ft === "non-veg" || ft === "nonveg" || ft === "non vegetarian") return false;

  if (ft.includes("non")) return false;
  return null;
}

export const getSelectedMenuItemsForInvitation = onCall(async (request) => {
  try {
    const { invitationId, token } = request.data || {};
    if (!invitationId || !token) {
      throw new HttpsError("invalid-argument", "invitationId and token are required");
    }

    const invSnap = await db.collection("invitations").doc(invitationId).get();
    if (!invSnap.exists) throw new HttpsError("not-found", "Invitation not found");

    const inv = invSnap.data() || {};

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
      ? eventData.selectedMenuItemIds.filter(
          (x) => typeof x === "string" && x.trim().length > 0
        )
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

        const rawCategory = d.category ?? "";
        const categoryKey = normalizeCategoryKey(rawCategory);
        const categoryLabel = categoryLabelFromKey(categoryKey);
        const isVeg = deriveIsVeg(d);

        mapById[doc.id] = {
          id: doc.id,
          name: d.name || d.title || "Menu item",
          description: (d.description ?? "").toString(),
          price: d.price ?? null,

          // ✅ what the guest UI should use
          categoryKey,
          categoryLabel,
          isVeg,

          // optional debugging (safe to keep/remove)
          foodType: d.foodType ?? null,
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

