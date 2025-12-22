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

  // Resolve the event regardless of whether caller passed docId or public id
  const eventObj = await getEventDataByEventId(eventPublicId);
  if (!eventObj) throw new HttpsError("not-found", "Event not found");

  const event = eventObj.data || {};
  const eventOrgId = safeStr(event.organisationId);

  // Verify host belongs to organisation
  const userSnap = await db.collection("users").doc(request.auth.uid).get();
  const user = userSnap.exists ? (userSnap.data() || {}) : {};
  const userOrgId = safeStr(user.organisationId);

  if (!eventOrgId || !userOrgId || eventOrgId !== userOrgId) {
    throw new HttpsError("permission-denied", "Not allowed");
  }

  // IMPORTANT: invitations/responses store public eventId in your system
  const matchEventId = safeStr(event.eventId) || eventPublicId;

  // 3) Invitations funnel stats
  const invSnap = await db.collection("invitations").where("eventId", "==", matchEventId).get();

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
  const demoSnap = await db
    .collection("demographicQuestionsResponses")
    .where("eventId", "==", matchEventId)
    .get();

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
  const menuSnap = await db
    .collection("menuSelectedItemsResponses")
    .where("eventId", "==", matchEventId)
    .get();

  const menu = { responses: menuSnap.size, itemCounts: {} };

  menuSnap.forEach((doc) => {
    const r = doc.data() || {};
    const ids = Array.isArray(r.selectedMenuItemIds) ? r.selectedMenuItemIds : [];
    for (const id of ids) inc(menu.itemCounts, safeStr(id), 1);
  });

  // 6) Attach menu item metadata
  const itemIds = Object.keys(menu.itemCounts);
  const itemsById = {};

  for (const batch of chunk(itemIds, 10)) {
    const snap = await db.collection("menu_items").where(FieldPath.documentId(), "in", batch).get();
    snap.forEach((d) => {
      const x = d.data() || {};
      itemsById[d.id] = {
        id: d.id,
        name: x.name || x.title || "Menu item",
        category: x.category ?? "other",
        isVeg: typeof x.isVeg === "boolean" ? x.isVeg : null,
      };
    });
  }

  const menuItems = itemIds
    .map((id) => ({ ...itemsById[id], id, count: menu.itemCounts[id] }))
    .sort((a, b) => (b.count ?? 0) - (a.count ?? 0));

  return {
    ok: true,
    eventId: matchEventId,
    eventName: safeStr(event.name) || "Event",
    invitations: inv,
    demographics: { responses: demoSnap.size, questions: Object.values(demoQuestions) },
    menu: { responses: menu.responses, items: menuItems },
  };
});
