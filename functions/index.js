/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

// functions/index.js

import { initializeApp, getApps } from "firebase-admin/app";

// Guard so we don't double-initialize if any module already called initializeApp()
if (!getApps().length) {
    initializeApp();
}

export { signupAdmin } from "./signupAdmin.js";
export { saveCompanyInfo } from "./saveCompanyInfo.js";
export { checkOrganisationInfo } from "./checkOrganisationInfo.js";
