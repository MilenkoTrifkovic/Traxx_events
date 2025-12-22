import { HttpsError } from "firebase-functions/v2/https";
import {
    isValidEmail,
    isValidUrl,
    isValidPhone,
    isValidTimezone,
    validateRequiredString,
    isValidFirebaseStoragePath
} from "../utils/validationUtils.js";

/**
 * Validates organisation address object
 * @param {object} address - Address object to validate
 * @return {void}
 * @throws {HttpsError} If validation fails
 */
function validateAddress(address) {
    if (!address) {
        throw new HttpsError(
            "invalid-argument",
            "Address is required."
        );
    }

    if (typeof address !== "object" || Array.isArray(address)) {
        throw new HttpsError(
            "invalid-argument",
            "Address must be an object."
        );
    }

    // Required address fields
    const requiredAddressFields = ["street", "city", "state", "zip", "country"];

    for (const field of requiredAddressFields) {
        validateRequiredString(address[field], `Address ${field}`);
    }

    // Additional validation for specific fields
    if (address.zip && typeof address.zip === "string") {
        const zipRegex = /^[\w\s\-]{3,10}$/; // Basic zip/postal code format
        if (!zipRegex.test(address.zip.trim())) {
            throw new HttpsError(
                "invalid-argument",
                "Invalid zip/postal code format."
            );
        }
    }
}

/**
 * Validates company info data from Flutter app
 * @param {object} data - Company info data to validate
 * @return {void}
 * @throws {HttpsError} If validation fails
 */
export function validateCompanyInfo(data) {
    if (!data) {
        throw new HttpsError("invalid-argument", "No data provided.");
    }

    if (typeof data !== "object" || Array.isArray(data)) {
        throw new HttpsError(
            "invalid-argument",
            "Data must be an object."
        );
    }

    // Validate required string fields
    validateRequiredString(data.name, "Company name");
    validateRequiredString(data.phone, "Company phone");
    validateRequiredString(data.timezone, "Timezone");

    // Validate phone format
    if (!isValidPhone(data.phone.toString().trim())) {
        throw new HttpsError(
            "invalid-argument",
            "Invalid phone number format."
        );
    }

    // Validate timezone
    if (!isValidTimezone(data.timezone)) {
        throw new HttpsError(
            "invalid-argument",
            "Invalid timezone. Must be a valid IANA timezone identifier (e.g., 'America/New_York', 'Europe/London', 'Asia/Tokyo')."
        );
    }

    // Validate address object
    if (!data.address) {
        throw new HttpsError(
            "invalid-argument",
            "Address is required."
        );
    }

    if (typeof data.address !== "object" || Array.isArray(data.address)) {
        throw new HttpsError(
            "invalid-argument",
            "Address must be an object."
        );
    }

    // Validate required address fields
    validateRequiredString(data.address.street, "Street address");
    validateRequiredString(data.address.city, "City");
    validateRequiredString(data.address.state, "State");
    validateRequiredString(data.address.zip, "ZIP code");
    validateRequiredString(data.address.country, "Country");

    // Additional validation for zip code
    if (data.address.zip && typeof data.address.zip === "string") {
        const zipRegex = /^[\w\s\-]{3,10}$/; // Basic zip/postal code format
        if (!zipRegex.test(data.address.zip.trim())) {
            throw new HttpsError(
                "invalid-argument",
                "Invalid zip/postal code format."
            );
        }
    }

    // Validate optional currency field
    if (data.currency !== undefined && data.currency !== null) {
        if (typeof data.currency !== "string") {
            throw new HttpsError(
                "invalid-argument",
                "Currency must be a string."
            );
        }

        // Validate currency is a 3-letter ISO code
        const currencyRegex = /^[A-Z]{3}$/;
        if (data.currency.trim().length > 0 && !currencyRegex.test(data.currency.trim())) {
            throw new HttpsError(
                "invalid-argument",
                "Invalid currency format. Must be a 3-letter ISO code (e.g., 'USD', 'EUR', 'GBP')."
            );
        }
    }

    // Validate optional website field
    if (data.website !== undefined && data.website !== null) {
        if (typeof data.website !== "string") {
            throw new HttpsError(
                "invalid-argument",
                "Website must be a string."
            );
        }

        // Only validate if website is provided and not empty
        if (data.website.trim().length > 0 && !isValidUrl(data.website.trim())) {
            throw new HttpsError(
                "invalid-argument",
                "Invalid website URL format. Must start with http:// or https://"
            );
        }
    }

    // Validate optional logo field
    if (data.logo !== undefined && data.logo !== null) {
        if (typeof data.logo !== "string") {
            throw new HttpsError(
                "invalid-argument",
                "Logo path must be a string."
            );
        }

        // Only validate if logo path is provided and not empty
        if (data.logo.trim().length > 0 && !isValidFirebaseStoragePath(data.logo.trim())) {
            throw new HttpsError(
                "invalid-argument",
                "Invalid logo path format. Must be a valid Firebase Storage path like 'uploads/filename.jpg'"
            );
        }
    }

    // Check for unexpected fields (optional - helps catch typos)
    const allowedFields = [
        "name",
        "phone",
        "website",
        "address",
        "timezone",
        "currency",       // Currency ISO code (e.g., 'USD', 'EUR')
        "logo",
        "organisationId", // Allow this field but it will be overwritten
        "isDisabled",     // Allow from Flutter but will be overwritten
        "createdAt",      // Allow from Flutter but will be overwritten
        "modifiedDate"    // Allow from Flutter but will be overwritten
    ];

    for (const key in data) {
        if (!allowedFields.includes(key)) {
            throw new HttpsError(
                "invalid-argument",
                `Unexpected field: ${key}`
            );
        }
    }
}

/**
 * Validates complete organisation data
 * @param {object} data - Organisation data to validate
 * @return {void}
 * @throws {HttpsError} If validation fails
 */
export function validateOrganisationData(data) {
    if (!data) {
        throw new HttpsError("invalid-argument", "No data provided.");
    }

    if (typeof data !== "object" || Array.isArray(data)) {
        throw new HttpsError(
            "invalid-argument",
            "Data must be an object."
        );
    }

    // Validate required string fields
    validateRequiredString(data.name, "Organisation name");
    validateRequiredString(data.email, "Organisation email");

    // Validate email format
    if (!isValidEmail(data.email)) {
        throw new HttpsError(
            "invalid-argument",
            "Invalid email format."
        );
    }

    // Validate address
    validateAddress(data.address);

    // Validate required timezone field
    validateRequiredString(data.timezone, "Timezone");
    if (!isValidTimezone(data.timezone)) {
        throw new HttpsError(
            "invalid-argument",
            "Invalid timezone. Must be a valid IANA timezone identifier (e.g., 'America/New_York', 'Europe/London', 'Asia/Tokyo')."
        );
    }

    // Validate optional phone field
    if (data.phone !== undefined && data.phone !== null) {
        if (typeof data.phone !== "string") {
            throw new HttpsError(
                "invalid-argument",
                "Phone must be a string."
            );
        }

        if (data.phone.trim().length > 0 && !isValidPhone(data.phone.trim())) {
            throw new HttpsError(
                "invalid-argument",
                "Invalid phone number format."
            );
        }
    }

    // Validate optional website field
    if (data.website !== undefined && data.website !== null) {
        if (typeof data.website !== "string") {
            throw new HttpsError(
                "invalid-argument",
                "Website must be a string."
            );
        }

        // Only validate if website is provided and not empty
        if (data.website.trim().length > 0 && !isValidUrl(data.website.trim())) {
            throw new HttpsError(
                "invalid-argument",
                "Invalid website URL format. Must start with http:// or https://"
            );
        }
    }

    // Check for unexpected fields (optional - helps catch typos)
    const allowedFields = [
        "name",
        "email",
        "phone",
        "website",
        "address",
        "timezone",
        "createdAt",
    ];

    for (const key in data) {
        if (!allowedFields.includes(key)) {
            throw new HttpsError(
                "invalid-argument",
                `Unexpected field: ${key}`
            );
        }
    }
}