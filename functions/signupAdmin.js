import { onCall, HttpsError } from "firebase-functions/v2/https";
import logger from "firebase-functions/logger";
import { getAuth } from 'firebase-admin/auth';
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { validateUserCredentials } from "./validators/userCredentialValidator.js";

const auth = getAuth();
const db = getFirestore();

// User signup function with credential validation
export const signupAdmin = onCall(async (request) => {
    try {
        // Validate the user credentials (email and password)
        validateUserCredentials(request.data);

        // Create the user account with Firebase Auth
        const userRecord = await auth.createUser({
            email: request.data.email,
            password: request.data.password,
            emailVerified: false, // User will need to verify their email
        });

        // Store additional user data in Firestore
        await db.collection("users").add({
            userId: userRecord.uid,
            email: request.data.email,
            createdAt: FieldValue.serverTimestamp(),
            modifiedAt: FieldValue.serverTimestamp(),
            isDisabled: false,
        });

        logger.info(`User account created successfully: ${userRecord.uid}`);

        return {
            success: true,
            message: "User account created successfully",
            uid: userRecord.uid,
        };

    } catch (error) {
        logger.error("Error creating user account:", error);

        // If it's already an HttpsError (from validation), re-throw it
        if (error.code && error.message) {
            throw error;
        }

        // Handle Firebase Auth specific errors
        if (error.code === "auth/email-already-exists") {
            throw new HttpsError(
                "already-exists",
                "An account with this email already exists."
            );
        }

        if (error.code === "auth/weak-password") {
            throw new HttpsError(
                "invalid-argument",
                "Password is too weak."
            );
        }

        // Generic error for unexpected issues
        throw new HttpsError(
            "internal",
            "An error occurred while creating the user account."
        );
    }
});