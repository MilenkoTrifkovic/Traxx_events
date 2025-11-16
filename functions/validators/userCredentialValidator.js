import { HttpsError } from "firebase-functions/v2/https";
import {
    isValidEmail,
    validateRequiredString,
    isValidPassword,
    getPasswordRequirements
} from "../utils/validationUtils.js";

/**
 * Validates user signup credential data
 * @param {object} data - User credential data to validate
 * @return {void}
 * @throws {HttpsError} If validation fails
 */
export function validateUserCredentials(data) {
    if (!data) {
        throw new HttpsError("invalid-argument", "No data provided.");
    }

    if (typeof data !== "object" || Array.isArray(data)) {
        throw new HttpsError(
            "invalid-argument",
            "Data must be an object."
        );
    }

    // Validate required email field
    validateRequiredString(data.email, "Email");

    // Validate email format
    if (!isValidEmail(data.email)) {
        throw new HttpsError(
            "invalid-argument",
            "Invalid email format."
        );
    }

    // Validate required password field
    validateRequiredString(data.password, "Password");

    // Validate password strength
    if (!isValidPassword(data.password)) {
        throw new HttpsError(
            "invalid-argument",
            `Invalid password. ${getPasswordRequirements()}`
        );
    }

    // Check for unexpected fields (helps catch typos)
    const allowedFields = ["email", "password"];

    for (const key in data) {
        if (!allowedFields.includes(key)) {
            throw new HttpsError(
                "invalid-argument",
                `Unexpected field: ${key}`
            );
        }
    }

    // Additional email validation - check for common issues
    const emailLower = data.email.toLowerCase().trim();

    // Check for consecutive dots
    if (emailLower.includes("..")) {
        throw new HttpsError(
            "invalid-argument",
            "Email cannot contain consecutive dots."
        );
    }

    // Check for dots at the beginning or end of local part
    const [localPart] = emailLower.split("@");
    if (localPart.startsWith(".") || localPart.endsWith(".")) {
        throw new HttpsError(
            "invalid-argument",
            "Email local part cannot start or end with a dot."
        );
    }

    // Check email length (RFC 5321 limits)
    if (emailLower.length > 254) {
        throw new HttpsError(
            "invalid-argument",
            "Email address is too long (maximum 254 characters)."
        );
    }

    if (localPart.length > 64) {
        throw new HttpsError(
            "invalid-argument",
            "Email local part is too long (maximum 64 characters)."
        );
    }
}
