import { HttpsError } from "firebase-functions/v2/https";

/**
 * Validates email format
 * @param {string} email - Email to validate
 * @return {boolean} True if valid email format
 */
export function isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
}

/**
 * Validates URL format
 * @param {string} url - URL to validate
 * @return {boolean} True if valid URL format
 */
export function isValidUrl(url) {
    try {
        const urlObj = new URL(url);
        return urlObj.protocol === "http:" || urlObj.protocol === "https:";
    } catch (error) {
        return false;
    }
}

/**
 * Validates phone number format (basic validation)
 * @param {string} phone - Phone number to validate
 * @return {boolean} True if valid phone format
 */
export function isValidPhone(phone) {
    // Basic phone validation - allows digits, spaces, dashes, parentheses, plus
    const phoneRegex = /^[\+]?[\d\s\-\(\)]{7,}$/;
    return phoneRegex.test(phone);
}

/**
 * Validates timezone format (IANA timezone identifier)
 * @param {string} timezone - Timezone to validate
 * @return {boolean} True if valid timezone format
 */
export function isValidTimezone(timezone) {
    try {
        // Try to create a date formatter with the timezone
        // This will throw an error if the timezone is invalid
        Intl.DateTimeFormat(undefined, { timeZone: timezone });
        return true;
    } catch (error) {
        return false;
    }
}

/**
 * Validates that a value is a non-empty string
 * @param {*} value - Value to validate
 * @param {string} fieldName - Name of the field for error messages
 * @return {void}
 * @throws {HttpsError} If validation fails
 */
export function validateRequiredString(value, fieldName) {
    if (!value) {
        throw new HttpsError(
            "invalid-argument",
            `${fieldName} is required.`
        );
    }
    if (typeof value !== "string") {
        throw new HttpsError(
            "invalid-argument",
            `${fieldName} must be a string.`
        );
    }
    if (value.trim().length === 0) {
        throw new HttpsError(
            "invalid-argument",
            `${fieldName} cannot be empty.`
        );
    }
}

/**
 * Validates password strength
 * @param {string} password - Password to validate
 * @return {boolean} True if password meets strength requirements
 */
export function isValidPassword(password) {
    // Password must be at least 8 characters long
    if (password.length < 8) {
        return false;
    }

    // Password must contain at least one uppercase letter
    if (!/[A-Z]/.test(password)) {
        return false;
    }

    // Password must contain at least one lowercase letter
    if (!/[a-z]/.test(password)) {
        return false;
    }

    // Password must contain at least one number
    if (!/\d/.test(password)) {
        return false;
    }

    // Password must contain at least one special character
    if (!/[!@#$%^&*(),.?":{}|<>]/.test(password)) {
        return false;
    }

    return true;
}

/**
 * Validates Firebase Cloud Storage path format
 * @param {string} path - Storage path to validate
 * @return {boolean} True if valid storage path format
 */
export function isValidFirebaseStoragePath(path) {
    // Expected format: uploads/1763244573603.jpg
    // Pattern: folder/filename.extension
    const storagePathRegex = /^[a-zA-Z0-9_\-\/]+\.[a-zA-Z0-9]{2,4}$/;

    // Check basic format
    if (!storagePathRegex.test(path)) {
        return false;
    }

    // Check for valid image extensions
    const validExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'svg'];
    const extension = path.toLowerCase().split('.').pop();

    return validExtensions.includes(extension);
}

/**
 * Gets password strength requirements as a string
 * @return {string} Password requirements description
 */
export function getPasswordRequirements() {
    return "Password must be at least 8 characters long and contain at least one uppercase letter, one lowercase letter, one number, and one special character (!@#$%^&*(),.?\":{}|<>).";
}