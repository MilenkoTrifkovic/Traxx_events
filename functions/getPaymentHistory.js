import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";

/**
 * Callable Cloud Function to get payment history for an organisation
 * 
 * Expected data:
 * - organisationId: string (required) - The organisation ID to fetch payments for
 * 
 * Returns:
 * - Array of payment records sorted by creation date (newest first)
 */
export const getPaymentHistory = onCall(async (request) => {
    try {
        // Verify user is authenticated
        if (!request.auth) {
            throw new HttpsError('unauthenticated', 'User must be authenticated');
        }

        const db = getFirestore();
        
        // Get organisationId from request data
        const { organisationId } = request.data;
        
        if (!organisationId) {
            throw new HttpsError('invalid-argument', 'Missing required parameter: organisationId');
        }

        console.log(`📊 Fetching payment history for organisation: ${organisationId}`);

        // Query payments collection for this organisation
        const paymentsSnapshot = await db
            .collection('payments')
            .where('organisationId', '==', organisationId)
            .orderBy('createdAt', 'desc')
            .get();

        if (paymentsSnapshot.empty) {
            console.log(`No payments found for organisation: ${organisationId}`);
            return {
                success: true,
                payments: [],
                count: 0
            };
        }

        // Transform documents to plain objects
        const payments = paymentsSnapshot.docs.map(doc => {
            const data = doc.data();
            return {
                id: doc.id,
                transactionId: data.transactionId,
                organisationId: data.organisationId,
                events: data.events,
                amount: data.amount,
                currency: data.currency || 'usd',
                paymentStatus: data.paymentStatus,
                packageName: data.packageName,
                productName: data.productName,
                userEmail: data.userEmail,
                userId: data.userId,
                createdAt: data.createdAt?.toDate?.()?.toISOString() || data.createdAt,
                modifiedAt: data.modifiedAt?.toDate?.()?.toISOString() || data.modifiedAt,
                isDisabled: data.isDisabled || false,
                // Free credit fields
                isAssignedBySuperAdmin: data.isAssignedBySuperAdmin || false,
                isFreeCredit: data.isFreeCredit || false,
                assignedByEmail: data.assignedByEmail || null,
                assignedByName: data.assignedByName || null,
                note: data.note || null,
            };
        });

        console.log(`✅ Found ${payments.length} payment(s) for organisation: ${organisationId}`);

        return {
            success: true,
            payments: payments,
            count: payments.length
        };

    } catch (error) {
        console.error('❌ Error fetching payment history:', error);
        
        // Re-throw HttpsError as-is
        if (error instanceof HttpsError) {
            throw error;
        }
        
        throw new HttpsError('internal', error.message || 'Internal server error');
    }
});
