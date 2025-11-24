/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import { initializeApp } from 'firebase-admin/app';

// Import individual functions
import { signupAdmin } from "./signupAdmin.js";
import { saveCompanyInfo } from "./saveCompanyInfo.js";
import { checkOrganisationInfo } from "./checkOrganisationInfo.js";

// Initialize Firebase Admin
initializeApp();

// Export all functions
export { signupAdmin };
export { saveCompanyInfo };
export { checkOrganisationInfo };