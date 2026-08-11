import { CallableRequest } from "firebase-functions/v2/https";
import { UserRole } from "../types";
import { permissionDenied, unauthenticated } from "./errors";

/** Every callable in this project reads the caller's role from their
 * verified ID token custom claims (`request.auth.token.role`), never from a
 * client-supplied argument and never from the `users/{uid}` Firestore
 * document (which the client can otherwise write to). Custom claims are
 * only ever set server-side, by `setUserRole` / the auth-create trigger /
 * the admin bootstrap script — see functions/README.md. */

export function requireAuth(request: CallableRequest): string {
  const uid = request.auth?.uid;
  if (!uid) throw unauthenticated();
  return uid;
}

export function currentRole(request: CallableRequest): UserRole {
  const role = request.auth?.token?.role;
  return role === "seller" || role === "admin" ? role : "buyer";
}

export function requireRole(request: CallableRequest, allowed: UserRole[]): { uid: string; role: UserRole } {
  const uid = requireAuth(request);
  const role = currentRole(request);
  if (!allowed.includes(role)) {
    throw permissionDenied(`This action requires one of: ${allowed.join(", ")}.`);
  }
  return { uid, role };
}
