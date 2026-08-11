import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import { UserRole } from "../types";
import { logger } from "firebase-functions/v2";

/**
 * Fires when `users/{uid}` is first created (the client writes this doc
 * during signup — see lib/services/auth_service.dart `signUp` /
 * `signInWithGoogle`). This is the *only* place a role is ever granted from
 * a client-influenced value, and even then it is clamped to "buyer" or
 * "seller" — "admin" can never be set this way. From this point on,
 * firestore.rules blocks the client from ever writing `role` again; the
 * only way to change it is `setUserRole` (admin-only) or
 * `approveSellerApplication`, both of which run here with the Admin SDK and
 * set the *custom claim*, which is what every other function and the
 * Firestore rules' `isAdmin()`/`isSeller()` helpers actually trust.
 *
 * We mirror the same value back onto the Firestore doc (`role`) purely so
 * existing UI that reads `users/{uid}.role` keeps working without needing
 * an ID token refresh, but callers must never trust that field for
 * authorization — only the custom claim, exposed as `request.auth.token.role`
 * in callables and `request.auth.token.role` in security rules.
 */
export const onUserCreate = onDocumentCreated("users/{uid}", async (event) => {
  const snap = event.data;
  if (!snap) return;
  const uid = event.params.uid;
  const requestedRole = snap.data()?.role;
  const role: UserRole = requestedRole === "seller" ? "seller" : "buyer";

  await admin.auth().setCustomUserClaims(uid, { role });

  if (snap.data()?.role !== role) {
    await snap.ref.set({ role }, { merge: true });
  }

  logger.info(`Assigned role "${role}" to new user ${uid}`, { uid, role });
});
