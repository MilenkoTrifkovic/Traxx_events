// functions/getEventAnalytics.js
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldPath } from "firebase-admin/firestore";
import { db } from "./admin.js";

function chunk(arr, size) {
  const out = [];
  for (let i = 0; i < arr.length; i += size) out.push(arr.slice(i, i + size));
  return out;
}

function safeStr(x) {
  return (x ?? "").toString().trim();
}

function inc(map, key, by = 1) {
  if (!key) return;
  map[key] = (map[key] ?? 0) + by;
}

function normalizeSingleChoiceAnswer(raw) {
  if (raw == null) return null;
  if (typeof raw === "string") return { value: raw, freeText: null };
  if (typeof raw === "object") {
    const value = safeStr(raw.value);
    const freeText = safeStr(raw.freeText || "");
    return { value: value || null, freeText: freeText || null };
  }
  return { value: safeStr(raw) || null, freeText: null };
}

function normalizeCheckboxAnswer(raw) {
  if (!Array.isArray(raw)) return [];
  return raw
    .map((x) => ({
      value: safeStr(x?.value),
      freeText: safeStr(x?.freeText || ""),
    }))
    .filter((x) => x.value);
}

function normalizeIds(arr) {
  const out = [];
  const seen = new Set();
  for (const x of Array.isArray(arr) ? arr : []) {
    const id = safeStr(x);
    if (!id) continue;
    if (seen.add(id)) out.push(id);
  }
  return out;
}

function collectGroupSelectionsIds(groupSelections) {
  // supports:
  // 1) groupSelections: [{ itemIds: [...] }, ...]
  // 2) groupSelections: { groupA: { itemIds: [...] }, groupB: { itemIds: [...] } }
  // 3) groupSelections: { groupA: [...ids], groupB: [...ids] }
  const out = [];
  const pushIds = (maybeIds) => {
    for (const id of normalizeIds(maybeIds)) out.push(id);
  };

  if (Array.isArray(groupSelections)) {
    for (const g of groupSelections) {
      if (!g) continue;
      if (Array.isArray(g.itemIds)) pushIds(g.itemIds);
      else if (Array.isArray(g.selectedMenuItemIds)) pushIds(g.selectedMenuItemIds);
      else if (Array.isArray(g.items)) pushIds(g.items);
    }
    return normalizeIds(out);
  }

  if (groupSelections && typeof groupSelections === "object") {
    for (const v of Object.values(groupSelections)) {
      if (!v) continue;
      if (Array.isArray(v)) pushIds(v);
      else if (typeof v === "object") {
        if (Array.isArray(v.itemIds)) pushIds(v.itemIds);
        else if (Array.isArray(v.selectedMenuItemIds)) pushIds(v.selectedMenuItemIds);
      }
    }
    return normalizeIds(out);
  }

  return [];
}

function parseCompanionIndexFromDocId(docId) {
  const m = safeStr(docId).match(/_companion_(\d+)$/);
  return m ? Number(m[1]) : null;
}

function guestKeyForSelection({ invitationId, guestEmail, guestName, companionIndex }) {
  const ciStr = companionIndex == null ? "main" : String(companionIndex);
  const inv = safeStr(invitationId);
  const em = safeStr(guestEmail).toLowerCase();
  const nm = safeStr(guestName).toLowerCase();

  if (inv) return `inv:${inv}:${ciStr}`;
  if (em) return `email:${em}:${ciStr}`;
  if (nm) return `name:${nm}:${ciStr}`;
  return null;
}

async function getEventDataByEventId(eventId) {
  // 1) try doc id
  const byDoc = await db.collection("events").doc(eventId).get();
  if (byDoc.exists) return { id: byDoc.id, data: byDoc.data() };

  // 2) fallback query by field
  const q = await db
    .collection("events")
    .where("eventId", "==", eventId)
    .limit(1)
    .get();
  if (q.empty) return null;

  return { id: q.docs[0].id, data: q.docs[0].data() };
}

export const getEventAnalytics = onCall(async (request) => {
  const eventPublicId = safeStr(request.data?.eventId);
  if (!eventPublicId) {
    throw new HttpsError("invalid-argument", "eventId is required");
  }

  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Sign in required");
  }

  const eventObj = await getEventDataByEventId(eventPublicId);
  if (!eventObj) throw new HttpsError("not-found", "Event not found");
  const event = eventObj.data || {};
  const eventDocId = safeStr(eventObj.id);
  const eventFieldId = safeStr(event.eventId);
  const candidateEventIds = Array.from(
    new Set([eventPublicId, eventDocId, eventFieldId].filter(Boolean))
  );

  async function queryByEventId(collectionName) {
    if (candidateEventIds.length === 1) {
      return db
        .collection(collectionName)
        .where("eventId", "==", candidateEventIds[0])
        .get();
    }
    return db
      .collection(collectionName)
      .where("eventId", "in", candidateEventIds)
      .get();
  }

  console.log("🧩 candidateEventIds:", candidateEventIds);

  const eventOrgId = safeStr(event.organisationId);
  // Load caller profile
  const userSnap = await db.collection("users").doc(request.auth.uid).get();
  const user = userSnap.exists ? userSnap.data() || {} : {};
  const userOrgId = safeStr(user.organisationId);
  const userRole = safeStr(user.role);
  // ─────────────────────────────────────────────
  // ✅ Authorization
  // ─────────────────────────────────────────────
  const isSuperAdmin = userRole === "superAdmin" || userRole === "super_admin";
  const isOrgAdmin = userRole === "admin";
  const isHost = userRole === "host";
  const isSalesPerson =
    userRole === "sales_person" &&
    user.isActive === true &&
    user.isDisabled !== true;
  const hostUserIds = Array.isArray(event.hostUserIds) ? event.hostUserIds : [];
  const isEventHost =
    isHost && hostUserIds.map(safeStr).includes(request.auth.uid);
  const isAdminForEvent =
    isSuperAdmin || (isOrgAdmin && !!eventOrgId && eventOrgId === userOrgId);
  const isSalesPersonForEvent =
    isSalesPerson && !!eventOrgId && !!userOrgId && eventOrgId === userOrgId;

  if (!isAdminForEvent && !isEventHost && !isSalesPersonForEvent) {
    throw new HttpsError(
      "permission-denied",
      "You don't have permission to view this event's analytics"
    );
  }

  console.log("✅ Permission granted for analytics");

  const matchEventId = safeStr(event.eventId) || eventPublicId;

  // 3) Invitations funnel stats
  const invSnap = await queryByEventId("invitations");

  const inv = {
    total: invSnap.size,
    sent: 0,
    failed: 0,
    demographicsSubmitted: 0,
    menuSubmitted: 0,
  };

  invSnap.forEach((d) => {
    const x = d.data() || {};
    if (x.sent === true) inv.sent++;
    if (x.sent === false && x.sendError) inv.failed++;
    if (x.used === true) inv.demographicsSubmitted++;
    if (x.menuSelectionSubmitted === true) inv.menuSubmitted++;
  });

  // 4) Demographics aggregation
  const demoSnap = await queryByEventId("demographicQuestionsResponses");

  const demoQuestions = {};
  const DEMO_TEXT_SAMPLES_LIMIT = 10;

  demoSnap.forEach((doc) => {
    const r = doc.data() || {};
    const answers = Array.isArray(r.answers) ? r.answers : [];

    for (const a of answers) {
      const qid = safeStr(a?.questionId);
      if (!qid) continue;

      const qText = safeStr(a?.questionText);
      const type = safeStr(a?.type) || "unknown";
      const isRequired = a?.isRequired === true;

      demoQuestions[qid] ??= {
        questionId: qid,
        questionText: qText,
        type,
        isRequired,
        answeredCount: 0,
        optionCounts: {},
        freeTextCount: 0,
        freeTextSamples: [],
      };

      const qAgg = demoQuestions[qid];
      const raw = a?.answer;

      if (type === "short_answer" || type === "paragraph") {
        const txt = safeStr(raw);
        if (txt) {
          qAgg.answeredCount++;
          if (qAgg.freeTextSamples.length < DEMO_TEXT_SAMPLES_LIMIT) {
            qAgg.freeTextSamples.push(txt);
          }
        }
        continue;
      }

      if (type === "checkboxes") {
        const items = normalizeCheckboxAnswer(raw);
        if (items.length) qAgg.answeredCount++;
        for (const it of items) {
          inc(qAgg.optionCounts, it.value, 1);
          if (it.freeText) qAgg.freeTextCount++;
        }
        continue;
      }

      const one = normalizeSingleChoiceAnswer(raw);
      if (one?.value) {
        qAgg.answeredCount++;
        inc(qAgg.optionCounts, one.value, 1);
        if (one.freeText) qAgg.freeTextCount++;
      }
    }
  });

  
  // 5) Menu aggregation
  const menuSnap = await queryByEventId("menuSelectedItemsResponses");
  console.log("🍽️ menuSnap.size:", menuSnap.size);

  const menu = { responses: menuSnap.size, itemCounts: {} };

  // ✅ Guest selections (for guest filter + table)
  const guestMap = new Map(); // key -> guest row

  menuSnap.forEach((doc) => {
    const r = doc.data() || {};

    // ✅ Extract selected item ids correctly
    let ids = [];
    if (Array.isArray(r.selectedMenuItemIds)) {
      ids = normalizeIds(r.selectedMenuItemIds);
    } else if (r.groupSelections) {
      ids = collectGroupSelectionsIds(r.groupSelections);
    } else if (Array.isArray(r.groups)) {
      // optional fallback if schema ever changes
      for (const g of r.groups) {
        if (Array.isArray(g?.itemIds)) ids.push(...normalizeIds(g.itemIds));
      }
      ids = normalizeIds(ids);
    }

    if (!ids.length) return;

    // ✅ itemCounts
    for (const id of ids) inc(menu.itemCounts, id, 1);

    // guest identity
    const invitationId = safeStr(r.invitationId || r.invId || r.invitationID);
    const guestName = safeStr(r.guestName || r.name || r.guest || r.email || r.guestEmail || "Guest");
    const guestEmail = safeStr(r.guestEmail || r.email);

    let companionIndex = r.companionIndex ?? null;
    if (companionIndex == null) companionIndex = parseCompanionIndexFromDocId(doc.id);

    const key = guestKeyForSelection({
      invitationId,
      guestEmail,
      guestName,
      companionIndex,
    });
    if (!key) return;

    const existing = guestMap.get(key);
    if (existing) {
      const merged = new Set([...(existing.selectedMenuItemIds || []), ...ids]);
      existing.selectedMenuItemIds = Array.from(merged);

      // fill blanks
      if (!existing.name && guestName) existing.name = guestName;
      if (!existing.email && guestEmail) existing.email = guestEmail;
      if (!existing.invitationId && invitationId) existing.invitationId = invitationId;
      if (existing.companionIndex == null && companionIndex != null) existing.companionIndex = Number(companionIndex);
    } else {
      guestMap.set(key, {
        invitationId: invitationId || null,
        name: guestName || "Guest",
        email: guestEmail || null,
        companionIndex: companionIndex == null ? null : Number(companionIndex),
        selectedMenuItemIds: ids,
      });
    }
  });

  let guestSelections = Array.from(guestMap.values()).sort((a, b) =>
    safeStr(a.name).localeCompare(safeStr(b.name))
  );

  // 6) Attach menu item metadata
  const itemIds = Object.keys(menu.itemCounts);
  const itemsById = {};

  function safeNum(x) {
    const n = Number(x);
    return Number.isFinite(n) ? n : null;
  }

  function deriveIsVegFromFoodType(ft) {
    const s = safeStr(ft).toLowerCase();
    if (!s) return null;
    const norm = s.replaceAll("_", "").replaceAll("-", "").replaceAll(" ", "");
    if (norm === "veg" || norm === "vegetarian") return true;
    if (norm.startsWith("non") || norm.includes("nonveg") || norm.includes("nonvegetarian")) return false;
    return null;
  }

  if (itemIds.length) {
    for (const batch of chunk(itemIds, 10)) {
      const snap = await db
        .collection("menu_items")
        .where(FieldPath.documentId(), "in", batch)
        .get();

      snap.forEach((d) => {
        const x = d.data() || {};
        const foodType = safeStr(x.foodType);
        const isVeg = typeof x.isVeg === "boolean" ? x.isVeg : deriveIsVegFromFoodType(foodType);

        itemsById[d.id] = {
          id: d.id,
          name: safeStr(x.name || x.title || "Menu item"),
          category: safeStr(x.category) || "Other",
          categoryLabel: safeStr(x.category) || "Other",
          foodType: foodType || null,
          isVeg,
          price: safeNum(x.price),
          imageUrl: safeStr(x.imageUrl) || null,
          description: safeStr(x.description) || "",
          allergens: Array.isArray(x.allergens) ? x.allergens.map(safeStr).filter(Boolean) : [],
        };
      });
    }
  }

  const menuItems = itemIds
    .map((id) => ({
      ...(itemsById[id] || {
        id,
        name: "Menu item",
        category: "Other",
        categoryLabel: "Other",
        foodType: null,
        isVeg: null,
        price: null,
        imageUrl: null,
        description: "",
        allergens: [],
      }),
      id,
      count: menu.itemCounts[id] ?? 0,
    }))
    .sort((a, b) => (b.count ?? 0) - (a.count ?? 0));

  // 7) Compute guest dietType from selected menu items
  function itemIsVegById(id) {
    const it = itemsById[id];
    if (!it) return null;
    if (typeof it.isVeg === "boolean") return it.isVeg;
    return deriveIsVegFromFoodType(it.foodType);
  }

  function computeGuestDietType(selectedIds) {
    let hasVeg = false;
    let hasNonVeg = false;

    for (const id of Array.isArray(selectedIds) ? selectedIds : []) {
      const isVeg = itemIsVegById(id);
      if (isVeg === true) hasVeg = true;
      if (isVeg === false) hasNonVeg = true;
      if (hasVeg && hasNonVeg) break;
    }

    if (hasVeg && hasNonVeg) return "both";
    if (hasVeg) return "veg";
    if (hasNonVeg) return "nonVeg";
    return "unknown";
  }

  guestSelections.forEach((g) => {
    g.dietType = computeGuestDietType(g.selectedMenuItemIds || []);
  });

  // 8) Hydrate guest details (invitation + optional guests collection)
  async function hydrateGuestDetails(list) {
    const invIds = Array.from(new Set(list.map((g) => safeStr(g.invitationId)).filter(Boolean)));
    const invById = new Map();

    if (invIds.length) {
      const invRefs = invIds.map((id) => db.collection("invitations").doc(id));
      const invSnaps = await db.getAll(...invRefs);
      invSnaps.forEach((s) => {
        if (s.exists) invById.set(s.id, s.data() || {});
      });
    }

    for (const g of list) {
      const inv = invById.get(safeStr(g.invitationId)) || {};
      const ci = g.companionIndex;

      // fallback info from invitation or companion object
      let base = inv;
      if (ci != null) {
        const comps = Array.isArray(inv.companions) ? inv.companions : [];
        const c = comps[Number(ci)] || comps.find((x) => Number(x?.companionIndex) === Number(ci)) || null;
        if (c) base = c;
      }

      // Fill guest fields from invitation/companion first
      const name = safeStr(base.guestName || base.name || g.name || "Guest") || "Guest";
      const email = safeStr(base.guestEmail || base.email || g.email);

      g.name = name;
      g.email = email || null;

      g.address = safeStr(base.address || base.street || g.address || "") || null;
      g.city = safeStr(base.city || g.city || "") || null;
      g.state = safeStr(base.state || g.state || "") || null;
      g.country = safeStr(base.country || g.country || "") || null;
      g.gender = safeStr(base.gender || g.gender || "") || null;
    }
  }

  await hydrateGuestDetails(guestSelections);

  return {
    ok: true,
    eventId: matchEventId,
    eventName: safeStr(event.name) || "Event",
    invitations: inv,
    demographics: {
      responses: demoSnap.size,
      questions: Object.values(demoQuestions),
    },
    menu: { responses: menu.responses, items: menuItems, guestSelections },
  };
});


