import { onRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import Stripe from "stripe";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

const stripeSecretKey = defineSecret("STRIPE_SECRET_KEY");

export const stripeWebhook = onRequest(
  {
    cors: true,
    secrets: [stripeSecretKey],
  },
  async (req, res) => {
    const stripe = new Stripe(stripeSecretKey.value());
    const db = getFirestore();

    if (req.method !== "POST") {
      return res.status(405).send("Method Not Allowed");
    }

    // **For testing without secret key**
    const event = req.body;

    try {
      switch (event.type) {
        case "checkout.session.completed":
          const session = event.data.object;
          console.log("Checkout session completed:", session.id);
          console.log("Session metadata:", session.metadata);
          console.log("Payment status:", session.payment_status);

          // Extract metadata from the session
          const organisationId = session.metadata?.organisationId || session.client_reference_id;
          const userEmail = session.metadata?.userEmail;
          const userId = session.metadata?.userId;
          const credits = session.metadata?.credits;

          if (!organisationId) {
            console.error("No organisationId found in session metadata");
            break;
          }

          // Get payment intent ID if available
          const paymentIntentId = session.payment_intent;
          
          // Retrieve the payment intent to get more details
          let paymentIntent = null;
          if (paymentIntentId) {
            paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);
          }

          // Create payment record in Firestore
          const paymentData = {
            // Transaction information
            transactionId: session.id, // Checkout session ID
            paymentIntentId: paymentIntentId || null,
            stripeCustomerId: session.customer || null,
            
            // Organisation and user information
            organisationId: organisationId,
            companyId: organisationId, // Alias for organisationId
            userEmail: userEmail || null,
            userId: userId || null,
            
            // Payment details
            amount: session.amount_total, // Total amount in cents
            currency: session.currency,
            paymentStatus: session.payment_status, // paid, unpaid, or no_payment_required
            credits: credits ? parseInt(credits) : null,
            
            // Subscription information (if applicable)
            subscriptionId: session.subscription || null,
            
            // Product information
            productName: session.metadata?.productName || 'Credits Purchase',
            
            // Payment method
            paymentMethod: paymentIntent?.payment_method || null,
            
            // Status flags
            isDisabled: false,
            
            // Timestamps
            createdAt: FieldValue.serverTimestamp(),
            modifiedAt: FieldValue.serverTimestamp(),
            
            // Stripe URLs
            receiptUrl: paymentIntent?.charges?.data?.[0]?.receipt_url || null,
            
            // Additional metadata
            metadata: session.metadata || {},
          };

          // Save to Firestore payments collection
          const paymentRef = await db.collection('payments').add(paymentData);
          
          console.log("✅ Payment record created:", paymentRef.id);
          console.log("Payment data:", JSON.stringify(paymentData, null, 2));

          // TODO: Update organisation's credit balance here
          // const orgRef = db.collection('organisations').doc(organisationId);
          // await orgRef.update({
          //   credits: FieldValue.increment(parseInt(credits)),
          //   modifiedAt: FieldValue.serverTimestamp()
          // });

          break;

        case "payment_intent.succeeded":
          const paymentIntentSucceeded = event.data.object;
          console.log("PaymentIntent succeeded:", paymentIntentSucceeded.id);
          console.log("Amount received:", paymentIntentSucceeded.amount_received);
          break;

        case "payment_method.attached":
          const paymentMethod = event.data.object;
          console.log("PaymentMethod attached:", paymentMethod.id);
          break;

        case "payment_intent.payment_failed":
          const paymentIntentFailed = event.data.object;
          console.log("❌ Payment failed:", paymentIntentFailed.id);
          console.log("Error:", paymentIntentFailed.last_payment_error?.message);
          break;

        default:
          console.log(`Unhandled event type ${event.type}`);
      }

      res.json({ received: true });
    } catch (error) {
      console.error("Error processing webhook:", error);
      res.status(500).json({ error: error.message });
    }
  }
);
