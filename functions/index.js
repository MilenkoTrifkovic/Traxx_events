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
export { createSalesPersonAccount } from "./createSalesPersonAccount.js";
export { createHostUser } from "./createHostUser.js";
export { resendHostVerificationEmail } from "./resendHostVerificationEmail.js";
export { deleteHostUser } from "./deleteHostUser.js";
export { addCompanionToInvitation } from "./addCompanionToInvitation.js";
export { endpointSession } from "./endpointSession.js";
export { checkoutSession } from "./checkoutSession.js";
export { stripeWebhook } from "./stripeEndpoint.js";
export { getPaymentHistory } from "./getPaymentHistory.js";
export { createEvent } from "./createEvent.js";
export { submitCompanionAttendance } from "./submitCompanionAttendance.js";
