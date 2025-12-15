import {initializeApp, getApps} from "firebase-admin/app";

if (!getApps().length) {
  initializeApp();
}

export {signupAdmin} from "./signupAdmin.js";
export {saveCompanyInfo} from "./saveCompanyInfo.js";
export {checkOrganisationInfo} from "./checkOrganisationInfo.js";
export {sendInvitations} from "./sendInvitationForEvent.js";
