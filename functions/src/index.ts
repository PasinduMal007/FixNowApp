import * as admin from "firebase-admin";
import express, {
  type NextFunction,
  type Request,
  type Response,
} from "express";
import cors from "cors";
import {onRequest, onCall, HttpsError} from "firebase-functions/v2/https";
import {onValueCreated} from "firebase-functions/v2/database";

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

async function getRoleAndProfile(uid: string): Promise<{
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

function nowIso(): string {
  return new Date().toISOString();
}

async function createNotification(params: {
  toUid: string;
  type: string;
  title: string;
  message: string;
  bookingId: string;
}) {
  const db = admin.database();
  const nRef = db.ref(`notifications/${params.toUid}`).push();
  const id = nRef.key;
  if (!id) throw new Error("Failed to create notification id");

  await nRef.set({
    notificationId: id,
    type: params.type,
    title: params.title,
    message: params.message,
    bookingId: params.bookingId,
    isRead: false,
    timestamp: admin.database.ServerValue.TIMESTAMP,
    createdAtIso: nowIso(),
  });

  return id;
}

async function requireBooking(bookingId: string) {
  const db = admin.database();
  const snap = await db.ref(`bookings/${bookingId}`).get();
  if (!snap.exists()) throw new Error("Booking not found");
  const booking = (snap.val() ?? {}) as Record<string, any>;
  return {db, booking};
}

function requireString(v: any, field: string): string {
  const s = (v ?? "").toString().trim();
  if (!s) throw new Error(`${field} is required`);
  return s;
}

function requireNumber(v: any, field: string): number {
  const n = Number(v);
  if (!Number.isFinite(n)) throw new Error(`${field} must be a number`);
  return n;
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
        res.status(403).json({
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
      res.status(400).json({
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

app.post(
  "/customer/location/update",
  verifyFirebaseToken,
  async (req: AuthedRequest, res: Response) => {
    const uid = req.uid;
    if (!uid) {
      res.status(401).json({ok: false, message: "Unauthenticated"});
      return;
    }

    const body = (req.body ?? {}) as Record<string, unknown>;
    const locationText =
      typeof body.locationText === "string" ? body.locationText.trim() : "";

    if (locationText.length < 2 || locationText.length > 120) {
      res.status(400).json({
        ok: false,
        message: "locationText must be 2 to 120 characters.",
      });
      return;
    }

    const db = admin.database();
    const ref = db.ref(`users/customers/${uid}`);

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

    await ref.update({locationText});

    res.json({ok: true, locationText});
  },
);

app.post(
  "/worker/profile/update",
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
    const profession =
      typeof body.profession === "string" ? body.profession.trim() : "";
    const aboutMe = typeof body.aboutMe === "string" ? body.aboutMe.trim() : "";

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
      res.status(400).json({
        ok: false,
        message: "locationText must be 2 to 120 characters.",
      });
      return;
    }

    // Optional: add your own worker rule validations
    if (profession && (profession.length < 2 || profession.length > 80)) {
      res
        .status(400)
        .json({ok: false, message: "profession must be 2 to 80 characters."});
      return;
    }

    if (aboutMe && aboutMe.length > 500) {
      res
        .status(400)
        .json({ok: false, message: "aboutMe must be <= 500 characters."});
      return;
    }

    const db = admin.database();
    const ref = db.ref(`users/workers/${uid}`);

    const snap = await ref.get();
    if (!snap.exists()) {
      res.status(404).json({ok: false, message: "Worker profile not found."});
      return;
    }

    const current = snap.val() as Record<string, unknown>;
    if (current.role !== "worker" || current.uid !== uid) {
      res.status(403).json({ok: false, message: "Not a worker profile."});
      return;
    }

    const updates: Record<string, unknown> = {
      fullName,
    };

    if (email) updates.email = email;
    if (phoneNumber) updates.phoneNumber = phoneNumber;
    if (locationText) updates.locationText = locationText;
    if (profession) updates.profession = profession;
    if (aboutMe) updates.aboutMe = aboutMe;

    await ref.update(updates);

    const updatedSnap = await ref.get();

    res.json({ok: true, profile: updatedSnap.val()});
  },
);

type CreateBookingRequestInput = {
  workerId: string;
  serviceName: string;
  locationText: string;
  problemDescription: string;
  requestNote?: string;
  scheduledDate?: string;
  scheduledTime?: string;
  scheduledAt?: number;
  dateMode?: string;
};

function asCleanString(v: unknown, maxLen: number): string {
  if (typeof v !== "string") return "";
  const s = v.trim();
  if (!s) return "";
  return s.length > maxLen ? s.slice(0, maxLen) : s;
}

export const createBookingRequest = onCall(
  {region: "asia-southeast1"}, // keep region consistent with your other exports
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }

    const uid = request.auth.uid;
    const data = request.data as CreateBookingRequestInput;

    const workerId = asCleanString(data.workerId, 128);
    const serviceName = asCleanString(data.serviceName, 120);
    const locationText = asCleanString(data.locationText, 200);
    const problemDescription = asCleanString(data.problemDescription, 5000);
    const requestNote = asCleanString(data.requestNote ?? "", 5000);
    const scheduledDate = asCleanString(data.scheduledDate ?? "", 20);
    const scheduledTime = asCleanString(data.scheduledTime ?? "", 10);
    const dateMode = asCleanString(data.dateMode ?? "", 20);

    const scheduledAtRaw = data.scheduledAt;
    const scheduledAt =
      typeof scheduledAtRaw === "number" && Number.isFinite(scheduledAtRaw) ?
        scheduledAtRaw :
        null;

    // Basic format checks (optional but recommended)
    if (scheduledDate && !/^\d{4}-\d{2}-\d{2}$/.test(scheduledDate)) {
      throw new HttpsError(
        "invalid-argument",
        "scheduledDate must be YYYY-MM-DD.",
      );
    }
    if (scheduledTime && !/^\d{2}:\d{2}$/.test(scheduledTime)) {
      throw new HttpsError("invalid-argument", "scheduledTime must be HH:mm.");
    }
    if (scheduledAt !== null && scheduledAt <= 0) {
      throw new HttpsError(
        "invalid-argument",
        "scheduledAt must be a positive number.",
      );
    }

    if (!workerId) {
      throw new HttpsError("invalid-argument", "workerId is required.");
    }
    if (!serviceName) {
      throw new HttpsError("invalid-argument", "serviceName is required.");
    }
    if (!locationText) {
      throw new HttpsError("invalid-argument", "locationText is required.");
    }
    if (!problemDescription) {
      throw new HttpsError(
        "invalid-argument",
        "problemDescription is required.",
      );
    }

    const db = admin.database();

    const customerSnap = await db.ref(`users/customers/${uid}`).get();
    const customer = customerSnap.val() ?? {};
    const customerName = String(customer.fullName ?? "Customer");

    // Optional safety: verify worker exists (prevents bad IDs)
    const workerSnap = await db.ref(`users/workers/${workerId}`).get();
    if (!workerSnap.exists()) {
      throw new HttpsError("not-found", "Worker not found.");
    }

    const bookingRef = db.ref("bookings").push();
    const bookingId = bookingRef.key;
    if (!bookingId) {
      throw new HttpsError("internal", "Failed to generate bookingId.");
    }

    // Use numeric timestamps to satisfy your rules (isNumber())
    const now = Date.now();

    const booking = {
      bookingId,
      customerId: uid,
      customerName,
      workerId,
      serviceName,
      locationText,
      problemDescription,
      scheduledDate: scheduledDate || null,
      scheduledTime: scheduledTime || null,
      scheduledAt: scheduledAt ?? null,
      dateMode: dateMode || null,
      status: "pending",
      createdAt: now,
      updatedAt: now,
      quotationRequest: {
        requestedAt: now,
        ...(requestNote ? {requestNote} : {}),
      },
    };

    // Create notification id and write in same update
    const notificationRef = db.ref(`notifications/${workerId}`).push();
    const notificationId = notificationRef.key;

    const updates: Record<string, unknown> = {
      [`bookings/${bookingId}`]: booking,

      // You can keep these even if your onBookingCreateIndexUsers also does it.
      // It won't hurt, and it makes indexing immediate.
      [`userBookings/customers/${uid}/${bookingId}`]: true,
      [`userBookings/workers/${workerId}/${bookingId}`]: true,
    };

    if (notificationId) {
      updates[`notifications/${workerId}/${notificationId}`] = {
        id: notificationId, // matches your RTDB rule field name
        timestamp: now, // number
        isRead: false, // boolean
        type: "booking_request", // string
        title: "New booking request", // string
        message: `You have a new request for ${serviceName}.`,
        bookingId, // string
      };
    }

    await db.ref().update(updates);

    return {bookingId};
  },
);

export const attachBookingPhotos = onCall(
  {region: "asia-southeast1"},
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }

    const uid = request.auth.uid;

    const bookingId = String(request.data?.bookingId ?? "").trim();
    const urlsRaw = request.data?.photoUrls;

    if (!bookingId) {
      throw new HttpsError("invalid-argument", "bookingId is required.");
    }

    if (!Array.isArray(urlsRaw)) {
      throw new HttpsError("invalid-argument", "photoUrls must be an array.");
    }

    const cleaned = urlsRaw
      .map((u) => (typeof u === "string" ? u.trim() : ""))
      .filter((u) => u.length > 0);

    if (cleaned.length === 0) {
      throw new HttpsError("invalid-argument", "photoUrls is empty.");
    }

    if (cleaned.length > 3) {
      throw new HttpsError("invalid-argument", "Maximum 3 photos allowed.");
    }

    for (const u of cleaned) {
      if (u.length > 1200) {
        throw new HttpsError("invalid-argument", "A photo URL is too long.");
      }
      if (!/^https?:\/\//i.test(u)) {
        throw new HttpsError("invalid-argument", "Invalid photo URL.");
      }
    }

    const db = admin.database();
    const bookingRef = db.ref(`bookings/${bookingId}`);
    const snap = await bookingRef.get();

    if (!snap.exists()) {
      throw new HttpsError("not-found", "Booking not found.");
    }

    const booking = (snap.val() ?? {}) as Record<string, any>;

    if (String(booking.customerId ?? "") !== uid) {
      throw new HttpsError("permission-denied", "Not your booking.");
    }

    // If you want to allow uploads only while pending
    if (String(booking.status ?? "") !== "pending") {
      throw new HttpsError("failed-precondition", "Booking is not pending.");
    }

    const now = Date.now();

    // ✅ Indexed map format that matches your RTDB rules: "0","1","2"
    const photosMap: Record<string, string> = {};
    cleaned.forEach((url, idx) => {
      photosMap[String(idx)] = url;
    });

    const photosUpdate: Record<string, any> = {
      "photos/0": cleaned[0] ?? null,
      "photos/1": cleaned[1] ?? null,
      "photos/2": cleaned[2] ?? null,
      "updatedAt": now,
    };

    await bookingRef.update(photosUpdate);

    return {ok: true, count: cleaned.length};
  },
);

export const api = onRequest({region: "asia-southeast1"}, app);

export const onBookingCreateIndexUsers = onValueCreated(
  {region: "asia-southeast1", ref: "/bookings/{bookingId}"},
  async (event) => {
    const bookingId = (event.params as { bookingId: string }).bookingId;

    const booking = event.data.val() as Record<string, any> | null;
    if (!booking) return;

    const workerId = String(booking.workerId ?? "").trim();
    const customerId = String(booking.customerId ?? "").trim();

    if (!workerId || !customerId) {
      console.error("Booking missing workerId/customerId", {
        bookingId,
        workerId,
        customerId,
      });
      return;
    }

    const db = admin.database();

    // If indexes already exist, do nothing.
    // (Prevents unnecessary writes if you also write indexes in your HTTP endpoint.)
    const [workerIndexSnap, customerIndexSnap] = await Promise.all([
      db.ref(`userBookings/workers/${workerId}/${bookingId}`).get(),
      db.ref(`userBookings/customers/${customerId}/${bookingId}`).get(),
    ]);

    if (workerIndexSnap.exists() && customerIndexSnap.exists()) {
      return;
    }

    const updates: Record<string, any> = {};

    if (!workerIndexSnap.exists()) {
      updates[`userBookings/workers/${workerId}/${bookingId}`] = true;
    }
    if (!customerIndexSnap.exists()) {
      updates[`userBookings/customers/${customerId}/${bookingId}`] = true;
    }

    await db.ref().update(updates);
  },
);

export const onChatMessageCreate = onValueCreated(
  {region: "asia-southeast1", ref: "/chatMessages/{threadId}/{msgId}"},
  async (event) => {
    const {threadId} = event.params as { threadId: string; msgId: string };

    const msg = event.data.val() as {
      senderId: string;
      text: string;
      createdAt: number;
      type?: string;
    } | null;

    if (!msg || !msg.senderId || !msg.text) return;

    const db = admin.database();

    const threadRef = db.ref(`/chatThreads/${threadId}`);
    const threadSnap = await threadRef.get();
    if (!threadSnap.exists()) return;

    const thread = threadSnap.val() as {
      participants?: Record<string, boolean>;
    };

    const participants = thread.participants || {};
    const senderUid = String(msg.senderId);

    const uids = Object.keys(participants).filter(
      (u) => participants[u] === true,
    );
    if (uids.length < 2) return;

    const receiverUid = uids.find((u) => u !== senderUid);
    if (!receiverUid) return;

    const text = String(msg.text).trim();
    const createdAt = Number(msg.createdAt) || Date.now();

    const updates: Record<string, any> = {};
    updates[`/chatThreads/${threadId}/lastMessageText`] = text;
    updates[`/chatThreads/${threadId}/lastMessageAt`] = createdAt;

    updates[`/userThreads/${senderUid}/${threadId}/lastMessageText`] = text;
    updates[`/userThreads/${senderUid}/${threadId}/lastMessageAt`] = createdAt;
    updates[`/userThreads/${senderUid}/${threadId}/unreadCount`] = 0;

    updates[`/userThreads/${receiverUid}/${threadId}/lastMessageText`] = text;
    updates[`/userThreads/${receiverUid}/${threadId}/lastMessageAt`] =
      createdAt;

    await db.ref().update(updates);

    const unreadRef = db.ref(
      `/userThreads/${receiverUid}/${threadId}/unreadCount`,
    );
    await unreadRef.transaction((cur) => {
      const n = typeof cur === "number" ? cur : 0;
      return n + 1;
    });
  },
);

// --------------------
// QUOTATION WORKFLOW
// --------------------

app.post(
  "/booking/quote/request",
  verifyFirebaseToken,
  async (req: AuthedRequest, res: Response) => {
    try {
      const uid = req.uid!;
      const {role} = await getRoleAndProfile(uid);
      if (role !== "customer") {
        res
          .status(403)
          .json({ok: false, message: "Only customers can request quotes"});
        return;
      }

      const workerId = requireString(req.body.workerId, "workerId");
      const serviceId = requireString(req.body.serviceId, "serviceId");
      const serviceName = requireString(req.body.serviceName, "serviceName");
      const locationText = requireString(req.body.locationText, "locationText");

      const title = requireString(req.body.title, "title");
      const description = (req.body.description ?? "").toString();

      const db = admin.database();
      const bookingRef = db.ref("bookings").push();
      const bookingId = bookingRef.key;
      if (!bookingId) throw new Error("Failed to generate booking id");

      const updates: Record<string, any> = {};
      const now = admin.database.ServerValue.TIMESTAMP;

      const bookingData = {
        bookingId,
        customerId: uid,
        workerId,
        serviceId,
        serviceName,
        locationText,
        scheduledDate: asCleanString(req.body.scheduledDate, 20) || null,
        scheduledTime: asCleanString(req.body.scheduledTime, 10) || null,
        scheduledAt: Number.isFinite(Number(req.body.scheduledAt)) ?
          Number(req.body.scheduledAt) :
          null,
        dateMode: asCleanString(req.body.dateMode, 20) || null,
        status: "quote_requested",
        createdAt: now,
        updatedAt: now,
        quoteRequest: {
          title,
          description,
          requestedAt: now,
        },
      };

      updates[`bookings/${bookingId}`] = bookingData;
      updates[`userBookings/customers/${uid}/${bookingId}`] = true;
      updates[`userBookings/workers/${workerId}/${bookingId}`] = true;

      await db.ref().update(updates);

      await createNotification({
        toUid: workerId,
        type: "quote_requested",
        title: "New Quotation Request",
        message: `You received a new quotation request for ${serviceName}`,
        bookingId,
      });

      res.json({ok: true, bookingId});
    } catch (e: any) {
      res
        .status(400)
        .json({ok: false, message: e?.message ?? "Failed to request quote"});
    }
  },
);

app.post(
  "/booking/quote/worker-decision",
  verifyFirebaseToken,
  async (req: AuthedRequest, res: Response) => {
    try {
      const uid = req.uid!;
      const {role} = await getRoleAndProfile(uid);
      if (role !== "worker") {
        res.status(403).json({
          ok: false,
          message: "Only workers can respond to quote requests",
        });
        return;
      }

      const bookingId = requireString(req.body.bookingId, "bookingId");
      const decision = requireString(req.body.decision, "decision"); // accepted | declined
      const note = (req.body.note ?? "").toString();

      if (decision !== "accepted" && decision !== "declined") {
        throw new Error("decision must be accepted or declined");
      }

      const {db, booking} = await requireBooking(bookingId);

      if (booking.workerId !== uid) throw new Error("Not your booking");
      if (booking.status !== "quote_requested") {
        throw new Error("Booking is not in quote_requested status");
      }

      const now = admin.database.ServerValue.TIMESTAMP;

      if (decision === "declined") {
        await db.ref(`bookings/${bookingId}`).update({
          status: "quote_declined_by_worker",
          updatedAt: now,
          workerDecision: {decision: "declined", note, decidedAt: now},
        });

        await createNotification({
          toUid: booking.customerId,
          type: "quote_declined_by_worker",
          title: "Quotation Request Declined",
          message: "The worker declined your quotation request.",
          bookingId,
        });

        res.json({ok: true});
        return;
      }

      // accepted
      await db.ref(`bookings/${bookingId}`).update({
        status: "quote_accepted_by_worker",
        updatedAt: now,
        workerDecision: {decision: "accepted", note, decidedAt: now},
      });

      await createNotification({
        toUid: booking.customerId,
        type: "quote_accepted_by_worker",
        title: "Quotation Request Accepted",
        message: "The worker accepted your request and will send a quotation.",
        bookingId,
      });

      res.json({ok: true});
    } catch (e: any) {
      res.status(400).json({
        ok: false,
        message: e?.message ?? "Failed to update decision",
      });
    }
  },
);

app.post(
  "/booking/invoice/send",
  verifyFirebaseToken,
  async (req: AuthedRequest, res: Response) => {
    try {
      const uid = req.uid!;
      const {role, profile} = await getRoleAndProfile(uid);
      if (role !== "worker") {
        res
          .status(403)
          .json({ok: false, message: "Only workers can send invoices"});
        return;
      }

      const bookingId = requireString(req.body.bookingId, "bookingId");

      const inspectionFee = requireNumber(
        req.body.inspectionFee,
        "inspectionFee",
      );
      const laborHours = requireNumber(req.body.laborHours, "laborHours");
      const laborPrice = requireNumber(req.body.laborPrice, "laborPrice");
      const materials = requireNumber(req.body.materials, "materials");
      const notes = (req.body.notes ?? "").toString();

      const subtotal = inspectionFee + laborHours * laborPrice + materials;
      const validDays = Number(req.body.validDays ?? 3);
      const validUntil = Date.now() + validDays * 24 * 60 * 60 * 1000;

      const {db, booking} = await requireBooking(bookingId);
      if (booking.workerId !== uid) throw new Error("Not your booking");
      if (booking.status !== "quote_accepted_by_worker") {
        throw new Error(
          "Booking must be quote_accepted_by_worker before sending invoice",
        );
      }

      const workerName = (profile?.["fullName"] ?? "Worker").toString();
      const now = admin.database.ServerValue.TIMESTAMP;

      await db.ref(`bookings/${bookingId}`).update({
        status: "invoice_sent",
        updatedAt: now,
        invoice: {
          inspectionFee,
          laborHours,
          laborPrice,
          materials,
          notes,
          subtotal,
          validUntil,
          sentAt: now,
          workerName,
        },
      });

      // Notification payload matches your report style :contentReference[oaicite:5]{index=5}
      await createNotification({
        toUid: booking.customerId,
        type: "invoice_sent",
        title: "New Quotation Received",
        message: `${workerName} sent you a quotation for LKR ${subtotal}`,
        bookingId,
      });

      res.json({ok: true, subtotal, validUntil});
    } catch (e: any) {
      res
        .status(400)
        .json({ok: false, message: e?.message ?? "Failed to send invoice"});
    }
  },
);

app.post(
  "/booking/quote/customer-decision",
  verifyFirebaseToken,
  async (req: AuthedRequest, res: Response) => {
    try {
      const uid = req.uid!;
      const {role} = await getRoleAndProfile(uid);
      if (role !== "customer") {
        res.status(403).json({
          ok: false,
          message: "Only customers can accept/decline quotes",
        });
        return;
      }

      const bookingId = requireString(req.body.bookingId, "bookingId");
      const decision = requireString(req.body.decision, "decision"); // accepted | declined
      const reason = (req.body.reason ?? "").toString();

      if (decision !== "accepted" && decision !== "declined") {
        throw new Error("decision must be accepted or declined");
      }

      const {db, booking} = await requireBooking(bookingId);
      if (booking.customerId !== uid) throw new Error("Not your booking");
      if (booking.status !== "invoice_sent") {
        throw new Error(
          "Booking must be invoice_sent before customer decision",
        );
      }

      const now = admin.database.ServerValue.TIMESTAMP;

      if (decision === "declined") {
        await db.ref(`bookings/${bookingId}`).update({
          status: "quote_declined",
          updatedAt: now,
          quoteResponse: {
            customerDecision: "declined",
            reason,
            decidedAt: now,
          },
        });

        // Matches report :contentReference[oaicite:6]{index=6}
        await createNotification({
          toUid: booking.workerId,
          type: "quote_declined",
          title: "Quote Declined",
          message: "Customer declined your quotation",
          bookingId,
        });

        res.json({ok: true});
        return;
      }

      // accepted
      await db.ref(`bookings/${bookingId}`).update({
        status: "quote_accepted",
        updatedAt: now,
        quoteResponse: {customerDecision: "accepted", decidedAt: now},
      });

      // Matches report :contentReference[oaicite:7]{index=7}
      await createNotification({
        toUid: booking.workerId,
        type: "quote_accepted",
        title: "Quote Accepted!",
        message: "Customer accepted your quotation",
        bookingId,
      });

      res.json({ok: true});
    } catch (e: any) {
      res.status(400).json({
        ok: false,
        message: e?.message ?? "Failed to update quote decision",
      });
    }
  },
);
