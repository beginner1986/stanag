const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();

setGlobalOptions({region: "europe-central2", maxInstances: 10});

const webhookSecret = defineSecret("REVENUECAT_WEBHOOK_SECRET");

// Events that grant premium access.
const GRANT_EVENTS = new Set(["INITIAL_PURCHASE", "RENEWAL", "UNCANCELLATION"]);

// Events that permanently revoke access.
// CANCELLATION is intentionally excluded — the user retains access until the
// current billing period ends, at which point EXPIRATION fires. Revoking on
// CANCELLATION would remove paid-for access and violates Play Store policies.
const REVOKE_EVENTS = new Set(["EXPIRATION", "BILLING_ISSUE"]);

exports.revenuecatWebhook = onRequest(
    {secrets: [webhookSecret]},
    async (req, res) => {
      if (req.method !== "POST") {
        return res.status(405).send("Method Not Allowed");
      }

      const authHeader = req.headers["authorization"] ?? "";
      if (authHeader !== `Bearer ${webhookSecret.value()}`) {
        logger.warn("revenuecatWebhook: invalid secret");
        return res.status(401).send("Unauthorized");
      }

      const event = req.body?.event;
      if (!event) {
        return res.status(400).send("Missing event");
      }

      const {
        type,
        app_user_id: uid,
        expiration_at_ms: expiresAtMs,
      } = event;

      if (!uid) {
        logger.warn("revenuecatWebhook: missing app_user_id", {type});
        return res.status(400).send("Missing app_user_id");
      }

      try {
        if (GRANT_EVENTS.has(type)) {
          const premiumUntil = expiresAtMs ?? null;
          await admin.auth().setCustomUserClaims(uid, {
            is_premium: true,
            premium_until: premiumUntil,
          });
          const firestoreUntil = premiumUntil !== null ?
            admin.firestore.Timestamp.fromMillis(premiumUntil) :
            null;
          await admin.firestore().collection("users").doc(uid).set(
              {is_premium: true, premium_until: firestoreUntil},
              {merge: true},
          );
          logger.info("revenuecatWebhook: premium granted",
              {uid, type, expiresAtMs});
        } else if (REVOKE_EVENTS.has(type)) {
          await admin.auth().setCustomUserClaims(uid, {
            is_premium: false,
            premium_until: null,
          });
          await admin.firestore().collection("users").doc(uid).set(
              {is_premium: false, premium_until: null},
              {merge: true},
          );
          logger.info("revenuecatWebhook: premium revoked", {uid, type});
        } else {
          logger.info("revenuecatWebhook: unhandled event type (no-op)",
              {uid, type});
        }

        return res.status(200).send("OK");
      } catch (err) {
        logger.error("revenuecatWebhook: failed to process event",
            {uid, type, err});
        return res.status(500).send("Internal Server Error");
      }
    },
);
