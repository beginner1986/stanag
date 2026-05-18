"use strict";

const assert = require("assert");
const sinon = require("sinon");
const proxyquire = require("proxyquire");

// --- Admin SDK stubs ---

const setCustomUserClaims = sinon.stub();
const firestoreSet = sinon.stub();

const adminStub = {
  initializeApp: sinon.stub(),
  auth: () => ({setCustomUserClaims}),
  firestore: () => ({
    collection: () => ({doc: () => ({set: firestoreSet})}),
  }),
};
adminStub.firestore.Timestamp = {
  fromMillis: (ms) => ({seconds: Math.floor(ms / 1000), nanoseconds: 0}),
};

const loggerStub = {
  warn: sinon.stub(),
  info: sinon.stub(),
  error: sinon.stub(),
};

// Returning the handler directly so tests can call it as a plain async fn.
const onRequestStub = (_options, handler) => handler;

// Load the module under test with all Firebase dependencies replaced.
const {revenuecatWebhook: handler} = proxyquire("../index", {
  "firebase-admin": Object.assign(adminStub, {"@noCallThru": true}),
  "firebase-functions": {"setGlobalOptions": sinon.stub(), "@noCallThru": true},
  "firebase-functions/v2/https": {
    "onRequest": onRequestStub,
    "@noCallThru": true,
  },
  "firebase-functions/params": {
    "defineSecret": () => ({"value": () => "test-secret"}),
    "@noCallThru": true,
  },
  "firebase-functions/logger": Object.assign(loggerStub, {"@noCallThru": true}),
});

// --- Test helpers ---

const UID = "user-abc";
const EXPIRY_MS = 1700000000000;

/**
 * Builds a minimal mock request, merging any overrides into the defaults.
 * @param {object} overrides Fields to override on the default request.
 * @return {object} Mock request object.
 */
function makeReq(overrides = {}) {
  return Object.assign(
      {
        method: "POST",
        headers: {authorization: "Bearer test-secret"},
        body: {
          event: {
            type: "INITIAL_PURCHASE",
            app_user_id: UID,
            expiration_at_ms: EXPIRY_MS,
          },
        },
      },
      overrides,
  );
}

/**
 * Builds a mock response that records status and send calls.
 * @return {object} Mock response object.
 */
function makeRes() {
  const res = {};
  res.status = sinon.stub().returns(res);
  res.send = sinon.stub().returns(res);
  return res;
}

// --- Tests ---

describe("revenuecatWebhook", () => {
  beforeEach(() => {
    sinon.reset();
    setCustomUserClaims.resolves();
    firestoreSet.resolves();
  });

  // ── Request validation ────────────────────────────────────────────────────

  describe("request validation", () => {
    it("returns 405 for non-POST requests", async () => {
      const res = makeRes();
      await handler(makeReq({method: "GET"}), res);
      assert.ok(res.status.calledWith(405));
    });

    it("returns 401 when Authorization header is absent", async () => {
      const res = makeRes();
      await handler(makeReq({headers: {}}), res);
      assert.ok(res.status.calledWith(401));
    });

    it("returns 401 when secret is wrong", async () => {
      const res = makeRes();
      await handler(makeReq({headers: {authorization: "Bearer bad"}}), res);
      assert.ok(res.status.calledWith(401));
    });

    it("returns 400 when event body is missing", async () => {
      const res = makeRes();
      await handler(makeReq({body: {}}), res);
      assert.ok(res.status.calledWith(400));
    });

    it("returns 400 when app_user_id is missing", async () => {
      const res = makeRes();
      const event = {type: "INITIAL_PURCHASE", expiration_at_ms: EXPIRY_MS};
      await handler(makeReq({body: {event}}), res);
      assert.ok(res.status.calledWith(400));
    });
  });

  // ── GRANT events ──────────────────────────────────────────────────────────

  describe("GRANT events", () => {
    ["INITIAL_PURCHASE", "RENEWAL", "UNCANCELLATION"].forEach((type) => {
      it(`sets is_premium:true and returns 200 for ${type}`, async () => {
        const res = makeRes();
        const event = {type, app_user_id: UID, expiration_at_ms: EXPIRY_MS};
        await handler(makeReq({body: {event}}), res);

        assert.ok(setCustomUserClaims.calledOnceWith(UID, {
          is_premium: true,
          premium_until: EXPIRY_MS,
        }));
        const [fsData, fsOpts] = firestoreSet.firstCall.args;
        assert.strictEqual(fsData.is_premium, true);
        assert.ok(fsData.premium_until !== null);
        assert.deepStrictEqual(fsOpts, {merge: true});
        assert.ok(res.status.calledWith(200));
      });
    });

    it("stores null premium_until when expiry is absent", async () => {
      const res = makeRes();
      const event = {type: "RENEWAL", app_user_id: UID};
      await handler(makeReq({body: {event}}), res);

      assert.ok(setCustomUserClaims.calledOnceWith(UID, {
        is_premium: true,
        premium_until: null,
      }));
      const [fsData] = firestoreSet.firstCall.args;
      assert.strictEqual(fsData.premium_until, null);
      assert.ok(res.status.calledWith(200));
    });
  });

  // ── REVOKE events ─────────────────────────────────────────────────────────

  describe("REVOKE events", () => {
    ["EXPIRATION", "BILLING_ISSUE"].forEach((type) => {
      it(`sets is_premium:false and returns 200 for ${type}`, async () => {
        const res = makeRes();
        const event = {type, app_user_id: UID};
        await handler(makeReq({body: {event}}), res);

        assert.ok(setCustomUserClaims.calledOnceWith(UID, {
          is_premium: false,
          premium_until: null,
        }));
        assert.ok(firestoreSet.calledOnceWith(
            {is_premium: false, premium_until: null},
            {merge: true},
        ));
        assert.ok(res.status.calledWith(200));
      });
    });
  });

  // ── No-op events ──────────────────────────────────────────────────────────

  describe("no-op events", () => {
    // CANCELLATION is a no-op: user retains access until billing period ends.
    ["CANCELLATION", "PRODUCT_CHANGE", "TRANSFER"].forEach((type) => {
      it(`makes no admin calls and returns 200 for ${type}`, async () => {
        const res = makeRes();
        const event = {type, app_user_id: UID};
        await handler(makeReq({body: {event}}), res);

        assert.ok(setCustomUserClaims.notCalled);
        assert.ok(firestoreSet.notCalled);
        assert.ok(res.status.calledWith(200));
      });
    });
  });

  // ── Error handling ────────────────────────────────────────────────────────

  describe("error handling", () => {
    it("returns 500 when setCustomUserClaims throws", async () => {
      setCustomUserClaims.rejects(new Error("Auth SDK failure"));
      const res = makeRes();
      await handler(makeReq(), res);
      assert.ok(res.status.calledWith(500));
    });

    it("returns 500 when Firestore set throws", async () => {
      firestoreSet.rejects(new Error("Firestore failure"));
      const res = makeRes();
      await handler(makeReq(), res);
      assert.ok(res.status.calledWith(500));
    });
  });
});
