import { onCall, HttpsError } from "firebase-functions/v2/https";
import { Timestamp, FieldValue } from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";
import { randomBytes } from "crypto";
import { db } from "./admin.js";

function normalizeEmail(email) {
  return (email || "").toString().trim();
}
function emailLower(email) {
  return normalizeEmail(email).toLowerCase();
}

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

  // Allow superAdmin, admin, or host to create host users
  if (!isSuper && !isAdmin && !isHost) {
    throw new HttpsError("permission-denied", "Only admins or hosts can create other hosts.");
  }

  // SuperAdmin can create hosts for any organisation
  if (isSuper) {
    return;
  }

  // Admin must match organisationId
  if (isAdmin) {
    const myOrg = (u.organisationId || "").toString();
    if (!myOrg || myOrg !== organisationId) {
      throw new HttpsError("permission-denied", "You can only create hosts for your organisation.");
    }
    return;
  }

  // Host must be managed by the organisation
  if (isHost) {
    const managedByOrgIds = u.managedByOrgIds || [];
    if (!Array.isArray(managedByOrgIds) || !managedByOrgIds.includes(organisationId)) {
      throw new HttpsError("permission-denied", "You can only create hosts for organisations that manage you.");
    }
    return;
  }
}

export const createHostUser = onCall(async (request) => {
  try {
    const {
      organisationId,
      email,
      name,
      address,
      country,
      isDisabled = false,
      sendEmail = false,
    } = request.data || {};

    const orgId = (organisationId || "").toString().trim();
    const emLower = (email || "").toString().trim().toLowerCase();
    const displayName = (name || "").toString().trim();
    const addr = (address || "").toString().trim();
    const ctry = (country || "").toString().trim();

    if (!orgId) throw new HttpsError("invalid-argument", "organisationId is required");
    if (!displayName) throw new HttpsError("invalid-argument", "name is required");
    if (!emLower || !emLower.includes("@"))
      throw new HttpsError("invalid-argument", "Valid email is required");

    await requireAdminForOrg(request, orgId);

    const auth = getAuth();

    let authUser;
    let created = false;

    try {
      authUser = await auth.getUserByEmail(emLower);
    } catch (e) {
      const tempPassword = randomBytes(12).toString("hex");
      authUser = await auth.createUser({
        email: emLower,
        password: tempPassword,
        displayName: displayName || undefined,
        disabled: !!isDisabled,
      });
      created = true;
    }

    const uid = authUser.uid;

    const userRef = db.collection("users").doc(uid);
    const userSnap = await userRef.get();

    if (userSnap.exists) {
      const existingRole = (userSnap.data()?.role || "").toString();
      if (existingRole && existingRole !== "host") {
        throw new HttpsError(
          "failed-precondition",
          `This email is already used by a non-host account (role: ${existingRole}).`
        );
      }
    }

    const now = Timestamp.now();

    await userRef.set(
      {
        userId: uid,
        email: emLower,
        emailLower: emLower,
        role: "host",
        isDisabled: !!isDisabled,
        name: displayName,
        ...(addr ? { address: addr } : {}),
        ...(ctry ? { country: ctry } : {}),
        managedByOrgIds: FieldValue.arrayUnion(orgId),
        modifiedAt: now,
        ...(userSnap.exists ? {} : { createdAt: now }),
      },
      { merge: true }
    );

    const orgHostRef = db
      .collection("organisations")
      .doc(orgId)
      .collection("hosts")
      .doc(uid);

    await orgHostRef.set(
      {
        hostUid: uid,
        email: emLower,
        emailLower: emLower,
        name: displayName,
        ...(addr ? { address: addr } : {}),
        ...(ctry ? { country: ctry } : {}),
        isDisabled: !!isDisabled,
        updatedAt: now,
        ...(created ? { createdAt: now } : {}),
      },
      { merge: true }
    );

    // sendEmail stays false for your Add Host flow
    return { uid, email: emLower, created, alreadyVerified: authUser.emailVerified === true };
    } catch (err) {
    console.error("createHostUser error:", err);

    // ✅ Do NOT rely on instanceof (can fail across bundles/ESM).
    const httpsCodes = new Set([
      "cancelled","unknown","invalid-argument","deadline-exceeded","not-found",
      "already-exists","permission-denied","resource-exhausted","failed-precondition",
      "aborted","out-of-range","unimplemented","internal","unavailable","data-loss","unauthenticated"
    ]);

    // 1) If it's already an HttpsError-like object, rethrow as-is
    if (err && typeof err.code === "string" && httpsCodes.has(err.code)) {
      throw err;
    }

    // 2) Map Firebase Auth errors to readable HttpsError codes
    const code = (err && err.code ? String(err.code) : "");
    const msg = (err && err.message ? String(err.message) : String(err));

    if (code.startsWith("auth/")) {
      if (code === "auth/email-already-exists") {
        throw new HttpsError("already-exists", "Email already exists.");
      }
      if (code === "auth/invalid-email") {
        throw new HttpsError("invalid-argument", "Invalid email.");
      }
      if (code === "auth/user-not-found") {
        throw new HttpsError("not-found", "User not found.");
      }
      // fallback for other auth errors
      throw new HttpsError("failed-precondition", msg);
    }

    // 3) Anything else -> internal, but include details so Flutter can show it
    throw new HttpsError("internal", "createHostUser failed", {
      rawCode: code,
      rawMessage: msg,
      stack: err?.stack || null,
    });
  }

});

