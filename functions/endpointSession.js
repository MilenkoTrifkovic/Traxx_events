import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import Stripe from "stripe";

// Define the Stripe secret key as a secret parameter
const stripeSecretKey = defineSecret("STRIPE_SECRET_KEY");

export const endpointSession = onCall(
  { secrets: [stripeSecretKey] },
  async (request) => {
    const { priceId, YOUR_DOMAIN = "http://localhost:4242" } = request.data;

    // if (!priceId) {
    //   throw new HttpsError(
    //     "invalid-argument",
    //     "Price ID is required"
    //   );
    // }

    const stripe = new Stripe(stripeSecretKey.value());

    const session = await stripe.checkout.sessions.create({
      line_items: [
        {
          price: priceId,
          quantity: 1,
        },
      ],
      mode: "payment",
      success_url: `${YOUR_DOMAIN}/success.html`,
      cancel_url: `${YOUR_DOMAIN}/cancel.html`,
    });

    return {
      url: session.url,
    };
  }
);
