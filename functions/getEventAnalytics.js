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

async function getEventDataByEventId(eventId) {
  // 1) try doc id
  const byDoc = await db.collection("events").doc(eventId).get();
  if (byDoc.exists) return { id: byDoc.id, data: byDoc.data() };

  // 2) fallback query by field
  const q = await db.collection("events").where("eventId", "==", eventId).limit(1).get();
  if (q.empty) return null;

  return { id: q.docs[0].id, data: q.docs[0].data() };
}

  export const getEventAnalytics = onCall(async (request) => {
    // this is the eventId you pass from Flutter (public eventId in your app)
    const eventPublicId = safeStr(request.data?.eventId);
    if (!eventPublicId) {
      throw new HttpsError("invalid-argument", "eventId is required");
    }

    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Sign in required");
    }

    console.log("🔍 getEventAnalytics called:");
    console.log("  - Event ID:", eventPublicId);
    console.log("  - User UID:", request.auth.uid);
    console.log("  - User Email:", request.auth.token.email);

    // Resolve the event regardless of whether caller passed docId or public id
    const eventObj = await getEventDataByEventId(eventPublicId);
    if (!eventObj) throw new HttpsError("not-found", "Event not found");

    const event = eventObj.data || {};
    const eventDocId = safeStr(eventObj.id);        // Firestore docId
    const eventFieldId = safeStr(event.eventId);    // eventId field inside doc (public id maybe)
    const candidateEventIds = Array.from(
      new Set([eventPublicId, eventDocId, eventFieldId].filter(Boolean))
    );

// helper to query by eventId supporting both docId + publicId
    async function queryByEventId(collectionName) {
      if (candidateEventIds.length === 1) {
        return db.collection(collectionName).where("eventId", "==", candidateEventIds[0]).get();
      }
      // Firestore "in" supports up to 10 values (we have max 3 here)
      return db.collection(collectionName).where("eventId", "in", candidateEventIds).get();
    }

  console.log("🧩 candidateEventIds:", candidateEventIds);

    const eventOrgId = safeStr(event.organisationId);

    // Load caller profile
    const userSnap = await db.collection("users").doc(request.auth.uid).get();
    const user = userSnap.exists ? (userSnap.data() || {}) : {};
    const userOrgId = safeStr(user.organisationId);
    const userRole = safeStr(user.role);

    // ─────────────────────────────────────────────
    // ✅ Authorization (ALIGNED with your Firestore rules)
    //   - superAdmin / super_admin: can view any event analytics
    //   - admin: can view only events in same organisation
    //   - host: can view only events where they are assigned (hostUserIds contains uid)
    // ─────────────────────────────────────────────
    const isSuperAdmin = userRole === "superAdmin" || userRole === "super_admin";
    const isOrgAdmin = userRole === "admin";
    const isHost = userRole === "host";

    const hostUserIds = Array.isArray(event.hostUserIds) ? event.hostUserIds : [];
    const isEventHost =
      isHost && hostUserIds.map(safeStr).includes(request.auth.uid);

    const isAdminForEvent =
      isSuperAdmin || (isOrgAdmin && !!eventOrgId && eventOrgId === userOrgId);

    if (!isAdminForEvent && !isEventHost) {
      throw new HttpsError(
        "permission-denied",
        "You don't have permission to view this event's analytics"
      );
    }

    console.log("✅ Permission granted for analytics");

    // IMPORTANT: invitations/responses store public eventId in your system
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

    // ✅ 5.1) Guest selections (for guest filter) — build from menuSelectedItemsResponses docs
    const guestMap = new Map(); // key -> { invitationId, name, email, selectedMenuItemIds }

    menuSnap.forEach((doc) => {
      const r = doc.data() || {};

      const invitationId = safeStr(r.invitationId || r.invId || r.invitationID);
      const guestName = safeStr(
        r.guestName || r.name || r.guest || r.guestEmail || r.email || "Guest"
      );
      const guestEmail = safeStr(r.guestEmail || r.email);

      const ids = Array.isArray(r.selectedMenuItemIds)
        ? r.selectedMenuItemIds.map(safeStr).filter(Boolean)
        : [];

      if (!invitationId || ids.length === 0) return;

      // If you support companions later, add companionIndex to the key:
      const companionIndex = r.companionIndex ?? null;
      const key = `${invitationId}:${companionIndex === null ? "main" : String(companionIndex)}`;

      const existing = guestMap.get(key);
      if (existing) {
        const merged = new Set([...(existing.selectedMenuItemIds || []), ...ids]);
        existing.selectedMenuItemIds = Array.from(merged);
        if (!existing.name && guestName) existing.name = guestName;
        if (!existing.email && guestEmail) existing.email = guestEmail;
      } else {
        guestMap.set(key, {
          invitationId,
          name: guestName,
          email: guestEmail || null,
          companionIndex: companionIndex === null ? null : Number(companionIndex),
          selectedMenuItemIds: Array.from(new Set(ids)),
        });
      }
    });

    const guestSelections = Array.from(guestMap.values()).sort((a, b) =>
      safeStr(a.name).localeCompare(safeStr(b.name))
    );
    
    const invToIds = new Map();
    const invIds = Array.from(invToIds.keys());

  // Lookup guest names from invitations collection (batch by 10)
    for (const batch of chunk(invIds, 10)) {
      const snap = await db
        .collection("invitations")
        .where(FieldPath.documentId(), "in", batch)
        .get();

      snap.forEach((d) => {
        const inv = d.data() || {};
        const guestName = safeStr(inv.guestName || inv.name || inv.guest || inv.email || "Guest");
        guestSelections.push({
          invitationId: d.id,
          name: guestName,
          selectedMenuItemIds: invToIds.get(d.id) || [],
        });
      });
    }

    // Sort guests alphabetically
    guestSelections.sort((a, b) => safeStr(a.name).localeCompare(safeStr(b.name)));

    // 6) Attach menu item metadata (FULL FIELDS FOR UI)
    const itemIds = Object.keys(menu.itemCounts);
    const itemsById = {};

    function safeNum(x) {
      const n = Number(x);
      return Number.isFinite(n) ? n : null;
    }

    function deriveIsVegFromFoodType(ft) {
      const s = safeStr(ft).toLowerCase();
      if (!s) return null;
      if (s === "veg") return true;
      if (s === "non_veg" || s === "non-veg" || s.includes("non")) return false;
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

          const foodType = safeStr(x.foodType); // "veg" | "non_veg" (your schema)
          const isVeg =
            typeof x.isVeg === "boolean" ? x.isVeg : deriveIsVegFromFoodType(foodType);

          itemsById[d.id] = {
            id: d.id,
            // basic
            name: safeStr(x.name || x.title || "Menu item"),
            category: safeStr(x.category) || "Other",
            // for UI (Flutter can prettify / title-case)
            categoryLabel: safeStr(x.category) || "Other",

            // food + price
            foodType: foodType || null,
            isVeg,
            price: safeNum(x.price),

            // media + text
            imageUrl: safeStr(x.imageUrl) || null,
            description: safeStr(x.description) || "",

            // allergens
            allergens: Array.isArray(x.allergens)
              ? x.allergens.map(safeStr).filter(Boolean)
              : [],
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


