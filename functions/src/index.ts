import * as admin from "firebase-admin";

admin.initializeApp();

export { onUserCreate } from "./roles/onUserCreate";
export { setUserRole } from "./roles/setUserRole";
export {
  requestSellerUpgrade,
  approveSellerApplication,
  rejectSellerApplication,
} from "./roles/sellerApplications";

export { createOrder } from "./orders/createOrder";
export { updateOrderStatus } from "./orders/updateOrderStatus";

export { verifyKhaltiPayment } from "./payments/khaltiVerify";
export { initiateEsewaPayment, verifyEsewaPayment } from "./payments/esewaVerify";
export { confirmCodPayment, markRefunded } from "./payments/codConfirm";

export { onOrderWrite } from "./notifications/onOrderWrite";
export { onLowStock } from "./notifications/lowStock";

export { createReview } from "./reviews/createReview";
export { deleteReview } from "./reviews/moderateReview";
