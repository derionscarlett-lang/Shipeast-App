/**
 * ShipEast Cloud Functions.
 *
 * Bootstrapped by P2-03. Several later items are impossible client-side and
 * land here: promo redemption (P3-03), server-side commission (P3-04), rating
 * roll-ups (P3-05), notification fan-out (P4-04), and admin-initiated driver
 * provisioning (P4-05).
 */

import { onRequest } from 'firebase-functions/v2/https';

export { setAdminClaim } from './admin';

// Phase 3 — the work the clients must not be trusted with.
export { redeemPromo } from './redeemPromo';   // P3-03
export { confirmDelivery } from './delivery';  // P3-04
export { submitRating } from './rating';       // P3-05

// Phase 4 — the capabilities that did not exist at all.
export {
  onNotificationCreated,   // fixes the admin's "All Drivers" dead end
  onOrderCreated,          // a backgrounded driver finally hears about an order
  onOrderStatusChanged,
  onDriverStatusChanged
} from './notifications';   // P4-04
export { createDriverAccount } from './drivers';  // P4-05

/**
 * Proves the deploy pipeline works end to end (P2-03's acceptance criterion).
 * Deliberately trivial and unauthenticated — it reveals nothing.
 */
export const healthcheck = onRequest((_req, res) => {
  res.json({
    ok: true,
    service: 'shipeast-functions',
    time: new Date().toISOString()
  });
});
