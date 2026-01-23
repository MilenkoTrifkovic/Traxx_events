import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { v4 as uuidv4 } from "uuid";

/**
 * Callable Cloud Function to create a new event with server-side validation
 * 
 * This function validates that the organisation has remaining event credits
 * before allowing event creation.
 * 
 * Expected data (object):
 * - organisationId: string (required)
 * - venueId: string (required)
 * - name: string (required)
 * - capacity: number (required)
 * - startDateTime: string (ISO date, required)
 * - endDateTime: string (ISO date, required)
 * - rsvpDeadline: string (ISO date, required)
 * - eventType: string (required)
 * - timezone: string (default: 'UTC')
 * - serviceType: string (default: 'buffet')
 * - ... other optional event fields
 * 
 * Returns:
 * - success: boolean
 * - event: the created event object (if successful)
 * - remainingEvents: number of events left after creation
 * 
 * Throws HttpsError on failure
 */
export const createEvent = onCall(
    {
        timeoutSeconds: 60,
        memory: "256MiB",
    },
    async (request) => {
        // Verify user is authenticated
        if (!request.auth) {
            throw new HttpsError(
                'unauthenticated',
                'User must be authenticated to create events.'
            );
        }

        const eventData = request.data;

        // ============================================
        // VALIDATION - Required fields
        // ============================================
        const requiredFields = [
            'organisationId',
            'venueId', 
            'name',
            'capacity',
            'startDateTime',
            'endDateTime',
            'rsvpDeadline',
            'eventType'
        ];

        const missingFields = requiredFields.filter(field => !eventData[field]);
        if (missingFields.length > 0) {
            throw new HttpsError(
                'invalid-argument',
                `Missing required fields: ${missingFields.join(', ')}`
            );
        }

        try {
            const db = getFirestore();
            const organisationId = eventData.organisationId;
            console.log(`🔵 Creating event for organisation: ${organisationId}`);
            console.log(`🔵 User: ${request.auth.uid} (${request.auth.token.email})`);

            // ============================================
            // CHECK EVENTS BALANCE
            // ============================================
            
            // Get total purchased events from payments
            const paymentsSnapshot = await db
                .collection('payments')
                .where('organisationId', '==', organisationId)
                .get();

            let totalPurchasedEvents = 0;
            paymentsSnapshot.docs.forEach(doc => {
                const data = doc.data();
                const status = (data.paymentStatus || '').toLowerCase();
                // Only count completed payments
                if (status === 'paid' || status === 'complete' || status === 'completed' || status === 'succeeded') {
                    totalPurchasedEvents += (data.events || 0);
                }
            });

            console.log(`📊 Total purchased events: ${totalPurchasedEvents}`);

            // Get total used events (current event count)
            const eventsSnapshot = await db
                .collection('events')
                .where('organisationId', '==', organisationId)
                .get();

            const totalUsedEvents = eventsSnapshot.size;
            console.log(`📊 Total used events: ${totalUsedEvents}`);

            // Calculate remaining events
            const remainingEvents = totalPurchasedEvents - totalUsedEvents;
            console.log(`📊 Remaining events before creation: ${remainingEvents}`);

            // Check if user has remaining events
            if (remainingEvents <= 0) {
                console.log(`❌ No events remaining for organisation: ${organisationId}`);
                throw new HttpsError(
                    'resource-exhausted',
                    'No event credits remaining. Please purchase more events.',
                    {
                        purchasedEvents: totalPurchasedEvents,
                        usedEvents: totalUsedEvents,
                        remainingEvents: 0
                    }
                );
            }

            // ============================================
            // GENERATE UNIQUE INVITATION CODE
            // ============================================
            const generateInvitationCode = async () => {
                const characters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Exclude confusing chars
                const codeLength = 8;
                let attempts = 0;
                const maxAttempts = 10;

                while (attempts < maxAttempts) {
                    let code = '';
                    for (let i = 0; i < codeLength; i++) {
                        code += characters.charAt(Math.floor(Math.random() * characters.length));
                    }

                    // Check if code already exists
                    const existingEvent = await db
                        .collection('events')
                        .where('invitationCode', '==', code)
                        .limit(1)
                        .get();

                    if (existingEvent.empty) {
                        return code;
                    }
                    attempts++;
                }
                throw new HttpsError('internal', 'Failed to generate unique invitation code');
            };

            const invitationCode = eventData.invitationCode || await generateInvitationCode();

            // ============================================
            // CREATE EVENT DOCUMENT
            // ============================================
            const eventId = eventData.eventId || uuidv4();

            // Parse dates
            const startDateTime = new Date(eventData.startDateTime);
            const endDateTime = new Date(eventData.endDateTime);
            const rsvpDeadline = new Date(eventData.rsvpDeadline);

            // Build event document
            const eventDoc = {
                eventId: eventId,
                organisationId: organisationId,
                venueId: eventData.venueId,
                name: eventData.name,
                address: eventData.address || '',
                capacity: parseInt(eventData.capacity) || 0,
                startDateTime: startDateTime,
                endDateTime: endDateTime,
                rsvpDeadline: rsvpDeadline,
                eventType: eventData.eventType,
                timezone: eventData.timezone || 'UTC',
                serviceType: eventData.serviceType || 'buffet',
                status: eventData.status || 'draft',
                invitationCode: invitationCode,
                
                // Optional fields
                description: eventData.description || null,
                dressCode: eventData.dressCode || null,
                plannerEmail: eventData.plannerEmail || null,
                specialNotes: eventData.specialNotes || null,
                hideHostInfo: eventData.hideHostInfo || false,
                maxInviteByGuest: parseInt(eventData.maxInviteByGuest) || 0,
                coverImageUrl: eventData.coverImageUrl || null,
                
                // Location (if provided)
                location: eventData.location ? {
                    latitude: eventData.location.latitude,
                    longitude: eventData.location.longitude
                } : null,

                // Menu/categories
                selectableMenuCategories: eventData.selectableMenuCategories || [],
                selectedMenus: eventData.selectedMenus || [],
                selectedMenuId: eventData.selectedMenuId || null,
                selectedMenuItemIds: eventData.selectedMenuItemIds || [],
                selectedDemographicQuestionSetId: eventData.selectedDemographicQuestionSetId || null,

                // Invitation letter
                invitationLetterPath: eventData.invitationLetterPath || null,
                invitationLetterUrl: eventData.invitationLetterUrl || null,

                // Metadata
                isDisabled: false,
                createdAt: FieldValue.serverTimestamp(),
                updatedAt: FieldValue.serverTimestamp(),
                
                // Track who created the event
                createdBy: request.auth.uid,
            };

            // Save to Firestore
            await db.collection('events').doc(eventId).set(eventDoc);

            console.log(`✅ Event created successfully: ${eventId}`);
            console.log(`📊 Remaining events after creation: ${remainingEvents - 1}`);

            // Return success response
            return {
                success: true,
                event: {
                    ...eventDoc,
                    createdAt: new Date().toISOString(),
                    updatedAt: new Date().toISOString(),
                    startDateTime: startDateTime.toISOString(),
                    endDateTime: endDateTime.toISOString(),
                    rsvpDeadline: rsvpDeadline.toISOString(),
                },
                remainingEvents: remainingEvents - 1,
                message: 'Event created successfully'
            };

        } catch (error) {
            console.error('❌ Error creating event:', error);
            
            // Re-throw HttpsError as-is
            if (error instanceof HttpsError) {
                throw error;
            }
            
            // Wrap other errors
            throw new HttpsError(
                'internal',
                error.message || 'Internal server error'
            );
        }
    }
);
