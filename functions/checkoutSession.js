import { onRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import Stripe from "stripe";
import { getFirestore } from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";

// Define the Stripe secret key as a secret parameter
const stripeSecretKey = defineSecret("STRIPE_SECRET_KEY");

/**
 * HTTP Cloud Function for creating Stripe Checkout Session
 * Requires authentication. Gets user's email, queries Firestore for organisationId,
 * and includes it in the checkout session metadata.
 * 
 * Expected request body (form data or JSON):
 * - productName: string (name of the product/service)
 * - amount: number (price in cents)
 * - currency: string (currency code, e.g., 'usd')
 * - quantity: number (quantity to purchase)
 * - successUrl: string (URL to redirect on success)
 * - cancelUrl: string (URL to redirect on cancel)
 * - userEmail: string (authenticated user's email)
 */
export const checkoutSession = onRequest(
    {
        secrets: [stripeSecretKey],
        cors: true // Enable CORS for web clients
    },
    async (req, res) => {
        try {
            // Initialize Stripe with the secret key
            const stripe = new Stripe(stripeSecretKey.value());
            const db = getFirestore();

            // Extract data from request body (works for both JSON and form data)
            const data = {
                ...req.query,
                ...req.body,
            };

            const {
                productName = 'Test Product',
                amount = '10000', // 100 USD in cents
                currency = 'usd',
                quantity = '1',
                successUrl = 'https://your-domain.com/success.html',
                cancelUrl = 'https://your-domain.com/cancel.html',
                userEmail,
            } = data;

            // Require user email
            if (!userEmail) {
                console.error('User email is required');
                return res.status(400).send('User email is required');
            }

            console.log('Looking up user with email:', userEmail);

            // Query Firestore to find user by email
            const usersRef = db.collection('users');
            const querySnapshot = await usersRef.where('email', '==', userEmail).limit(1).get();

            if (querySnapshot.empty) {
                console.error('No user found with email:', userEmail);
                return res.status(404).send('User not found');
            }

            const userDoc = querySnapshot.docs[0];
            const userData = userDoc.data();
            const organisationId = userData.organisationId;

            if (!organisationId) {
                console.error('User does not have an organisationId');
                return res.status(400).send('User does not have an organisation');
            }

            console.log('Found organisationId:', organisationId);

            // Convert to numbers if they're strings
            const amountInt = typeof amount === 'string' ? parseInt(amount) : amount;
            const quantityInt = typeof quantity === 'string' ? parseInt(quantity) : quantity;

            console.log('Creating checkout session with:', {
                productName,
                amount: amountInt,
                currency,
                quantity: quantityInt,
                successUrl,
                cancelUrl,
                userEmail,
                organisationId,
                method: req.method,
            });

            const session = await stripe.checkout.sessions.create({
                payment_method_types: ['card'],
                line_items: [
                    {
                        price_data: {
                            currency: currency,
                            product_data: {
                                name: productName,
                            },
                            unit_amount: amountInt,
                        },
                        quantity: quantityInt,
                    },
                ],
                mode: 'payment',
                success_url: successUrl,
                cancel_url: cancelUrl,
                metadata: {
                    organisationId: organisationId,
                    userEmail: userEmail,
                    userId: userData.userId || '',
                    credits: Math.floor(amountInt / 100), // Calculate credits based on amount
                },
                client_reference_id: organisationId, // Also set as reference for easy lookup
            });

            console.log('Checkout session created:', session.id, 'for organisation:', organisationId);
            res.status(303).redirect(session.url);
        } catch (err) {
            console.error('Error creating checkout session:', err);
            res.status(500).send('Internal Server Error: ' + err.message);
        }
    }
);
