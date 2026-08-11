#!/usr/bin/env node
/**
 * One-time bootstrap for the very first admin account.
 *
 * There's a chicken-and-egg problem: `setUserRole` (the normal way to grant
 * "admin") requires the caller to already be an admin. This script breaks
 * that cycle by using a service account key directly, run locally by you —
 * never deployed, never callable from the app.
 *
 * Usage:
 *   1. Firebase Console -> Project settings -> Service accounts ->
 *      "Generate new private key". Save it outside version control, e.g.
 *      functions/serviceAccountKey.json (already gitignored).
 *   2. The target user must already exist (sign up normally in the app
 *      first, as a buyer or seller).
 *   3. node scripts/setAdminClaim.js <uid> ./serviceAccountKey.json
 *   4. Delete/revoke the downloaded key once you're done if you don't need
 *      it for anything else.
 */
const admin = require("firebase-admin");

const [, , uid, keyPath] = process.argv;

if (!uid || !keyPath) {
  console.error("Usage: node scripts/setAdminClaim.js <uid> <path-to-service-account-key.json>");
  process.exit(1);
}

const serviceAccount = require(require("path").resolve(keyPath));
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

async function main() {
  await admin.auth().setCustomUserClaims(uid, { role: "admin" });
  await admin.firestore().collection("users").doc(uid).set(
    { role: "admin", roleChangedAt: admin.firestore.FieldValue.serverTimestamp(), roleChangedBy: "bootstrap-script" },
    { merge: true },
  );
  console.log(`Granted admin to ${uid}. They must sign out and back in (or refresh their ID token) for it to take effect.`);
  process.exit(0);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
