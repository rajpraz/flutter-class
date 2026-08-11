import { onCall } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { requireRole } from "../utils/auth";
import { failedPrecondition, invalidArgument, notFound } from "../utils/errors";

interface RequestSellerUpgradeInput {
  shopName: string;
  phone: string;
  reason?: string;
}

/**
 * A signed-in buyer asks to become a seller. Does not grant anything by
 * itself — it just files `sellerApplications/{uid}` with status "pending"
 * for an admin to review via `approveSellerApplication` /
 * `rejectSellerApplication`. Buyers who signed up directly as a seller (the
 * existing signup flow still allows choosing "seller" at signup) don't need
 * this; it's for buyers upgrading later.
 */
export const requestSellerUpgrade = onCall<RequestSellerUpgradeInput>(async (request) => {
  const { uid } = requireRole(request, ["buyer"]);
  const { shopName, phone, reason } = request.data ?? {};
  if (!shopName?.trim() || !phone?.trim()) {
    throw invalidArgument("shopName and phone are required.");
  }

  const db = admin.firestore();
  const ref = db.collection("sellerApplications").doc(uid);
  const existing = await ref.get();
  if (existing.exists && existing.data()?.status === "pending") {
    throw failedPrecondition("You already have a pending seller application.");
  }

  await ref.set({
    uid,
    shopName: shopName.trim(),
    phone: phone.trim(),
    reason: (reason ?? "").trim(),
    status: "pending",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    reviewedAt: null,
    reviewedBy: null,
  });

  return { success: true };
});

interface ReviewSellerApplicationInput {
  applicantUid: string;
}

export const approveSellerApplication = onCall<ReviewSellerApplicationInput>(async (request) => {
  const { uid: adminUid } = requireRole(request, ["admin"]);
  const { applicantUid } = request.data ?? {};
  if (!applicantUid) throw invalidArgument("applicantUid is required.");

  const db = admin.firestore();
  const appRef = db.collection("sellerApplications").doc(applicantUid);
  const appSnap = await appRef.get();
  if (!appSnap.exists) throw notFound("Application not found.");

  await admin.auth().setCustomUserClaims(applicantUid, { role: "seller" });
  const batch = db.batch();
  batch.set(
    db.collection("users").doc(applicantUid),
    { role: "seller", roleChangedAt: admin.firestore.FieldValue.serverTimestamp(), roleChangedBy: adminUid },
    { merge: true },
  );
  batch.update(appRef, {
    status: "approved",
    reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
    reviewedBy: adminUid,
  });
  await batch.commit();

  return { success: true };
});

export const rejectSellerApplication = onCall<ReviewSellerApplicationInput & { reason?: string }>(
  async (request) => {
    const { uid: adminUid } = requireRole(request, ["admin"]);
    const { applicantUid, reason } = request.data ?? {};
    if (!applicantUid) throw invalidArgument("applicantUid is required.");

    const db = admin.firestore();
    const appRef = db.collection("sellerApplications").doc(applicantUid);
    const appSnap = await appRef.get();
    if (!appSnap.exists) throw notFound("Application not found.");

    await appRef.update({
      status: "rejected",
      rejectionReason: (reason ?? "").trim(),
      reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
      reviewedBy: adminUid,
    });

    return { success: true };
  },
);
