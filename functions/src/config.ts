import { defineSecret, defineString } from "firebase-functions/params";

/**
 * Environment-specific configuration.
 *
 * Nothing here is a hardcoded secret. Values come from Firebase's
 * "params" mechanism, which is resolved at deploy time from either
 * `firebase functions:secrets:set` (for `defineSecret`, stored encrypted in
 * Secret Manager) or `.env.<project-alias>` files / deploy-time prompts (for
 * `defineString`). See functions/README.md for exactly what to set before
 * deploying.
 */

/** "development" | "staging" | "production". Controls which payment gateway
 * base URLs are used (sandbox vs live) and whether verbose debug logging is
 * emitted. Defaults to "development" so a misconfigured deploy fails safe
 * (sandbox endpoints, not live money movement). */
export const APP_ENV = defineString("APP_ENV", { default: "development" });

// --- Khalti ---
// Secret (server-side) key used to call Khalti's Epayment Lookup API to
// verify a payment actually happened, for the amount claimed, before an
// order is ever marked paid. Never the same as the publishable/public key
// used client-side.
export const KHALTI_SECRET_KEY = defineSecret("KHALTI_SECRET_KEY");

export function khaltiBaseUrl(env: string): string {
  // Khalti uses the same base URL for sandbox and live; sandbox vs live is
  // determined entirely by which secret key is configured. Kept as a
  // function (not a constant) so a future gateway change only touches this
  // file.
  void env;
  return "https://a.khalti.com/api/v2";
}

// --- eSewa ---
// eSewa v2 requires a merchant code (product code) and an HMAC secret used
// to both sign initiate requests and verify the signature eSewa returns.
export const ESEWA_MERCHANT_CODE = defineString("ESEWA_MERCHANT_CODE", { default: "EPAYTEST" });
export const ESEWA_SECRET_KEY = defineSecret("ESEWA_SECRET_KEY");

export function esewaStatusCheckUrl(env: string): string {
  return env === "production"
    ? "https://epay.esewa.com.np/api/epay/transaction/status"
    : "https://rc-epay.esewa.com.np/api/epay/transaction/status";
}

/** Admin bootstrap: a one-time shared secret used only by
 * scripts/setAdminClaim.ts (run locally with a service account, never
 * called from the app) to grant the very first admin account. Required
 * because there is no admin yet to call the normal `setUserRole` callable
 * with. Rotate/remove after first use. */
export const ADMIN_BOOTSTRAP_SECRET = defineSecret("ADMIN_BOOTSTRAP_SECRET");
