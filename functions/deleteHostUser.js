import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getAuth } from "firebase-admin/auth";
import { db } from "./admin.js";

async function requireAdminForOrg(request, organisationId) {
  if (!request.auth?.uid) throw new HttpsError("unauthenticated", "Sign in required.");

  const adminUid = request.auth.uid;
  const snap = await db.collection("users").doc(adminUid).get();
  if (!snap.exists) throw new HttpsError("permission-denied", "User profile not found.");

  const u = snap.data() || {};
  const role = (u.role || "").toString();

  const isSuper =
    role === "superAdmin" || role === "super_admin" || role === "superadmin";
  const isAdmin = role === "admin";
  const isHost = role === "host";

  // Allow superAdmin, admin, or host to delete host users
  if (!isSuper && !isAdmin && !isHost) {
    throw new HttpsError("permission-denied", "Only admins or hosts can delete other hosts.");
  }

  // SuperAdmin can delete hosts from any organisation
  if (isSuper) {
    return;
  }

  // Admin must match organisationId
  if (isAdmin) {
    const myOrg = (u.organisationId || "").toString();
    if (!myOrg || myOrg !== organisationId) {
      throw new HttpsError("permission-denied", "You can only delete hosts from your organisation.");
    }
    return;
  }

  // Host must be managed by the organisation
  if (isHost) {
    const managedByOrgIds = u.managedByOrgIds || [];
    if (!Array.isArray(managedByOrgIds) || !managedByOrgIds.includes(organisationId)) {
      throw new HttpsError("permission-denied", "You can only delete hosts from organisations that manage you.");
    }
    return;
  }
}

export const deleteHostUser = onCall(async (request) => {
  try {
    const { organisationId, hostUid, deleteAuth = false } = request.data || {};

    const orgId = (organisationId || "").toString().trim();
    const uid = (hostUid || "").toString().trim();

    if (!orgId) throw new HttpsError("invalid-argument", "organisationId is required");
    if (!uid) throw new HttpsError("invalid-argument", "hostUid is required");

    await requireAdminForOrg(request, orgId);

    // Ensure host exists in org directory (prevents deleting random uid)
    const orgHostRef = db.collection("organisations").doc(orgId).collection("hosts").doc(uid);
    const orgHostSnap = await orgHostRef.get();
    if (!orgHostSnap.exists) {
      throw new HttpsError("not-found", "Host not found in this organisation.");
    }

    // Ensure Firestore user is host
    const userRef = db.collection("users").doc(uid);
    const userSnap = await userRef.get();
    if (userSnap.exists) {
      const role = (userSnap.data()?.role || "").toString();
      if (role && role !== "host") {
        throw new HttpsError("failed-precondition", `User role is '${role}', not 'host'.`);
      }
    }

    // Optional: disable or delete Auth user
    const auth = getAuth();
    try {
      if (deleteAuth) {
        await auth.deleteUser(uid);
      } else {
        await auth.updateUser(uid, { disabled: true });
      }
    } catch (e) {
      // Don't fail deletion if auth user missing; continue with Firestore cleanup
      console.warn("Auth update/delete failed:", e);
    }

    // Delete Firestore docs
    await Promise.all([
      orgHostRef.delete(),
      userRef.delete(),
    ]);

    return { ok: true, deletedAuth: !!deleteAuth };
  } catch (err) {
    console.error("deleteHostUser error:", err);

    if (err && typeof err.code === "string") throw err;
    throw new HttpsError("internal", "deleteHostUser failed", {
      message: err?.message || String(err),
    });
  }
});
