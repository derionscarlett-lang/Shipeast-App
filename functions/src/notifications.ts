/**
 * Notification fan-out (P4-04).
 *
 * Audit §9. Both apps collect an `fcmToken` and **nothing has ever sent to
 * one**. The admin's "Log Notification" button writes a Firestore document
 * that only the customer app reads, so choosing "All Drivers" delivered to
 * nobody — the panel reported success for a message no driver could receive.
 *
 * The trigger that matters most is `onOrderCreated`. Today a driver only
 * learns an order exists while the app is foregrounded and toggled online
 * (`dashboard_screen.dart`). A driver with the phone in their pocket misses
 * every order. For a delivery product that is a fundamental gap, not polish.
 *
 * Everything decidable without a database lives in exported pure functions at
 * the top of this file and is pinned by `notifications.test.ts`. What a
 * customer is told their order is doing should not first be observable in
 * production.
 */

import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as OrderStatus from './orderStatus';

if (admin.apps.length === 0) {
  admin.initializeApp();
}

/** FCM refuses more than this many tokens in one multicast. */
export const MULTICAST_LIMIT = 500;

export interface PushContent {
  title: string;
  body: string;
  data?: Record<string, string>;
}

/**
 * Split into FCM-sized batches.
 *
 * Exported because the failure it prevents is invisible until the driver
 * roster crosses 500: a single oversized call is rejected wholesale, so
 * *every* driver silently stops receiving orders the day the 501st signs up.
 */
export function chunk<T>(items: readonly T[], size = MULTICAST_LIMIT): T[][] {
  if (size < 1) return [items.slice()];
  const out: T[][] = [];
  for (let i = 0; i < items.length; i += size) {
    out.push(items.slice(i, i + size));
  }
  return out;
}

/**
 * Unique, non-empty tokens.
 *
 * Duplicates are real: a customer document and a driver document can hold the
 * same token when one person uses both apps on one phone, and an admin
 * broadcast to `all` reads both collections. Without this they get the
 * notification twice.
 */
export function dedupeTokens(tokens: readonly unknown[]): string[] {
  const seen = new Set<string>();
  for (const t of tokens) {
    if (typeof t === 'string' && t.trim() !== '') seen.add(t);
  }
  return [...seen];
}

/** Collections an admin broadcast target reads tokens from. */
export function targetCollections(target: unknown): string[] {
  switch (String(target ?? 'all').toLowerCase()) {
    case 'drivers':   return ['drivers'];
    case 'customers': return ['users'];
    case 'all':       return ['users', 'drivers'];
    // Anything else is treated by the caller as a single uid (SCHEMA.md
    // §notifications allows one), NOT as a broadcast. Failing open here would
    // turn one hand-edited document into a push to the entire user base.
    default:          return [];
  }
}

/**
 * What a driver sees when a new order lands.
 *
 * The money figure is the order's stored `total`, never a recomputed one —
 * a driver deciding whether to take a job must be shown the same number the
 * customer was charged.
 */
export function orderCreatedContent(
  orderId: string,
  order: Record<string, unknown>
): PushContent {
  const total = Number(order.total);
  const merchant = typeof order.merchantName === 'string' && order.merchantName
    ? order.merchantName
    : 'A merchant';
  const amount = Number.isFinite(total) && total > 0
    ? ` · $${Math.round(total).toLocaleString('en-US')}`
    : '';
  return {
    title: 'New order available',
    body: `${merchant}${amount}`,
    data: { type: 'order_created', orderId }
  };
}

/**
 * What a customer is told when their order moves.
 *
 * Returns null for statuses the customer should not be pinged about:
 * `pending` is the state the order is created in — the customer is looking at
 * the confirmation screen and does not need a push telling them what they
 * just did.
 */
export function statusChangeContent(
  orderId: string,
  status: string
): PushContent | null {
  if (!OrderStatus.isValid(status) || status === OrderStatus.PENDING) return null;
  const body: Record<string, string> = {
    [OrderStatus.CONFIRMED]:  'A driver has been assigned to your order.',
    [OrderStatus.PICKED_UP]:  'Your order has been picked up.',
    [OrderStatus.IN_TRANSIT]: 'Your driver is on the way.',
    [OrderStatus.DELIVERED]:  'Your order has been delivered. Enjoy!',
    [OrderStatus.CANCELLED]:  'Your order was cancelled.'
  };
  return {
    // The label comes from the shared lifecycle module, so the push and the
    // tracking screen cannot disagree about what the order is doing.
    title: OrderStatus.label(status),
    body: body[status] ?? 'Your order status changed.',
    data: { type: 'order_status', orderId, status }
  };
}

/** What an applicant is told when the admin rules on their application. */
export function driverStatusContent(status: string): PushContent | null {
  if (status === 'approved') {
    return {
      title: 'You\'re approved',
      body: 'Your ShipEast driver account is active. Go online to start receiving orders.',
      data: { type: 'driver_status', status }
    };
  }
  if (status === 'rejected') {
    return {
      title: 'Application not approved',
      body: 'Your driver application was not approved. Contact support for details.',
      data: { type: 'driver_status', status }
    };
  }
  // 'pending' and anything unrecognised: say nothing. A driver reverted to
  // pending by an admin correction should hear it from a person.
  return null;
}

/** Error codes meaning the token is dead and should be removed. */
const DEAD_TOKEN_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
  'messaging/invalid-argument'
]);

export function isDeadToken(code: unknown): boolean {
  return typeof code === 'string' && DEAD_TOKEN_CODES.has(code);
}

// ──────────────────────────────────────────────────────────────────────────
// Database-touching plumbing
// ──────────────────────────────────────────────────────────────────────────

const db = () => admin.firestore();

/**
 * At-most-once guard.
 *
 * Firestore triggers are **at-least-once**: a retry after a transient error
 * re-runs the handler with the same event. Without this a customer gets "Your
 * driver is on the way" three times. `create()` fails if the document exists,
 * which makes the check and the claim a single atomic operation — a plain
 * get-then-set would race two concurrent retries.
 *
 * Returns true if this caller owns the send.
 */
async function claim(eventKey: string): Promise<boolean> {
  try {
    await db().collection('pushLog').doc(eventKey).create({
      at: admin.firestore.FieldValue.serverTimestamp()
    });
    return true;
  } catch (e) {
    const code = (e as { code?: number | string }).code;
    // 6 / ALREADY_EXISTS — another delivery of this event already sent it.
    if (code === 6 || code === 'already-exists') return false;
    // Any other failure: send anyway. A duplicate notification is an
    // annoyance; a silently dropped one is the bug this file exists to fix.
    logger.warn('pushLog claim failed, sending unguarded', { eventKey, code });
    return true;
  }
}

/** Reads token + document path so a dead token can be cleared at its source. */
async function tokensFrom(
  collections: readonly string[]
): Promise<{ token: string; ref: FirebaseFirestore.DocumentReference }[]> {
  const out: { token: string; ref: FirebaseFirestore.DocumentReference }[] = [];
  for (const name of collections) {
    const snap = await db().collection(name).where('fcmToken', '!=', '').get();
    for (const doc of snap.docs) {
      const token = doc.data().fcmToken;
      if (typeof token === 'string' && token.trim() !== '') {
        out.push({ token, ref: doc.ref });
      }
    }
  }
  return out;
}

/** A single addressee, looked up in both collections. */
async function tokenForUid(uid: string) {
  if (!uid) return [];
  const out: { token: string; ref: FirebaseFirestore.DocumentReference }[] = [];
  for (const name of ['users', 'drivers']) {
    const snap = await db().collection(name).doc(uid).get();
    const token = snap.data()?.fcmToken;
    if (typeof token === 'string' && token.trim() !== '') {
      out.push({ token, ref: snap.ref });
    }
  }
  return out;
}

/** Online, approved drivers only — the people who can actually take the job. */
async function onlineDriverTokens() {
  const snap = await db().collection('drivers')
    .where('status', '==', 'approved')
    .where('isOnline', '==', true)
    .get();
  return snap.docs
    .map((d) => ({ token: d.data().fcmToken, ref: d.ref }))
    .filter((r): r is { token: string; ref: FirebaseFirestore.DocumentReference } =>
      typeof r.token === 'string' && r.token.trim() !== '');
}

/**
 * Sends, then clears every token FCM reports as dead.
 *
 * Pruning is not housekeeping. An uninstalled app leaves a token that fails on
 * every future send; left in place the roster fills with corpses, each one a
 * wasted call and a misleading "sent to 40 drivers" in the logs.
 */
async function sendTo(
  recipients: { token: string; ref: FirebaseFirestore.DocumentReference }[],
  content: PushContent
): Promise<number> {
  const owner = new Map<string, FirebaseFirestore.DocumentReference>();
  for (const r of recipients) if (!owner.has(r.token)) owner.set(r.token, r.ref);
  const tokens = dedupeTokens([...owner.keys()]);
  if (tokens.length === 0) return 0;

  let delivered = 0;
  const dead: FirebaseFirestore.DocumentReference[] = [];

  for (const batch of chunk(tokens)) {
    const res = await admin.messaging().sendEachForMulticast({
      tokens: batch,
      notification: { title: content.title, body: content.body },
      data: content.data ?? {},
      android: { priority: 'high' },
      apns: { payload: { aps: { sound: 'default' } } }
    });
    delivered += res.successCount;
    res.responses.forEach((r, i) => {
      if (!r.success && isDeadToken(r.error?.code)) {
        const ref = owner.get(batch[i]);
        if (ref) dead.push(ref);
      }
    });
  }

  if (dead.length > 0) {
    const writer = db().batch();
    for (const ref of dead) {
      writer.update(ref, { fcmToken: admin.firestore.FieldValue.delete() });
    }
    await writer.commit();
  }

  logger.info('push sent', {
    title: content.title,
    targets: tokens.length,
    delivered,
    pruned: dead.length
  });
  return delivered;
}

// ──────────────────────────────────────────────────────────────────────────
// Triggers
// ──────────────────────────────────────────────────────────────────────────

/**
 * Admin broadcast. This is the fix for the "All Drivers" dead end: the panel
 * writes the same document it always did, and it now actually goes somewhere.
 */
export const onNotificationCreated = onDocumentCreated(
  'notifications/{notificationId}',
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    if (!(await claim(`notification_${event.params.notificationId}`))) return;

    const collections = targetCollections(data.target);
    const recipients = collections.length > 0
      ? await tokensFrom(collections)
      // SCHEMA.md §notifications permits a single uid as the target. Look it
      // up in both collections — the same uid space serves customers and
      // drivers, and the admin knows which it meant.
      : await tokenForUid(String(data.target ?? ''));

    if (recipients.length === 0) {
      logger.warn('notification reached nobody', { target: data.target });
    }

    const delivered = await sendTo(recipients, {
      title: String(data.title ?? 'ShipEast'),
      body: String(data.message ?? ''),
      data: { type: 'broadcast' }
    });

    // Closes the loop between "logged" and "sent" — the panel's history has
    // always claimed success for messages that reached nobody.
    await event.data!.ref.set({ deliveredCount: delivered }, { merge: true });
  }
);

/** The one that matters most — see the file header. */
export const onOrderCreated = onDocumentCreated('orders/{orderId}', async (event) => {
  const order = event.data?.data();
  if (!order) return;
  const orderId = event.params.orderId;
  if (!(await claim(`order_created_${orderId}`))) return;

  await sendTo(await onlineDriverTokens(), orderCreatedContent(orderId, order));
});

/**
 * Status changes: the customer always, plus the assigned driver on a
 * cancellation — a driver already en route needs to be told to stop, and
 * nothing told them before this.
 */
export const onOrderStatusChanged = onDocumentUpdated('orders/{orderId}', async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after) return;

  const status = String(after.status ?? '');
  if (String(before.status ?? '') === status) return;

  const orderId = event.params.orderId;
  if (!(await claim(`order_status_${orderId}_${status}`))) return;

  const content = statusChangeContent(orderId, status);
  if (content) {
    // `customerId` is canonical (SCHEMA.md §orders, enforced by the create
    // rule). `userId` is only read as a fallback for pre-migration documents.
    const userId = after.customerId ?? after.userId;
    if (typeof userId === 'string' && userId) {
      const snap = await db().collection('users').doc(userId).get();
      const token = snap.data()?.fcmToken;
      if (typeof token === 'string' && token) {
        await sendTo([{ token, ref: snap.ref }], content);
      }
    }
  }

  if (status === OrderStatus.CANCELLED) {
    const driverId = after.driverId;
    if (typeof driverId === 'string' && driverId) {
      const snap = await db().collection('drivers').doc(driverId).get();
      const token = snap.data()?.fcmToken;
      if (typeof token === 'string' && token) {
        await sendTo([{ token, ref: snap.ref }], {
          title: 'Order cancelled',
          body: 'An order assigned to you was cancelled. Do not continue the delivery.',
          data: { type: 'order_cancelled', orderId }
        });
      }
    }
  }
});

/**
 * Approval and rejection.
 *
 * A driver applying today learns their fate by opening the app and guessing;
 * `pending_approval_screen.dart` polls, so the answer arrives only while they
 * happen to be watching.
 */
export const onDriverStatusChanged = onDocumentUpdated('drivers/{driverId}', async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after) return;

  const status = String(after.status ?? '');
  if (String(before.status ?? '') === status) return;

  const content = driverStatusContent(status);
  if (!content) return;

  const token = after.fcmToken;
  if (typeof token !== 'string' || !token) return;
  if (!(await claim(`driver_status_${event.params.driverId}_${status}`))) return;

  await sendTo([{ token, ref: event.data!.after.ref }], content);
});
