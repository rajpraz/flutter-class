import { onCall } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { UserRole } from "../types";
import { requireRole } from "../utils/auth";
import { invalidArgument, notFound } from "../utils/errors";

const VALID_ROLES: UserRole[] = ["buyer", "seller", "admin"];

interface SetUserRoleInput {
  targetUid: string;
  role: UserRole;
}

/**
 * Admin-only. Promotes/demotes any user to buyer/seller/admin. This is the
 * only sanctioned way to grant "admin" at all, and the only way to change a
 * role after signup. Sets the custom claim (source of truth for every rule
 * and function) and mirrors it to `users/{uid}.role` for the existing UI.
 */
export const setUserRole = onCall<SetUserRoleInput>(async (request) => {
  const { uid: adminUid } = requireRole(request, ["admin"]);

  const { targetUid, role } = request.data ?? {};
  if (!targetUid || typeof targetUid !== "string") {
    throw invalidArgument("targetUid is required.");
  }
  if (!VALID_ROLES.includes(role)) {
    throw invalidArgument(`role must be one of: ${VALID_ROLES.join(", ")}.`);
  }

  const db = admin.firestore();
  const userRef = db.collection("users").doc(targetUid);
  const userSnap = await userRef.get();
  if (!userSnap.exists) {
    throw notFound("That user doesn't exist.");
  }

  await admin.auth().setCustomUserClaims(targetUid, { role });
  await userRef.set(
    {
      role,
      roleChangedAt: admin.firestore.FieldValue.serverTimestamp(),
      roleChangedBy: adminUid,
    },
    { merge: true },
  );

  return { success: true, targetUid, role };
});
