import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { db } from "./admin.js";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import postmark from "postmark";

// ─────────────────────────────────────────────
// Postmark + App config
// ─────────────────────────────────────────────
const POSTMARK_SERVER_TOKEN = defineSecret("POSTMARK_SERVER_TOKEN");

const FROM_EMAIL = process.env.FROM_EMAIL || "developer@trax-event.com";
const FROM_NAME = process.env.FROM_NAME || "Trax Events";
const APP_BASE_URL = process.env.APP_BASE_URL || "https://trax-event.app";
const MESSAGE_STREAM = process.env.POSTMARK_MESSAGE_STREAM || "outbound";

function buildDetailsLink(invId, invToken) {
  return (
    `${APP_BASE_URL}/guest-response?invitationId=${encodeURIComponent(invId)}` +
    `&token=${encodeURIComponent(invToken)}` +
    `&view=details&v=${Date.now()}`
  );
}

// For demographics-only events, "complete" means:
// - main guest RSVP responded + attending
// - companions attendance confirmed; if attending: demo submitted; if not attending: skip
// - and menu is NOT required / not configured (no selectedMenuItemIds + no menuItemGroups)
function isMenuRequired(inv) {
  // If you store menu config on invitation, use that. Otherwise treat it as required
  // when a menu has been selected/attached in invitation (common pattern).
  // ✅ safest: if invitation has any menu requirement flag/ids.
  const ids = inv?.selectedMenuItemIds;
  const groups = inv?.menuItemGroups;
  if (Array.isArray(ids) && ids.length > 0) return true;
  if (Array.isArray(groups) && groups.length > 0) return true;

  // If you have a flag like inv.menuRequired, respect it:
  if (inv?.menuRequired === true) return true;

  // Otherwise assume menu may be required later (but for demographics-only event
  // you should store menu config presence somewhere). We'll treat it as NOT required.
  return false;
}

function isFlowCompleteForDemographicsOnly(inv) {
  if (!inv) return false;

  // Declined is complete
  if (inv.hasResponded === true && inv.isAttending === false) return true;

  // Must RSVP yes
  if (inv.hasResponded !== true || inv.isAttending !== true) return false;

  const requiresDemo = !!inv.demographicQuestionSetId;

  // if no demographic set, then demographics-only doesn't apply
  if (!requiresDemo) return false;

  // main guest must submit demo
  if (inv.used !== true) return false;

  // companions must have attendance confirmed; if attending then demo submitted
  const comps = Array.isArray(inv.companions) ? inv.companions : [];
  for (const c of comps) {
    if (c?.attendingSubmitted !== true) return false;
    if (c?.isAttending === false) continue;
    if (c?.demographicSubmitted !== true) return false;
  }

  // and menu must NOT be required for this to finish here
  if (isMenuRequired(inv)) return false;

  return true;
}

async function maybeSendThankYouEmailAfterDemographics(invitationId) {
  const invRef = db.collection("invitations").doc(invitationId);
  const invSnap = await invRef.get();
  if (!invSnap.exists) return;

  const inv = invSnap.data() || {};
  if (inv.thankYouEmailSent === true) return;

  if (!isFlowCompleteForDemographicsOnly(inv)) return;

  const guestEmail = (inv.guestEmail || "").toString().trim();
  const invToken = (inv.token || "").toString().trim();
  if (!guestEmail || !invToken) return;

  let eventName = "Your event";
  try {
    const eventId = (inv.eventId || "").toString().trim();
    if (eventId) {
      const eventSnap = await db.collection("events").doc(eventId).get();
      if (eventSnap.exists) {
        eventName = (eventSnap.data()?.name || eventName).toString();
      }
    }
  } catch (_) {}

  const link = buildDetailsLink(invitationId, invToken);

  const pmToken = (POSTMARK_SERVER_TOKEN.value() || "").trim();
  if (!pmToken) return;

  const client = new postmark.ServerClient(pmToken);

  await client.sendEmail({
    From: `"${FROM_NAME}" <${FROM_EMAIL}>`,
    To: guestEmail,
    Subject: `Thank you! Your responses for ${eventName} are submitted`,
    TextBody:
      `Thank you for submitting your responses.\n\n` +
      `View your event details here:\n${link}\n`,
    HtmlBody: `
      <div style="font-family:Segoe UI,Tahoma,Verdana,sans-serif;line-height:1.6;color:#111;">
        <h2 style="margin:0 0 10px;">Thank you!</h2>
        <p style="margin:0 0 14px;">Your responses were submitted successfully.</p>
        <p style="margin:0 0 18px;">
          <a href="${link}" style="display:inline-block;padding:12px 18px;background:#2563eb;color:#fff;border-radius:8px;text-decoration:none;font-weight:600;">
            View Event Details
          </a>
        </p>
        <p style="font-size:12px;color:#666;">
          If the button doesn’t work, use this link:<br/>
          <a href="${link}">${link}</a>
        </p>
      </div>
    `,
    MessageStream: MESSAGE_STREAM,
    Metadata: {
      invitationId,
      eventId: (inv.eventId || "").toString(),
      type: "thank_you",
      via: "submitDemographics",
    },
  });

  await invRef.update({
    thankYouEmailSent: true,
    thankYouEmailSentAt: Timestamp.now(),
  });
}

// ─────────────────────────────────────────────
// ✅ submitDemographics
// ─────────────────────────────────────────────
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

        if ((inv.token || "") !== token) {
          throw new HttpsError("permission-denied", "Invalid token");
        }

        const expiresAt = inv.expiresAt?.toDate ? inv.expiresAt.toDate() : null;
        if (expiresAt && expiresAt.getTime() < Date.now()) {
          throw new HttpsError("failed-precondition", "Invitation expired");
        }

        const companions = Array.isArray(inv.companions) ? [...inv.companions] : [];

        if (!isMainGuest) {
          if (compIdx >= companions.length) {
            throw new HttpsError(
              "invalid-argument",
              `Companion index ${compIdx} is out of range. Only ${companions.length} companions exist.`
            );
          }

          const c = companions[compIdx] || {};

          if (c.attendingSubmitted !== true) {
            throw new HttpsError("failed-precondition", "Companion attendance not confirmed yet");
          }

          if (c.isAttending === false) {
            return { ok: true, skipped: true, reason: "companion_not_attending", companionIndex: compIdx };
          }

          if (c.demographicSubmitted === true) {
            return {
              ok: true,
              alreadySubmitted: true,
              responseId: c.demographicResponseId || null,
              companionIndex: compIdx,
            };
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

      // ✅ Thank-you mail for demographics-only flows
      try {
        await maybeSendThankYouEmailAfterDemographics(invitationId);
      } catch (e) {
        console.error("⚠️ maybeSendThankYouEmailAfterDemographics failed:", e);
      }

      return result;
    } catch (err) {
      console.error("submitDemographics error:", err);
      throw err instanceof HttpsError
        ? err
        : new HttpsError("internal", err?.message ?? "Unknown error");
    }
  }
);
