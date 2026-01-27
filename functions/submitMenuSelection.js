import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "./admin.js";
import {
  normalizeIds,
  collectGroupItemIds,
  getEventDataByEventIdTx,
  sanitizeMenuItemGroups,
} from "./menuSelectionHelpers.js";

const ALLOWED_ALLERGENS = new Set([
  "dairy",
  "eggs",
  "fish",
  "shellfish",
  "soy",
  "sesame",
  "wheat",
  "peanuts",
  "tree_nuts",
]);

function cleanAllergens(arr) {
  if (!Array.isArray(arr)) return [];
  const out = [];
  for (const v of arr) {
    const s = (v ?? "").toString().trim().toLowerCase();
    if (s && ALLOWED_ALLERGENS.has(s) && !out.includes(s)) out.push(s);
  }
  out.sort();
  return out;
}

export const submitMenuSelection = onCall(async (request) => {
  try {
    const {
      invitationId,
      token,
      selectedMenuItemIds,
      companionIndex,
      dietPreference,
      allergens, // ✅ NEW
    } = request.data || {};

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

    // ✅ diet normalize (default both)
    const prefRaw = (dietPreference || "").toString().trim().toLowerCase();
    const normalizedPref =
      prefRaw === "veg" ? "veg" :
      (prefRaw === "non_veg" || prefRaw === "non-veg") ? "non_veg" :
      prefRaw === "both" ? "both" :
      "both";

    const cleanedAllergens = cleanAllergens(allergens);

    const personKey = isMainGuest ? "main" : `c${compIdx}`;

    const invRef = db.collection("invitations").doc(invitationId);
    const respDocId = isMainGuest ? invitationId : `${invitationId}_companion_${compIdx}`;
    const respRef = db.collection("menuSelectedItemsResponses").doc(respDocId);

    const result = await db.runTransaction(async (tx) => {
      const invSnap = await tx.get(invRef);
      if (!invSnap.exists) throw new HttpsError("not-found", "Invitation not found");
      const inv = invSnap.data() || {};

      if ((inv.token || "") !== token) throw new HttpsError("permission-denied", "Invalid token");

      const expiresAt = inv.expiresAt?.toDate ? inv.expiresAt.toDate() : null;
      if (expiresAt && expiresAt.getTime() < Date.now()) {
        throw new HttpsError("failed-precondition", "Invitation expired");
      }

      const companions = Array.isArray(inv.companions) ? [...inv.companions] : [];
      if (!isMainGuest && compIdx >= companions.length) {
        throw new HttpsError("invalid-argument", `Companion index ${compIdx} is out of range.`);
      }

      // prerequisites
      if (isMainGuest) {
        if (inv.used !== true) throw new HttpsError("failed-precondition", "Demographic questions not submitted yet");
      } else {
        const companion = companions[compIdx];
        if (companion.demographicSubmitted !== true) {
          throw new HttpsError("failed-precondition", `Companion ${compIdx} has not submitted demographics yet`);
        }
      }

      // detect already submitted
      const alreadySubmitted = isMainGuest
        ? (inv.menuSelectionSubmitted === true)
        : (companions[compIdx]?.menuSubmitted === true);

      // ✅ if already submitted: still patch diet+allergens, then return
      if (alreadySubmitted) {
        const patch = {
          [`dietPreferenceByPerson.${personKey}`]: normalizedPref,
          [`allergensByPerson.${personKey}`]: cleanedAllergens,
          modifiedAt: FieldValue.serverTimestamp(),
        };

        if (isMainGuest) {
          tx.update(invRef, patch);
        } else {
          companions[compIdx] = {
            ...companions[compIdx],
            dietPreference: normalizedPref,
            allergens: cleanedAllergens,
          };
          tx.update(invRef, { ...patch, companions });
        }

        return { ok: true, alreadySubmitted: true, companionIndex: compIdx, dietPreference: normalizedPref, allergens: cleanedAllergens, patched: true };
      }

      // extra safety
      const existing = await tx.get(respRef);
      if (existing.exists) {
        const patch = {
          [`dietPreferenceByPerson.${personKey}`]: normalizedPref,
          [`allergensByPerson.${personKey}`]: cleanedAllergens,
          modifiedAt: FieldValue.serverTimestamp(),
        };

        if (isMainGuest) tx.update(invRef, patch);
        else {
          companions[compIdx] = {
            ...companions[compIdx],
            dietPreference: normalizedPref,
            allergens: cleanedAllergens,
          };
          tx.update(invRef, { ...patch, companions });
        }

        return { ok: true, alreadySubmitted: true, companionIndex: compIdx, dietPreference: normalizedPref, allergens: cleanedAllergens, patched: true };
      }

      // ----- existing validation logic -----
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

      for (const id of cleaned) {
        if (!allowedSet.has(id)) throw new HttpsError("invalid-argument", "Invalid menu item selected");
      }

      // enforce maxPick only (no required enforcement)
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

        groupSelections[g.groupId] = picked; // may be null (allowed)
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

      // response doc includes diet + allergens
      tx.set(respRef, {
        eventId: inv.eventId || "",
        organisationId: inv.organisationId || "",
        invitationId,
        guestId,
        guestEmail,
        guestName,
        isCompanion: !isMainGuest,
        companionIndex: compIdx,

        dietPreference: normalizedPref,
        allergens: cleanedAllergens,

        selectedMenuItemIds: cleaned,
        groupSelections,
        createdAt: FieldValue.serverTimestamp(),
      });

      const selectionSummary = {
        dietPreference: normalizedPref,
        allergens: cleanedAllergens,
        selectedMenuItemIds: cleaned,
        groupSelections,
        submittedAt: FieldValue.serverTimestamp(),
      };

      if (isMainGuest) {
        tx.update(invRef, {
          menuSelectionSubmitted: true,
          menuSelectionSubmittedAt: FieldValue.serverTimestamp(),

          [`dietPreferenceByPerson.${personKey}`]: normalizedPref,
          [`allergensByPerson.${personKey}`]: cleanedAllergens,
          [`menuSelectionByPerson.${personKey}`]: selectionSummary,

          modifiedAt: FieldValue.serverTimestamp(),
        });
      } else {
        companions[compIdx] = {
          ...companions[compIdx],
          dietPreference: normalizedPref,
          allergens: cleanedAllergens,
          menuSubmitted: true,
          menuResponseId: respRef.id,
          menuSubmittedAt: new Date().toISOString(),
          selectedMenuItemIds: cleaned,
          groupSelections,
        };

        tx.update(invRef, {
          companions,

          [`dietPreferenceByPerson.${personKey}`]: normalizedPref,
          [`allergensByPerson.${personKey}`]: cleanedAllergens,
          [`menuSelectionByPerson.${personKey}`]: selectionSummary,

          modifiedAt: FieldValue.serverTimestamp(),
        });
      }

      return { ok: true, alreadySubmitted: false, companionIndex: compIdx, dietPreference: normalizedPref, allergens: cleanedAllergens };
    });

    console.log("✅ submitMenuSelection WRITE", {
      invitationId,
      isMainGuest,
      compIdx,
      personKey,
      normalizedPref,
      cleanedAllergens,
    });

    return result;
  } catch (err) {
    console.error("submitMenuSelection error:", err);
    throw err instanceof HttpsError ? err : new HttpsError("internal", err?.message ?? "Unknown error");
  }
});


