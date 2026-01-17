import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

admin.initializeApp();

export const completeUserSignup = onCall(
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const uid = request.auth.uid;
    const role = request.data.role as string;
    const fullName = request.data.fullName as string;

    if (role !== "customer" && role !== "worker") {
      throw new HttpsError(
        "invalid-argument",
        "Invalid role"
      );
    }

    const userRecord = await admin.auth().getUser(uid);

    const baseUserData = {
      uid,
      fullName,
      email: userRecord.email ?? "",
      role,
      createdAt: admin.database.ServerValue.TIMESTAMP,
    };

    if (role === "customer") {
      await admin
        .database()
        .ref(`users/customers/${uid}`)
        .set(baseUserData);
    } else {
      await admin
        .database()
        .ref(`users/workers/${uid}`)
        .set({
          ...baseUserData,
          status: "pending_verification",
        });
    }

    await admin.auth().setCustomUserClaims(uid, {role});

    return {success: true};
  }
);
