// functions/sendInvitationForEvent.js
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { Timestamp } from "firebase-admin/firestore";
import { db } from "./admin.js";

import postmark from "postmark";
import { randomBytes } from "crypto";

// ✅ ESM-safe firebase-admin init
// if (!getApps().length) initializeApp();
// const db = getFirestore();

// Secret
const POSTMARK_SERVER_TOKEN = defineSecret("POSTMARK_SERVER_TOKEN");

// Config
const FROM_EMAIL = "developer@trax-event.com";
const FROM_NAME = process.env.FROM_NAME || "Trax Events";
const APP_BASE_URL = "https://trax-event.app";
const INV_EXPIRY_DAYS = (() => {
  const raw = process.env.INV_EXPIRY_DAYS; // could be "0" or "0.01"
  const n = Number.parseInt(String(raw ?? "14"), 10);
  return Number.isFinite(n) && n >= 1 ? n : 14; // ✅ never less than 1 day
})();

const MESSAGE_STREAM = process.env.POSTMARK_MESSAGE_STREAM || "outbound";

function makeToken() {
  return randomBytes(24).toString("hex");
}

function escapeHtml(s) {
  const str = (s ?? "").toString();
  return str
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

export const sendInvitations = onCall(
  { secrets: [POSTMARK_SERVER_TOKEN] },
  async (request) => {
    try {
      if (!APP_BASE_URL) {
        throw new HttpsError("failed-precondition", "APP_BASE_URL missing");
      }

      const {
        eventId,
        organisationId,
        invitations,
        demographicQuestionSetId,
        staticLink,
        invitationCode,
      } = request.data || {};

      if (!eventId) {
        throw new HttpsError("invalid-argument", "eventId is required");
      }

      if (!Array.isArray(invitations) || invitations.length === 0) {
        throw new HttpsError("invalid-argument", "invitations array required");
      }

      // ✅ token: trim to remove accidental whitespace/newlines
      const token = (POSTMARK_SERVER_TOKEN.value() || "").trim();
      console.log("Postmark token length:", token.length);

      if (!token) {
        throw new HttpsError(
          "failed-precondition",
          "POSTMARK_SERVER_TOKEN missing/empty at runtime."
        );
      }

      const client = new postmark.ServerClient(token);

      const createdAt = Timestamp.now();
      const expiresAt = Timestamp.fromMillis(
        Date.now() + INV_EXPIRY_DAYS * 24 * 60 * 60 * 1000
      );
      const preview = await buildQuestionPreview({ questionSetId: demographicQuestionSetId });

      

      const results = [];

      for (const guest of invitations) {
        const guestEmail = (guest?.guestEmail || "").trim();
        const guestName = (guest?.guestName || "").trim();
        const guestId = guest?.guestId || null;
        const maxGuestInvite = typeof guest?.maxGuestInvite === 'number' 
          ? guest.maxGuestInvite 
          : 0;
        const batchId = guest?.batchId || null;

        if (!guestEmail) continue;

        const ref = db.collection("invitations").doc();
        const inviteToken = makeToken();

        await ref.set({
          invitationId: ref.id,
          eventId,
          organisationId: organisationId || null,
          guestId,
          guestEmail,
          guestName,
          maxGuestInvite,
          demographicQuestionSetId: demographicQuestionSetId || null,
          token: inviteToken,
          used: false,
          createdAt,
          expiresAt,
          sent: false,
          ...(invitationCode && { invitationCode }),
          ...(batchId && { batchId }),
        });

        // const link =
        // `${APP_BASE_URL}/demographics?invitationId=${encodeURIComponent(ref.id)}` +
        // `&token=${encodeURIComponent(inviteToken)}`;
        // const link =
        // `${APP_BASE_URL}/guest-response?invitationId=${encodeURIComponent(ref.id)}` +
        // `&token=${encodeURIComponent(inviteToken)}`;
        const link =
        `${APP_BASE_URL}/demographics?invitationId=${encodeURIComponent(ref.id)}` +
        `&token=${encodeURIComponent(inviteToken)}` +
        `&v=${Date.now()}`;

        const subject = "Complete your demographics";

        // Build reference information
        let referenceInfo = "";
        if (invitationCode || batchId) {
          referenceInfo = "\n\nReference Information:";
          if (invitationCode) referenceInfo += `\nInvitation Code: ${invitationCode}`;
          if (batchId) referenceInfo += `\nBatch ID: ${batchId}`;
        }

        const textBody =
            `Hello${guestName ? " " + guestName : ""},\n\n` +
            `Please open this link to answer the demographic questions:\n${link}\n\n` +
            `You may see follow-up questions depending on your answers.\n\n` +
            (preview.text || "") +
            `This link expires in ${INV_EXPIRY_DAYS} days.` +
            referenceInfo +
            `\n\n— ${FROM_NAME}`;


        const safeName = guestName ? escapeHtml(guestName) : "";
        
        // Build HTML reference information
        let htmlReferenceInfo = "";
        if (invitationCode || batchId) {
          htmlReferenceInfo = '<p style="color:#6b7280;font-size:13px;margin-top:20px;padding-top:10px;border-top:1px solid #e5e7eb">';
          htmlReferenceInfo += '<strong>Reference Information:</strong><br/>';
          if (invitationCode) htmlReferenceInfo += `Invitation Code: <strong>${escapeHtml(invitationCode)}</strong><br/>`;
          if (batchId) htmlReferenceInfo += `Batch ID: <strong>${escapeHtml(batchId)}</strong>`;
          htmlReferenceInfo += '</p>';
        }
        
        const htmlBody = `
          <div style="font-family: Poppins, sans-serif; line-height: 1.5;">
            <p>Hello${safeName ? " " + safeName : ""},</p>
            <p>Please click the button below to complete the demographic questions, then choose your preferred menu items.</p>
            <p style="color:#6b7280;font-size:13px;margin-top:10px">
              You may see follow-up questions depending on your answers.
            </p>
            <p style="margin: 18px 0;">
              <a href="${link}" style="display:inline-block;padding:10px 14px;background:#2563eb;color:#fff;text-decoration:none;border-radius:8px">
                Open questions
              </a>
            </p>

            <p style="color:#6b7280;font-size:13px">
              If the button doesn’t work, copy and paste this link into your browser:<br/>
              <a href="${link}">${link}</a>
            </p>

            <p style="color:#6b7280;font-size:13px">
              This link expires in ${INV_EXPIRY_DAYS} days.
            </p>

            ${htmlReferenceInfo}

            <p>— ${escapeHtml(FROM_NAME)}</p>
          </div>
        `;

        try {
          const resp = await client.sendEmail({
            From: `"${FROM_NAME}" <${FROM_EMAIL}>`,
            To: guestEmail,
            Subject: subject,
            TextBody: textBody,
            HtmlBody: htmlBody,
            MessageStream: MESSAGE_STREAM,
            Metadata: { invitationId: ref.id, eventId },
          });

          await ref.update({
            sent: true,
            sentAt: Timestamp.now(),
            postmarkMessageId: resp.MessageID,
          });

          results.push({ guestEmail, invitationId: ref.id, status: "sent" });
        } catch (err) {
          const status = err?.statusCode ?? err?.code ?? null;
          const msg = err?.message ?? String(err);
          const body = err?.response?.body ?? err?.body ?? null;

          await ref.update({
            sent: false,
            sentAt: Timestamp.now(),
            sendError: msg,
            sendErrorStatus: status,
            sendErrorBody: body,
          });

          results.push({
            guestEmail,
            invitationId: ref.id,
            status: "failed",
            error: msg,
            statusCode: status,
          });
        }
      }

      await db.collection("invitationLogs").add({
        eventId,
        organisationId: organisationId || null,
        createdAt: Timestamp.now(),
        results,
      });

      return {
        ok: true,
        invited: results.filter((r) => r.status === "sent").length,
        results,
      };
    } catch (err) {
      console.error("sendInvitations error:", err);
      throw err instanceof HttpsError
        ? err
        : new HttpsError("internal", err?.message ?? "Unknown error");
    }
  }
);

async function buildQuestionPreview({ questionSetId, maxQuestions = 8 }) {
  if (!questionSetId) return { text: "", html: "" };

  // 1) Load questions in the set
  const qsnap = await db
    .collection("demographicQuestions")
    .where("questionSetId", "==", questionSetId)
    .where("isDisabled", "==", false)
    .get();

  const questions = qsnap.docs.map((d) => {
    const data = d.data() || {};
    return {
      docId: d.id,
      questionId: (data.questionId || d.id).toString(),
      questionText: (data.questionText || "").toString(),
      displayOrder: Number(data.displayOrder || 0),
      parentQuestionId: (data.parentQuestionId || "").toString().trim(),
      triggerOptionId: (data.triggerOptionId || "").toString().trim(),
    };
  });

  // base = parentQuestionId empty
  const base = questions
    .filter((q) => !q.parentQuestionId)
    .sort((a, b) => a.displayOrder - b.displayOrder)
    .slice(0, maxQuestions);

  // sub rules = have parentQuestionId + triggerOptionId
  const subs = questions.filter((q) => q.parentQuestionId && q.triggerOptionId);

  // group subs: parentQuestionId -> triggerOptionId -> [subQuestionText...]
  const byParent = new Map();
  for (const s of subs) {
    if (!byParent.has(s.parentQuestionId)) byParent.set(s.parentQuestionId, new Map());
    const byTrigger = byParent.get(s.parentQuestionId);
    if (!byTrigger.has(s.triggerOptionId)) byTrigger.set(s.triggerOptionId, []);
    byTrigger.get(s.triggerOptionId).push(s.questionText);
  }

  // 2) Load option labels for parent questions (to show “If you pick X…”)
  const parentIds = Array.from(byParent.keys());
  const optionIdToLabel = new Map();

  const chunk = (arr, size) => {
    const out = [];
    for (let i = 0; i < arr.length; i += size) out.push(arr.slice(i, i + size));
    return out;
  };

  for (const c of chunk(parentIds, 30)) {
    const osnap = await db
      .collection("demographicQuestionOptions")
      .where("questionId", "in", c)
      .where("isDisabled", "==", false)
      .get();

    for (const od of osnap.docs) {
      const odt = od.data() || {};
      optionIdToLabel.set(od.id, (odt.label || "").toString());
    }
  }

  // 3) Build preview (text + html)
  let text = "";
  let html = "";

  if (base.length > 0) {
    text += "Questions preview (you will answer these on the form):\n";
    html += `
      <div style="margin-top:18px;padding:14px;border:1px solid #e5e7eb;border-radius:10px;background:#fafafa">
        <div style="font-weight:700;margin-bottom:8px">Questions preview</div>
        <div style="color:#6b7280;font-size:13px;margin-bottom:10px">
          You’ll answer these on the website after opening the link.
        </div>
        <ol style="margin:0;padding-left:18px">
    `;

    for (const q of base) {
      const qText = q.questionText || "(Untitled question)";
      text += `• ${qText}\n`;

      html += `<li style="margin:6px 0">${escapeHtml(qText)}`;

      // Conditional rules for this question?
      const triggers = byParent.get(q.questionId);
      if (triggers && triggers.size) {
        text += `  Follow-ups may appear for some answers.\n`;

        html += `
          <div style="margin-top:6px;color:#6b7280;font-size:13px">
            Follow-up questions may appear depending on your answer:
          </div>
          <ul style="margin:6px 0 0 0;padding-left:18px;color:#111827;font-size:13px">
        `;

        // show up to 3 triggers to keep email short
        let shown = 0;
        for (const [triggerOptId, subTexts] of triggers.entries()) {
          if (shown >= 3) break;
          shown++;

          const optLabel = optionIdToLabel.get(triggerOptId) || "Selected option";
          const subList = (subTexts || []).filter(Boolean).slice(0, 3);

          html += `<li><strong>${escapeHtml(optLabel)}</strong> → ${escapeHtml(subList.join(", "))}</li>`;
        }
        html += `</ul>`;
      }

      html += `</li>`;
    }

    html += `</ol></div>`;
  }

  if (text) {
    text += "\nNote: Follow-up questions will only appear when relevant answers are selected.\n\n";
  }

  return { text, html };
}
