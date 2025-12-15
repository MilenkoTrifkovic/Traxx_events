// test-sendgrid.mjs
import "dotenv/config";
import sgMail from "@sendgrid/mail";

sgMail.setApiKey(process.env.SENDGRID_KEY);

async function test() {
  try {
    const res = await sgMail.send({
      personalizations: [{ to: [{ email: "your-test-email@domain.com" }] }],
      from: { email: process.env.SENDGRID_FROM_EMAIL, name: process.env.SENDGRID_FROM_NAME || "Traxx Events" },
      subject: "SendGrid test from local",
      content: [{ type: "text/plain", value: "If you get this, SendGrid is working." }]
    });
    console.log("SendGrid sent:", res);
  } catch (err) {
    console.error("SendGrid error:", err?.response?.body || err);
  }
}

test();
