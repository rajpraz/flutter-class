import { HttpsError } from "firebase-functions/v2/https";

/** Thin wrappers so call sites read as intent, and so every user-facing
 * message is one we've deliberately chosen to expose (never a raw
 * Firestore/Node error, which could leak internal details). */

export function unauthenticated(message = "You must be signed in."): HttpsError {
  return new HttpsError("unauthenticated", message);
}

export function permissionDenied(message = "You don't have permission to do this."): HttpsError {
  return new HttpsError("permission-denied", message);
}

export function invalidArgument(message: string): HttpsError {
  return new HttpsError("invalid-argument", message);
}

export function failedPrecondition(message: string): HttpsError {
  return new HttpsError("failed-precondition", message);
}

export function notFound(message: string): HttpsError {
  return new HttpsError("not-found", message);
}

export function internal(message = "Something went wrong. Please try again."): HttpsError {
  return new HttpsError("internal", message);
}
