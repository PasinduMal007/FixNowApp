import * as admin from "firebase-admin";
import express, {
  type NextFunction,
  type Request,
  type Response,
} from "express";
import cors from "cors";
import {onRequest} from "firebase-functions/v2/https";

admin.initializeApp();

const app = express();

app.use(cors({origin: true}));
app.use(express.json());

type AuthedRequest = Request & {
  uid?: string;
  token?: admin.auth.DecodedIdToken;
};

async function verifyFirebaseToken(
  req: AuthedRequest,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const header = req.headers.authorization ?? "";
    const match = header.match(/^Bearer (.+)$/);

    if (!match) {
      res
        .status(401)
        .json({ok: false, message: "Missing Authorization Bearer token"});
      return;
    }

    const idToken = match[1];
    const decoded = await admin.auth().verifyIdToken(idToken);

    req.uid = decoded.uid;
    req.token = decoded;

    next();
    return;
  } catch (_err) {
    res.status(401).json({ok: false, message: "Invalid or expired token"});
    return;
  }
}

async function getRoleAndProfile(
  uid: string,
): Promise<{
  role: "customer" | "worker" | null;
  profile: Record<string, unknown> | null;
}> {
  const db = admin.database();

  const customerSnap = await db.ref(`users/customers/${uid}`).get();
  if (customerSnap.exists()) {
    const profile = (customerSnap.val() ?? {}) as Record<string, unknown>;
    const roleValue = profile["role"];
    const role = roleValue === "customer" ? "customer" : "customer";
    return {role, profile};
  }

  const workerSnap = await db.ref(`users/workers/${uid}`).get();
  if (workerSnap.exists()) {
    const profile = (workerSnap.val() ?? {}) as Record<string, unknown>;
    const roleValue = profile["role"];
    const role = roleValue === "worker" ? "worker" : "worker";
    return {role, profile};
  }

  return {role: null, profile: null};
}

app.post(
  "/auth/login-info",
  verifyFirebaseToken,
  async (req: AuthedRequest, res: Response) => {
    try {
      const uid = req.uid;
      if (!uid) {
        res.status(401).json({ok: false, message: "Unauthenticated"});
        return;
      }

      const expectedRoleRaw = (
        req.body as Record<string, unknown> | undefined
      )?.["expectedRole"];
      const expectedRole =
        expectedRoleRaw === "customer" || expectedRoleRaw === "worker" ?
          expectedRoleRaw :
          null;

      const result = await getRoleAndProfile(uid);

      if (!result.role || !result.profile) {
        res
          .status(404)
          .json({ok: false, message: "No user profile found in database"});
        return;
      }

      if (expectedRole && result.role !== expectedRole) {
        res
          .status(403)
          .json({
            ok: false,
            message: `This account is not a ${expectedRole} account.`,
          });
        return;
      }

      res.json({
        ok: true,
        uid,
        role: result.role,
        profile: result.profile,
      });
    } catch (_e) {
      res.status(500).json({ok: false, message: "Server error"});
    }
  },
);

app.post(
  "/customer/profile/update",
  verifyFirebaseToken,
  async (req: AuthedRequest, res: Response) => {
    const uid = req.uid;
    if (!uid) {
      res.status(401).json({ok: false, message: "Unauthenticated"});
      return;
    }

    const body = (req.body ?? {}) as Record<string, unknown>;

    const fullName =
      typeof body.fullName === "string" ? body.fullName.trim() : "";
    const email = typeof body.email === "string" ? body.email.trim() : "";
    const phoneNumber =
      typeof body.phoneNumber === "string" ? body.phoneNumber.trim() : "";
    const locationText =
      typeof body.locationText === "string" ? body.locationText.trim() : "";
    const dob = typeof body.dob === "string" ? body.dob.trim() : "";

    // Validate (mirror your RTDB rules)
    if (fullName.length < 2 || fullName.length > 100) {
      res
        .status(400)
        .json({ok: false, message: "fullName must be 2 to 100 characters."});
      return;
    }

    if (email && !/^[^@]+@[^@]+\.[^@]+$/.test(email)) {
      res.status(400).json({ok: false, message: "Invalid email format."});
      return;
    }

    if (phoneNumber && !/^[0-9]{9}$/.test(phoneNumber)) {
      res
        .status(400)
        .json({ok: false, message: "phoneNumber must be exactly 9 digits."});
      return;
    }

    if (
      locationText &&
      (locationText.length < 2 || locationText.length > 120)
    ) {
      res
        .status(400)
        .json({
          ok: false,
          message: "locationText must be 2 to 120 characters.",
        });
      return;
    }

    if (
      dob &&
      !/^(19|20)[0-9]{2}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$/.test(dob)
    ) {
      res.status(400).json({ok: false, message: "dob must be YYYY-MM-DD."});
      return;
    }

    const db = admin.database();
    const ref = db.ref(`users/customers/${uid}`);

    // Ensure profile exists and role is customer
    const snap = await ref.get();
    if (!snap.exists()) {
      res
        .status(404)
        .json({ok: false, message: "Customer profile not found."});
      return;
    }

    const current = snap.val() as Record<string, unknown>;
    if (current.role !== "customer" || current.uid !== uid) {
      res.status(403).json({ok: false, message: "Not a customer profile."});
      return;
    }

    const updates: Record<string, unknown> = {
      fullName,
      locationText,
    };

    if (email) updates.email = email;
    if (phoneNumber) updates.phoneNumber = phoneNumber;
    if (dob) updates.dob = dob;

    await ref.update(updates);

    const updatedSnap = await ref.get();
    res.json({ok: true, profile: updatedSnap.val()});
  },
);

export const api = onRequest({region: "asia-southeast1"}, app);
