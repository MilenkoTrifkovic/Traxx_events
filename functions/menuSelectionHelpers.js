import { FieldPath } from "firebase-admin/firestore";
import { db } from "./admin.js";

export function chunk(arr, size) {
  const out = [];
  for (let i = 0; i < arr.length; i += size) out.push(arr.slice(i, i + size));
  return out;
}

export function normalizeIds(arr) {
  const out = [];
  const seen = new Set();
  for (const x of Array.isArray(arr) ? arr : []) {
    const id = (x ?? "").toString().trim();
    if (!id) continue;
    if (seen.add(id)) out.push(id);
  }
  return out;
}

export function collectGroupItemIds(rawGroups) {
  const out = [];
  const seen = new Set();
  const groups = Array.isArray(rawGroups) ? rawGroups : [];
  for (const g of groups) {
    const ids = Array.isArray(g?.itemIds) ? g.itemIds : [];
    for (const x of ids) {
      const id = (x ?? "").toString().trim();
      if (!id) continue;
      if (seen.add(id)) out.push(id);
    }
  }
  return out;
}

export async function getEventDataByEventId(eventId) {
  const byDoc = await db.collection("events").doc(eventId).get();
  if (byDoc.exists) return { id: byDoc.id, data: byDoc.data() };

  const q = await db.collection("events").where("eventId", "==", eventId).limit(1).get();
  if (q.empty) return null;
  return { id: q.docs[0].id, data: q.docs[0].data() };
}

export async function getEventDataByEventIdTx(tx, eventId) {
  const docRef = db.collection("events").doc(eventId);
  const byDoc = await tx.get(docRef);
  if (byDoc.exists) return { id: byDoc.id, data: byDoc.data() };

  const q = db.collection("events").where("eventId", "==", eventId).limit(1);
  const qSnap = await tx.get(q);

  if (qSnap.empty) return null;
  return { id: qSnap.docs[0].id, data: qSnap.docs[0].data() };
}

// ✅ Canonical enum keys (MenuCategory.name in Flutter)
const CATEGORY_KEYS = new Set([
  "appetizers","salads","soups","entrees","pasta","sides","breads","desserts",
  "beverages","buffet","foodStations","lateNightSnacks","kidsMenu",
  "culturalRegional","dietSpecific","brunch","bbq","other",
]);

export function normalizeCategoryKey(raw) {
  const rawStr = (raw ?? "").toString().trim();
  if (!rawStr) return "other";
  if (CATEGORY_KEYS.has(rawStr)) return rawStr;

  const lower = rawStr.toLowerCase().trim();
  const compact = lower.replace(/[\s_-]/g, "");

  if (compact === "foodstations") return "foodStations";
  if (compact === "latenightsnacks") return "lateNightSnacks";
  if (compact === "kidsmenu") return "kidsMenu";
  if (compact === "culturalregional") return "culturalRegional";
  if (compact === "dietspecific") return "dietSpecific";

  const map = {
    appetizer:"appetizers", salad:"salads", soup:"soups", entree:"entrees",
    dessert:"desserts", drink:"beverages", drinks:"beverages", beverage:"beverages",
    appetizers:"appetizers", salads:"salads", soups:"soups", entrees:"entrees",
    desserts:"desserts", beverages:"beverages", buffet:"buffet",
    brunch:"brunch", bbq:"bbq", other:"other",
  };
  if (map[lower]) return map[lower];

  return "other";
}

export function categoryLabelFromKey(key) {
  switch (key) {
    case "foodStations": return "Food Stations";
    case "lateNightSnacks": return "Late-Night Snacks";
    case "kidsMenu": return "Kids Menu";
    case "culturalRegional": return "Cultural / Regional";
    case "dietSpecific": return "Diet-Specific";
    case "bbq": return "BBQ";
    default:
      return (key || "Other").toString().replace(/([A-Z])/g, " $1").replace(/^./, c => c.toUpperCase());
  }
}

export function deriveIsVeg(d) {
  if (typeof d.isVeg === "boolean") return d.isVeg;
  const ft = (d.foodType ?? "").toString().trim().toLowerCase();
  if (!ft) return null;
  if (ft === "veg" || ft === "vegetarian") return true;
  if (ft === "non-veg" || ft === "nonveg" || ft === "non vegetarian") return false;
  if (ft.includes("non")) return false;
  return null;
}

/**
 * Sanitize groups:
 * - valid groupId/name
 * - itemIds unique
 * - itemIds must be in allowedSet
 * - no id appears in multiple groups
 * - if mapById given: drop disabled/missing items
 */
export function sanitizeMenuItemGroups(rawGroups, allowedSet, mapById = null) {
  const input = Array.isArray(rawGroups) ? rawGroups : [];
  const groups = [];
  const groupedSet = new Set();

  for (const g of input) {
    const groupId = (g?.groupId ?? "").toString().trim();
    const name = (g?.name ?? "").toString().trim();
    if (!groupId || !name) continue;

    const categoryKey = normalizeCategoryKey(g?.categoryKey ?? "");
    const maxPickRaw = g?.maxPick;
    let maxPick = 1;
    if (Number.isFinite(+maxPickRaw)) maxPick = Math.max(1, parseInt(maxPickRaw, 10));

    const ids = Array.isArray(g?.itemIds) ? g.itemIds : [];
    const cleaned = [];
    const seen = new Set();

    for (const x of ids) {
      const id = (x ?? "").toString().trim();
      if (!id) continue;
      if (!allowedSet.has(id)) continue;
      if (mapById && !mapById[id]) continue;
      if (groupedSet.has(id)) continue;
      if (seen.add(id)) cleaned.push(id);
    }

    if (cleaned.length === 0) continue;
    cleaned.forEach((id) => groupedSet.add(id));

    groups.push({
      groupId,
      name,
      categoryKey,
      categoryLabel: categoryLabelFromKey(categoryKey),
      maxPick,
      itemIds: cleaned,
    });
  }

  return { groups, groupedSet };
}

export async function fetchMenuItemsByIds(allIds) {
  const ids = normalizeIds(allIds);
  const mapById = {};

  for (const batch of chunk(ids, 10)) {
    const snap = await db
      .collection("menu_items")
      .where(FieldPath.documentId(), "in", batch)
      .get();

    snap.forEach((doc) => {
      const d = doc.data() || {};
      if (d.isDisabled === true) return;

      const categoryKey = normalizeCategoryKey(d.category ?? "");
      mapById[doc.id] = {
        id: doc.id,
        name: d.name || d.title || "Menu item",
        description: (d.description ?? "").toString(),
        price: d.price ?? null,
        imageUrl: d.imageUrl ?? null,
        categoryKey,
        categoryLabel: categoryLabelFromKey(categoryKey),
        isVeg: deriveIsVeg(d),
        foodType: d.foodType ?? null,
      };
    });
  }

  return mapById;
}
