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
