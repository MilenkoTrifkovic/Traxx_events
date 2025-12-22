import {initializeApp, getApps} from "firebase-admin/app";
import { setGlobalOptions } from "firebase-functions/v2";

setGlobalOptions({ timeoutSeconds: 120, memory: "256MB" });

if (!getApps().length) {
  initializeApp();
}

export {signupAdmin} from "./signupAdmin.js";
export {saveCompanyInfo} from "./saveCompanyInfo.js";
export {checkOrganisationInfo} from "./checkOrganisationInfo.js";
export { sendInvitations } from "./sendInvitationForEvent.js";
export { submitDemographics } from "./submitDemographics.js";
export { getSelectedMenuItemsForInvitation } from "./getSelectedMenuItemsForInvitation.js";
export { submitMenuSelection } from "./submitMenuSelection.js";
export { getEventAnalytics } from "./getEventAnalytics.js";