import { test, describe, before, after, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds
} from '@firebase/rules-unit-testing';
import {
  doc, getDoc, setDoc, updateDoc, deleteDoc, collection, addDoc
} from 'firebase/firestore';

/* Firestore security rules (P2-01).
 *
 * Every case here maps to a hole that was genuinely open before this file
 * existed. The plan calls this suite non-negotiable, and the reason is in its
 * own risk register: "rules deploy blocks a legitimate flow" is the
 * highest-likelihood launch failure. So this tests both directions — what must
 * be denied, and what must keep working. */

let testEnv;

const CUSTOMER = 'customer_uid';
const OTHER_CUSTOMER = 'other_customer_uid';
const DRIVER = 'driver_uid';
const OTHER_DRIVER = 'other_driver_uid';
const ADMIN = 'admin_uid';

const asCustomer = () => testEnv.authenticatedContext(CUSTOMER).firestore();
const asOtherCustomer = () => testEnv.authenticatedContext(OTHER_CUSTOMER).firestore();
const asDriver = () => testEnv.authenticatedContext(DRIVER).firestore();
const asOtherDriver = () => testEnv.authenticatedContext(OTHER_DRIVER).firestore();
const asAdmin = () => testEnv.authenticatedContext(ADMIN, { admin: true }).firestore();
const asAnon = () => testEnv.unauthenticatedContext().firestore();

/** A well-formed order that satisfies the arithmetic invariant. */
function order(overrides = {}) {
  return {
    customerId: CUSTOMER,
    customerName: 'Test Customer',
    merchantId: 'm1',
    merchantName: 'Island Jerk Palace',
    items: [{ name: 'Jerk Chicken', price: 1200, quantity: 1 }],
    subtotal: 1200,
    deliveryFee: 250,
    serviceFee: 50,
    discount: 0,
    total: 1500,
    paymentMethod: 'Cash on Delivery',
    deliveryAddress: '15 Harbour Street',
    status: 'pending',
    driverId: null,
    rated: false,
    ...overrides
  };
}

/** Seeds a document bypassing rules, for testing reads and updates. */
async function seed(path, data) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), path), data);
  });
}

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'shipeast-rules-test',
    firestore: {
      rules: readFileSync(new URL('../../firestore.rules', import.meta.url), 'utf8'),
      host: '127.0.0.1',
      port: 8080
    }
  });
});

after(async () => { if (testEnv) await testEnv.cleanup(); });
beforeEach(async () => { await testEnv.clearFirestore(); });

// ═══════════════════════════════════════════════════════════════════════════
describe('drivers — self-approval is the hole this closes', () => {
  test('a driver CANNOT approve themselves', async () => {
    await seed(`drivers/${DRIVER}`, { name: 'D', status: 'pending', totalTrips: 0 });
    await assertFails(
      updateDoc(doc(asDriver(), `drivers/${DRIVER}`), { status: 'approved' })
    );
  });

  test('a driver CANNOT inflate their own trips or rating', async () => {
    await seed(`drivers/${DRIVER}`, { name: 'D', status: 'approved', totalTrips: 0 });
    const db = asDriver();
    await assertFails(updateDoc(doc(db, `drivers/${DRIVER}`), { totalTrips: 9999 }));
    await assertFails(updateDoc(doc(db, `drivers/${DRIVER}`), { averageRating: 5 }));
    await assertFails(updateDoc(doc(db, `drivers/${DRIVER}`), { todayEarnings: 100000 }));
  });

  test('a driver CAN edit their own profile fields', async () => {
    await seed(`drivers/${DRIVER}`, { name: 'D', status: 'approved', totalTrips: 0 });
    await assertSucceeds(
      updateDoc(doc(asDriver(), `drivers/${DRIVER}`), {
        name: 'New Name', phone: '876-555-0000', isOnline: true
      })
    );
  });

  test('a driver registers only as pending with zero trips', async () => {
    await assertSucceeds(
      setDoc(doc(asDriver(), `drivers/${DRIVER}`), {
        name: 'D', status: 'pending', totalTrips: 0
      })
    );
  });

  test('a driver CANNOT self-register as approved', async () => {
    await assertFails(
      setDoc(doc(asDriver(), `drivers/${OTHER_DRIVER}`), {
        name: 'D', status: 'approved', totalTrips: 0
      })
    );
    await assertFails(
      setDoc(doc(asDriver(), `drivers/${DRIVER}`), {
        name: 'D', status: 'approved', totalTrips: 0
      })
    );
  });

  test('an admin CAN approve a driver', async () => {
    await seed(`drivers/${DRIVER}`, { name: 'D', status: 'pending', totalTrips: 0 });
    await assertSucceeds(
      updateDoc(doc(asAdmin(), `drivers/${DRIVER}`), { status: 'approved' })
    );
  });

  test('a driver cannot write another driver document', async () => {
    await seed(`drivers/${OTHER_DRIVER}`, { name: 'O', status: 'approved', totalTrips: 0 });
    await assertFails(
      updateDoc(doc(asDriver(), `drivers/${OTHER_DRIVER}`), { name: 'Hacked' })
    );
  });

  test('driver PII in the private subcollection is not readable by others', async () => {
    await seed(`drivers/${DRIVER}/private/licence`, { licenceNumber: 'DL-123' });
    await assertFails(getDoc(doc(asCustomer(), `drivers/${DRIVER}/private/licence`)));
    await assertFails(getDoc(doc(asOtherDriver(), `drivers/${DRIVER}/private/licence`)));
    await assertSucceeds(getDoc(doc(asDriver(), `drivers/${DRIVER}/private/licence`)));
    await assertSucceeds(getDoc(doc(asAdmin(), `drivers/${DRIVER}/private/licence`)));
  });

  test('the customer CAN read the driver profile bringing their order', async () => {
    // Legitimate flow — the tracking screen shows name, rating and vehicle.
    await seed(`drivers/${DRIVER}`, { name: 'D', status: 'approved', totalTrips: 0 });
    await assertSucceeds(getDoc(doc(asCustomer(), `drivers/${DRIVER}`)));
  });

  test('an anonymous client cannot read drivers at all', async () => {
    await seed(`drivers/${DRIVER}`, { name: 'D', status: 'approved', totalTrips: 0 });
    await assertFails(getDoc(doc(asAnon(), `drivers/${DRIVER}`)));
  });
});

// ═══════════════════════════════════════════════════════════════════════════
describe('orders — money cannot be rewritten by a client', () => {
  test('a customer CANNOT modify the total after creation', async () => {
    await seed('orders/o1', order());
    await assertFails(updateDoc(doc(asCustomer(), 'orders/o1'), { total: 1 }));
  });

  test('a driver CANNOT modify the total of an order they hold', async () => {
    await seed('orders/o1', order({ driverId: DRIVER, status: 'confirmed' }));
    await assertFails(updateDoc(doc(asDriver(), 'orders/o1'), { total: 999999 }));
  });

  test('an order whose total does not reconcile is rejected at creation', async () => {
    // subtotal 1200 + fee 250 + service 50 - discount 0 = 1500, not 100.
    await assertFails(
      addDoc(collection(asCustomer(), 'orders'), order({ total: 100 }))
    );
  });

  test('a discounted order must still reconcile', async () => {
    await assertSucceeds(
      addDoc(collection(asCustomer(), 'orders'),
        order({ discount: 200, total: 1300 }))
    );
    await assertFails(
      addDoc(collection(asCustomer(), 'orders'),
        order({ discount: 200, total: 1500 }))
    );
  });

  test('a well-formed order is accepted', async () => {
    await assertSucceeds(addDoc(collection(asCustomer(), 'orders'), order()));
  });

  test('a customer cannot create an order as someone else', async () => {
    await assertFails(
      addDoc(collection(asCustomer(), 'orders'), order({ customerId: OTHER_CUSTOMER }))
    );
  });

  test('a customer cannot create an order pre-claimed or already advanced', async () => {
    await assertFails(
      addDoc(collection(asCustomer(), 'orders'), order({ driverId: DRIVER }))
    );
    await assertFails(
      addDoc(collection(asCustomer(), 'orders'), order({ status: 'delivered' }))
    );
  });

  test('orders can never be deleted, by anyone', async () => {
    await seed('orders/o1', order());
    await assertFails(deleteDoc(doc(asCustomer(), 'orders/o1')));
    await assertFails(deleteDoc(doc(asAdmin(), 'orders/o1')));
  });
});

// ═══════════════════════════════════════════════════════════════════════════
describe('orders — claiming and the lifecycle', () => {
  test('a driver CAN claim an unclaimed pending order', async () => {
    await seed('orders/o1', order());
    await assertSucceeds(
      updateDoc(doc(asDriver(), 'orders/o1'), {
        driverId: DRIVER, driverName: 'D', driverPhone: '876',
        status: 'confirmed', acceptedAt: new Date()
      })
    );
  });

  test('a driver CANNOT claim an order another driver already holds', async () => {
    await seed('orders/o1', order({ driverId: OTHER_DRIVER, status: 'confirmed' }));
    await assertFails(
      updateDoc(doc(asDriver(), 'orders/o1'), {
        driverId: DRIVER, driverName: 'D', status: 'confirmed'
      })
    );
  });

  test('a driver advances their order one legal step at a time', async () => {
    await seed('orders/o1', order({ driverId: DRIVER, status: 'confirmed' }));
    await assertSucceeds(
      updateDoc(doc(asDriver(), 'orders/o1'), { status: 'picked_up' })
    );
  });

  test('a driver CANNOT skip the transit step', async () => {
    // picked_up -> delivered would make the customer's "On the Way" step
    // unreachable, which is the defect P1-05 fixed in the client.
    await seed('orders/o1', order({ driverId: DRIVER, status: 'picked_up' }));
    await assertFails(
      updateDoc(doc(asDriver(), 'orders/o1'), { status: 'delivered' })
    );
  });

  test('a driver CANNOT run the lifecycle backwards', async () => {
    await seed('orders/o1', order({ driverId: DRIVER, status: 'delivered' }));
    await assertFails(
      updateDoc(doc(asDriver(), 'orders/o1'), { status: 'pending' })
    );
  });

  test('terminal orders are terminal, even for an admin', async () => {
    await seed('orders/o1', order({ status: 'delivered' }));
    await assertFails(updateDoc(doc(asAdmin(), 'orders/o1'), { status: 'pending' }));
    await seed('orders/o2', order({ status: 'cancelled' }));
    await assertFails(updateDoc(doc(asAdmin(), 'orders/o2'), { status: 'confirmed' }));
  });

  test('a driver cannot touch an order they do not hold', async () => {
    await seed('orders/o1', order({ driverId: OTHER_DRIVER, status: 'confirmed' }));
    await assertFails(
      updateDoc(doc(asDriver(), 'orders/o1'), { status: 'picked_up' })
    );
  });

  test('an admin CAN assign a driver and confirm in one write', async () => {
    // The P1-07 black-hole fix must be permitted by rules.
    await seed('orders/o1', order());
    await assertSucceeds(
      updateDoc(doc(asAdmin(), 'orders/o1'), {
        driverId: DRIVER, driverName: 'D', status: 'confirmed'
      })
    );
  });

  test('an admin CAN unassign, returning the order to the pool', async () => {
    await seed('orders/o1', order({ driverId: DRIVER, status: 'confirmed' }));
    await assertSucceeds(
      updateDoc(doc(asAdmin(), 'orders/o1'), { driverId: null, status: 'pending' })
    );
  });
});

// ═══════════════════════════════════════════════════════════════════════════
describe('orders — customer cancellation and rating', () => {
  test('a customer CAN cancel their own pending order', async () => {
    await seed('orders/o1', order());
    await assertSucceeds(
      updateDoc(doc(asCustomer(), 'orders/o1'), {
        status: 'cancelled', cancelledAt: new Date(),
        cancelledBy: 'customer', cancellationReason: 'Changed my mind'
      })
    );
  });

  test('a customer CANNOT cancel once a driver has committed', async () => {
    await seed('orders/o1', order({ driverId: DRIVER, status: 'confirmed' }));
    await assertFails(
      updateDoc(doc(asCustomer(), 'orders/o1'), { status: 'cancelled' })
    );
  });

  test('a customer cannot smuggle a price change into a cancellation', async () => {
    await seed('orders/o1', order());
    await assertFails(
      updateDoc(doc(asCustomer(), 'orders/o1'), { status: 'cancelled', total: 0 })
    );
  });

  test('a customer CAN rate a delivered order', async () => {
    await seed('orders/o1', order({ status: 'delivered' }));
    await assertSucceeds(
      updateDoc(doc(asCustomer(), 'orders/o1'), {
        rated: true, driverRating: 5, merchantRating: 4, comment: 'Great', tags: []
      })
    );
  });

  test('a customer cannot rate someone else\'s order', async () => {
    await seed('orders/o1', order({ status: 'delivered' }));
    await assertFails(
      updateDoc(doc(asOtherCustomer(), 'orders/o1'), { rated: true, driverRating: 5 })
    );
  });
});

// ═══════════════════════════════════════════════════════════════════════════
describe('orders — read isolation', () => {
  test('a customer CANNOT read another customer\'s order', async () => {
    await seed('orders/o1', order());
    await assertFails(getDoc(doc(asOtherCustomer(), 'orders/o1')));
  });

  test('a customer CAN read their own order', async () => {
    await seed('orders/o1', order());
    await assertSucceeds(getDoc(doc(asCustomer(), 'orders/o1')));
  });

  test('the assigned driver CAN read the order', async () => {
    await seed('orders/o1', order({ driverId: DRIVER, status: 'confirmed' }));
    await assertSucceeds(getDoc(doc(asDriver(), 'orders/o1')));
  });

  test('an unassigned driver CANNOT read someone else\'s order', async () => {
    await seed('orders/o1', order({ driverId: OTHER_DRIVER, status: 'confirmed' }));
    await assertFails(getDoc(doc(asDriver(), 'orders/o1')));
  });

  test('an anonymous client can read nothing in orders', async () => {
    await seed('orders/o1', order());
    await assertFails(getDoc(doc(asAnon(), 'orders/o1')));
  });

  test('an admin CAN read any order', async () => {
    await seed('orders/o1', order());
    await assertSucceeds(getDoc(doc(asAdmin(), 'orders/o1')));
  });
});

// ═══════════════════════════════════════════════════════════════════════════
describe('users — profile and address isolation', () => {
  test('a customer CANNOT read another customer\'s profile', async () => {
    await seed(`users/${CUSTOMER}`, { name: 'C', email: 'c@x.com' });
    await assertFails(getDoc(doc(asOtherCustomer(), `users/${CUSTOMER}`)));
  });

  test('a customer CANNOT read another customer\'s address', async () => {
    await seed(`users/${CUSTOMER}/addresses/a1`, { label: 'Home', text: '15 Harbour St' });
    await assertFails(getDoc(doc(asOtherCustomer(), `users/${CUSTOMER}/addresses/a1`)));
  });

  test('a customer CAN manage their own addresses', async () => {
    await assertSucceeds(
      setDoc(doc(asCustomer(), `users/${CUSTOMER}/addresses/a1`),
        { label: 'Home', text: '15 Harbour St' })
    );
  });

  test('a customer cannot disable or re-enable their own account', async () => {
    await seed(`users/${CUSTOMER}`, { name: 'C', email: 'c@x.com', disabled: true });
    await assertFails(
      updateDoc(doc(asCustomer(), `users/${CUSTOMER}`), { disabled: false })
    );
  });

  test('an admin CAN disable an account but not rewrite the profile', async () => {
    await seed(`users/${CUSTOMER}`, { name: 'C', email: 'c@x.com' });
    await assertSucceeds(
      updateDoc(doc(asAdmin(), `users/${CUSTOMER}`), { disabled: true })
    );
    await assertFails(
      updateDoc(doc(asAdmin(), `users/${CUSTOMER}`), { name: 'Changed' })
    );
  });

  test('an admin CAN read a customer profile (Customers page)', async () => {
    await seed(`users/${CUSTOMER}`, { name: 'C', email: 'c@x.com' });
    await assertSucceeds(getDoc(doc(asAdmin(), `users/${CUSTOMER}`)));
  });
});

// ═══════════════════════════════════════════════════════════════════════════
describe('merchants, promos, notifications', () => {
  test('anyone can read merchants; nobody but an admin can write them', async () => {
    await seed('merchants/m1', { name: 'Island Jerk Palace', isOpen: true });
    await assertSucceeds(getDoc(doc(asAnon(), 'merchants/m1')));
    await assertFails(setDoc(doc(asCustomer(), 'merchants/m2'), { name: 'Fake' }));
    await assertSucceeds(setDoc(doc(asAdmin(), 'merchants/m2'), { name: 'Real' }));
  });

  test('the client seeder can never come back', async () => {
    // audit §13 — the customer app wrote 15 demo merchants into production.
    await assertFails(setDoc(doc(asCustomer(), 'merchants/seeded'), { name: 'Demo' }));
    await assertFails(
      setDoc(doc(asCustomer(), 'merchants/m1/menuItems/i1'), { name: 'Item', price: 100 })
    );
  });

  test('a customer can read a promo code but not create or redeem one', async () => {
    await seed('promoCodes/SAVE20', {
      code: 'SAVE20', discountType: 'percent', discountAmount: 20,
      usedCount: 0, maxUses: 100, active: true
    });
    await assertSucceeds(getDoc(doc(asCustomer(), 'promoCodes/SAVE20')));
    await assertFails(
      updateDoc(doc(asCustomer(), 'promoCodes/SAVE20'), { usedCount: 0, maxUses: 99999 })
    );
    await assertFails(
      setDoc(doc(asCustomer(), 'promoCodes/FREE100'), {
        discountType: 'percent', discountAmount: 100, active: true
      })
    );
  });

  test('a customer cannot broadcast a notification', async () => {
    await assertFails(
      addDoc(collection(asCustomer(), 'notifications'), {
        title: 'Spam', message: 'x', target: 'all'
      })
    );
  });

  test('a client cannot rewrite the commission rate', async () => {
    // settings/pricing feeds server-side payout (P3-04).
    await seed('settings/pricing', { serviceFee: 50, driverCommissionRate: 0.1 });
    await assertFails(
      updateDoc(doc(asDriver(), 'settings/pricing'), { driverCommissionRate: 0.9 })
    );
    await assertSucceeds(getDoc(doc(asAnon(), 'settings/pricing')));
  });
});

// ═══════════════════════════════════════════════════════════════════════════
describe('default deny', () => {
  test('an unmatched collection is denied even to an admin', async () => {
    await assertFails(setDoc(doc(asAdmin(), 'somethingNew/x'), { a: 1 }));
    await assertFails(getDoc(doc(asCustomer(), 'somethingNew/x')));
  });
});

// ═══════════════════════════════════════════════════════════════════════════
describe('admin unassignment is a reversal, not a lifecycle transition', () => {
  test('an admin CANNOT push an order backwards without unassigning', async () => {
    // The narrow exception must not become a general backwards door.
    await seed('orders/o1', order({ driverId: DRIVER, status: 'picked_up' }));
    await assertFails(
      updateDoc(doc(asAdmin(), 'orders/o1'), { status: 'confirmed' })
    );
  });

  test('unassignment must actually clear the driver', async () => {
    await seed('orders/o1', order({ driverId: DRIVER, status: 'confirmed' }));
    await assertFails(
      updateDoc(doc(asAdmin(), 'orders/o1'), { status: 'pending' })
    );
  });

  test('unassignment can only return an order to pending', async () => {
    await seed('orders/o1', order({ driverId: DRIVER, status: 'picked_up' }));
    await assertFails(
      updateDoc(doc(asAdmin(), 'orders/o1'), { driverId: null, status: 'confirmed' })
    );
  });

  test('a driver cannot unassign themselves off a held order', async () => {
    await seed('orders/o1', order({ driverId: DRIVER, status: 'confirmed' }));
    await assertFails(
      updateDoc(doc(asDriver(), 'orders/o1'), { driverId: null, status: 'pending' })
    );
  });
});
