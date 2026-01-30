import { onCall, HttpsError } from "firebase-functions/v2/https";
import { db } from "./admin.js";
import { FieldValue } from "firebase-admin/firestore";

import { POSTMARK_SERVER_TOKEN, sendThankYouEmailsForInvitation } from "./thankYouEmail.js";

export const submitDemographics = onCall(
  { secrets: [POSTMARK_SERVER_TOKEN] },
  async (request) => {
    try {
      const { invitationId, token, answers, companionIndex } = request.data || {};

      if (!invitationId || !token) {
        throw new HttpsError("invalid-argument", "invitationId and token are required");
      }
      if (!Array.isArray(answers)) {
        throw new HttpsError("invalid-argument", "answers must be an array");
      }

      const isMainGuest = companionIndex === null || companionIndex === undefined;
      const compIdx = isMainGuest ? null : parseInt(companionIndex, 10);

      if (!isMainGuest && (isNaN(compIdx) || compIdx < 0)) {
        throw new HttpsError("invalid-argument", "companionIndex must be a non-negative integer");
      }

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

        const companions = Array.isArray(inv.companions) ? [...inv.companions] : [];

        if (!isMainGuest) {
          if (compIdx >= companions.length) {
            throw new HttpsError("invalid-argument", `Companion index ${compIdx} is out of range.`);
          }

          const c = companions[compIdx] || {};

          // attendance gate
          if (c.attendingSubmitted !== true) {
            throw new HttpsError("failed-precondition", "Companion attendance not confirmed yet");
          }
          if (c.isAttending === false) {
            return { ok: true, skipped: true, reason: "companion_not_attending", companionIndex: compIdx };
          }

          if (c.demographicSubmitted === true) {
            return { ok: true, alreadySubmitted: true, responseId: c.demographicResponseId || null, companionIndex: compIdx };
          }
        } else {
          if (inv.used === true) {
            return { ok: true, alreadySubmitted: true, responseId: inv.responseId || null };
          }
        }

        let guestId, guestEmail, guestName;
        if (isMainGuest) {
          guestId = inv.guestId || null;
          guestEmail = inv.guestEmail || "";
          guestName = inv.guestName || "";
        } else {
          const c = companions[compIdx] || {};
          guestId = c.guestId || null;
          guestEmail = c.guestEmail || c.email || "";
          guestName = c.guestName || c.name || "";
        }

        const respRef = db.collection("demographicQuestionsResponses").doc();
        tx.set(respRef, {
          eventId: inv.eventId || "",
          organisationId: inv.organisationId || "",
          invitationId,
          guestId,
          guestEmail,
          guestName,
          isCompanion: !isMainGuest,
          companionIndex: compIdx,
          demographicQuestionSetId: inv.demographicQuestionSetId || null,
          answers,
          createdAt: FieldValue.serverTimestamp(),
        });

        if (isMainGuest) {
          tx.update(invRef, {
            used: true,
            usedAt: FieldValue.serverTimestamp(),
            responseId: respRef.id,
          });
        } else {
          companions[compIdx] = {
            ...companions[compIdx],
            demographicSubmitted: true,
            demographicResponseId: respRef.id,
            demographicSubmittedAt: new Date().toISOString(),
          };
          tx.update(invRef, { companions });
        }

        return { ok: true, skipped: false, alreadySubmitted: false, responseId: respRef.id, companionIndex: compIdx };
      });

      // ✅ trigger thank-you emails if the whole flow becomes complete here
      try {
        await sendThankYouEmailsForInvitation(invitationId);
      } catch (e) {
        console.error("⚠️ sendThankYouEmailsForInvitation failed:", e);
      }

      return result;
    } catch (err) {
      console.error("submitDemographics error:", err);
      throw err instanceof HttpsError ? err : new HttpsError("internal", err?.message ?? "Unknown error");
    }
  }
);
