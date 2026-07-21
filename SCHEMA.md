# ShipEast — Schema of Record

**Status:** canonical · **Owner:** platform · **Established:** 2026-07-21 (P0-04)
**Firebase project (prod):** `shipeast-1a1f6`
**Resolves:** [all-three-apps-audit.md](all-three-apps-audit.md) §2, §5, §6, §11, §12, §13
**Implemented by:** [execution-all-three-plan.md](execution-all-three-plan.md) Phases 1–3

---

## Why this document exists

Three apps — `customer_app`, `driver_app`, `admin_panel` — share one Firestore database and were
each built against a private assumption about what an order, a driver, a merchant, and a promo code
look like. Those assumptions disagree in eleven places. The audit's root cause finding (§13) is not
any individual mismatch; it is that **no written contract ever existed**, so each app's author
reasonably invented one.

This file is that contract. It is the single source of truth. Where this document and the code
disagree, **the code is wrong** and there is a work item to fix it.

### Rules for changing this document

1. A schema change lands **here first**, in its own PR, before any code implements it.
2. Never silently repurpose a field name. Add the new field, migrate, then remove the old one —
   old app versions stay in the field for a long time (sideloaded APKs may never update).
3. Every field below names **who writes it** and **who reads it**. If a field has no reader, it
   should not exist. If it has no writer, it is a bug — that is exactly how `ordersToday` (always
   `0`) and `deliveryTime` (always the hardcoded fallback) happened.

---

## Global conventions

These apply to every collection and settle recurring inconsistencies found in the audit.

### a) Money — integers, minor-unit-free

All monetary values are **integers in Jamaican dollars**. No decimals, no `$` prefix, no thousands
separator, no currency symbol *in storage*.

```
deliveryFee: 250          ✅
fee: '$250'               ❌ current admin_panel/app.js:841 — resolves audit §6.1
total: 1450.00            ❌ never store a double for money
```

JMD has no circulating subunit in practice for this product, so integers are exact and there is no
floating-point rounding class of bug. Formatting happens **only at render time**, via:

- Flutter: `Money.format` / `Money.plain` (`driver_app/lib/driver_constants.dart`) — to be shared
  with the customer app in P3-06, which currently has two subtly-wrong `_formatPrice` copies.
- Admin: the existing `money()` helper (`admin_panel/app.js:41`).

This also kills the `amount` / `rawTotal` dual-read at `admin_panel/app.js:274-278`, which exists
only to tolerate both a number and a pre-formatted string in the same field.

### b) Timestamps — always `Timestamp`, never strings

Every date/time field is a Firestore `Timestamp`, written with `serverTimestamp()` where it records
"when did this happen". Never an ISO string, never a locale-formatted string.

```
expiresAt: Timestamp                ✅
validUntil: '2026-08-01'            ❌ current admin_panel/app.js:1121 — resolves audit §5
```

Server time, not client time, for anything that orders events. Client clocks are wrong and, on a
driver's phone, adversarially so.

### c) Spelling — British for licence fields

`licencePlate`, `licenceNumber` — **British spelling**, throughout.

This is not an aesthetic choice: both current *writers* (driver self-registration
`register_screen.dart:99-100`, and the admin panel `app.js:676-677`) already use British spelling.
Only the customer *reader* (`order_status_screen.dart:501`) uses American. Fixing one reader is
cheaper and lower-risk than migrating two writers plus every existing document (audit §12).

### d) Derived vs stored — counters that reset are never stored

Any figure that resets on a clock boundary is **computed at read time**, never persisted.

```
todayEarnings   → derive from today's delivered orders     (driver app already does this correctly)
ordersToday     → derive from the loaded orders array      (admin panel does NOT — audit §11)
```

A stored counter named `Today` has no reset mechanism and will be wrong from the first midnight
onward. The driver app hit this exact bug and solved it correctly at
`dashboard_screen.dart:149-161`, with a comment explaining why. The merchant equivalent must follow.

Aggregates that do *not* reset (`totalTrips`, `ratingCount`, `usedCount`) **are** stored, and are
incremented transactionally or server-side.

### e) Booleans — one field, no synonyms

One concept, one field. `merchants` currently carries both `isOpen` and `open`, written to the same
value by `app.js:841`, because the customer app read one and the admin wrote the other. Canonical:
`isOpen`. `open` is deprecated.

### f) Nullability

A field that is "not set yet" is **`null`**, not `''`, not `'—'`, not `0`. The admin panel writes
`'—'` as a placeholder into several driver and merchant fields (`app.js:672-677`, `838-840`); those
are display fallbacks that leaked into storage. Readers must render the fallback, not writers.

---

## `orders/{orderId}`

The central document. Written by all three apps; the source of every cross-app defect.

### Status vocabulary — canonical (resolves audit §2)

This is the single most important decision in this document. Today the customer app reads
`accepted` / `in_transit` (which nothing writes), the driver writes `confirmed` / `picked_up`
(which the customer does not understand), and the admin offers all seven unvalidated.

```
pending      order placed, no driver has claimed it
confirmed    a driver has claimed it and is en route to the merchant
picked_up    the driver has the goods
in_transit   the driver is en route to the customer     ← new; currently never written
delivered    terminal, success
cancelled    terminal, failure
```

`accepted` is **removed from the vocabulary entirely**. It was never written by any app.

**Legal transitions.** Enforced in three places, which must agree: `OrderStatus.transitions`
(P1-01), the admin dropdown (P1-06), and `firestore.rules` (P2-01).

```
pending    → confirmed | cancelled
confirmed  → picked_up | cancelled
picked_up  → in_transit | cancelled
in_transit → delivered  | cancelled
delivered  → (terminal — no transitions out)
cancelled  → (terminal — no transitions out)
```

**Derived sets**, defined once and used everywhere instead of ad-hoc `whereIn` literals:

| Set | Members | Used by |
|---|---|---|
| `active` | `pending`, `confirmed`, `picked_up`, `in_transit` | customer history "Active" tab |
| `driverHeld` | `confirmed`, `picked_up`, `in_transit` | driver `activeOrderStream` — **all three**, not two (audit §2.4) |
| `terminal` | `delivered`, `cancelled` | history, analytics |

Status strings are **never written as literals**. They come from the shared constant (P1-01), and
raw status values are **never rendered to a user** — always through `OrderStatus.label`.

### Fields

| Field | Type | Required | Written by | Read by | Notes |
|---|---|---|---|---|---|
| `customerId` | string (Auth UID) | ✅ | customer @ create | customer, driver, admin, rules | Immutable after create. |
| `customerName` | string | ✅ | customer @ create | admin, driver | Denormalised from `users/{uid}.name`. |
| `customerPhone` | string \| null | — | customer @ create | admin, driver | **Currently never written**; admin reads it (`app.js:275`) and always shows `—`. Add in P3-02. |
| `merchantId` | string | ✅ | customer @ create | admin, driver | |
| `merchantName` | string | ✅ | customer @ create | all | Denormalised. |
| `merchantAddr` | string \| null | — | customer @ create | driver, admin | **Currently never written**; the driver needs it to reach the pickup. Add in P3-02. |
| `items` | array\<OrderItem\> | ✅ | customer @ create | all | See below. Immutable. |
| `subtotal` | int | ✅ | customer @ create | all | Sum of `price × quantity`. Pre-discount. |
| `deliveryFee` | int | ✅ | customer @ create | all | Copied from `merchants/{id}.deliveryFee` at order time. |
| `serviceFee` | int | ✅ | customer @ create | all | |
| `discount` | int | ✅ | customer @ create | all | **Currently never written** (audit §6.2). `0` when no promo. |
| `promoCode` | string \| null | ✅ | customer @ create | admin | **Currently never written.** Audit trail for redemption. |
| `total` | int | ✅ | customer @ create | all | **Invariant:** `subtotal + deliveryFee + serviceFee - discount == total`. Asserted client-side before write (P3-02) and recomputed server-side (P2-01). |
| `paymentMethod` | string | ✅ | customer @ create | admin | `'cod'` only today. |
| `deliveryAddress` | string | ✅ | customer @ create | driver, admin | |
| `status` | string | ✅ | customer @ create (`pending`), driver, admin | all | Canonical vocabulary above. |
| `type` | string | ✅ | customer @ create | all | `'food'` \| `'package'` \| `'overseas'`. **Currently never written**; defaults to `'food'` when absent. Needed by P5-01. |
| `driverId` | string \| null | ✅ | driver @ accept, admin @ assign | all, rules | `null` = unclaimed. Explicit `null`, never `''` — `pendingOrdersStream` filters `isNull: true`. |
| `driverName` | string \| null | — | driver @ accept, admin @ assign | customer, admin | Denormalised. |
| `driverPhone` | string \| null | — | driver @ accept, admin @ assign | customer, admin | |
| `rated` | bool | ✅ | customer @ create (`false`), @ rate (`true`) | customer | |
| `driverRating` | int (1–5) \| null | — | customer @ rate | admin | |
| `merchantRating` | int (1–5) \| null | — | customer @ rate | admin | Collected today, **rolled up nowhere** (audit §11). P3-05 aggregates it. |
| `comment` | string \| null | — | customer @ rate | admin | |
| `tags` | array\<string\> | — | customer @ rate | admin | |
| `deliveryPhotoUrl` | string \| null | — | driver @ deliver | admin | Proof of delivery. Captured today, **displayed nowhere** — P5-06. |
| `deliveryNote` | string \| null | — | driver @ deliver | admin | Same. |
| `cancelledBy` | string \| null | — | customer / admin @ cancel | admin | `'customer'` \| `'admin'`. |
| `cancellationReason` | string \| null | — | customer / admin @ cancel | customer, driver, admin | |
| `assignedBy` | string \| null | — | admin @ assign | admin | Audit trail (P1-07). |

**Timestamps** — all `Timestamp`, all `serverTimestamp()`:

| Field | Set when |
|---|---|
| `createdAt` | order placed |
| `acceptedAt` | driver claims (status → `confirmed`) |
| `pickedUpAt` | status → `picked_up` |
| `inTransitAt` | status → `in_transit` — **new** |
| `deliveredAt` | status → `delivered` |
| `cancelledAt` | status → `cancelled` |
| `assignedAt` | admin assigns a driver |
| `updatedAt` | any admin mutation |

Each transition writes its timestamp **in the same write** as the status change, never separately.

### `OrderItem` (element of `items`)

| Field | Type | Notes |
|---|---|---|
| `name` | string | Denormalised from the menu item. |
| `price` | int | Unit price **at time of order**. Never re-read from the menu — menu prices change. |
| `quantity` | int | ≥ 1 |

### Deletion

**Orders are never deleted.** Cancel, never delete. Enforced in rules (P2-01).

---

## `drivers/{uid}`

**Document ID is the Firebase Auth UID.** This is not negotiable — the driver app addresses driver
documents by `uid` in every single access path (`main.dart:70`, `driver_firestore_service.dart:12`,
`19`, `22`, `register_screen.dart:97`).

The admin panel currently violates this with `addDoc(collection(db,'drivers'), obj)`
(`app.js:684`), producing a random-ID document with **no Auth account behind it** — a person who
can never log in, and a permanent ghost row in the admin's driver count (audit §4). Resolved by
P4-05 (`createDriverAccount` Cloud Function); mitigated in the interim by removing the button.

| Field | Type | Required | Written by | Read by | Notes |
|---|---|---|---|---|---|
| `name` | string | ✅ | driver @ register, admin | all | |
| `phone` | string | ✅ | driver @ register, admin | customer, admin | |
| `email` | string | ✅ | driver @ register, admin | admin | Mirrors the Auth email. |
| `vehicleType` | string | ✅ | driver @ register, admin | customer, admin | `'Car'` \| `'Motorcycle'` \| `'Bicycle'` \| `'Van'`. |
| `vehicleModel` | string | ✅ | driver @ register, admin | customer | Make and model, e.g. `'Toyota Corolla'`. **Driver registration does not collect this today** — admin does. P1-08 adds it and makes it required: an unidentifiable vehicle is a safety issue. |
| `licencePlate` | string | ✅ | driver @ register, admin | customer, admin | British spelling (§c). Uppercased. |
| `licenceNumber` | string | ✅ | driver @ register, admin | admin | PII — admin-read only, never exposed to customers. |
| `status` | string | ✅ | driver @ register (`pending`), **admin only** thereafter | all, rules | `'pending'` \| `'approved'` \| `'rejected'` \| `'suspended'`. **Rules must forbid a driver writing this to their own document** — today nothing stops self-approval (audit §7.1). |
| `isOnline` | bool | ✅ | driver | admin, functions | Availability toggle. |
| `onDelivery` | bool | — | driver | admin | Derived-ish; admin reads it (`app.js:308`). |
| `fcmToken` | string \| null | — | driver | functions | Collected today, **sent to by nothing** (audit §9). P4-04 uses it. |
| `avatarUrl` | string \| null | — | driver | customer, admin | |
| `totalTrips` | int | ✅ | **server only** (P3-04) | all | Lifetime. Stored (does not reset). |
| `totalRatings` | int | ✅ | server @ rating | — | Sum of stars, for the average. |
| `ratingCount` | int | ✅ | server @ rating | admin | Number of ratings. |
| `averageRating` | double | ✅ | server @ rating | customer, admin | `totalRatings / ratingCount`. |
| `ratingCounts` | map\<'1'..'5', int\> | — | server @ rating | admin | Per-star histogram. **Nothing writes it today**; the admin panel correctly shows an honest empty state (`app.js:735-750`) and will simply start working once P3-05 populates it. |
| `createdAt` | Timestamp | ✅ | driver @ register | admin | |
| `updatedAt` | Timestamp | — | admin | — | |

**Deprecated / do not write:** `rating` (superseded by `averageRating`), `todayEarnings` (violates
§d — derived instead), `vtype`, `vehicle`, `plate`, `dlicence`, `trips`, `ratingBreakdown` (all
legacy aliases the admin panel reads defensively; remove after P2-05 migration).

**Write access.** A driver may write their own profile fields only. `status`, `totalTrips`,
`totalRatings`, `ratingCount`, `averageRating`, `ratingCounts` are **server/admin only**.

---

## `merchants/{merchantId}`

Random document ID. Admin-owned: **the customer app must never write to this collection.** It does
today, via `seedMerchantsIfEmpty()` (audit §13, removed in P1-09).

The `hours` / `deliveryTime` collision is the subtle one here. The admin's "Opening Hours" input and
the customer's `deliveryTime` are **two different things** that were conflated because the admin
panel reads `o.hours||o.deliveryTime` (`app.js:325`). Both are specified below, separately.

| Field | Type | Required | Written by | Read by | Notes |
|---|---|---|---|---|---|
| `name` | string | ✅ | admin | all | |
| `category` | string | ✅ | admin | customer, admin | `'Food'` \| `'Grocery'` \| `'Pharmacy'`. |
| `owner` | string \| null | — | admin | admin | |
| `phone` | string \| null | — | admin | admin | |
| `email` | string \| null | — | admin | admin | |
| `address` | string | ✅ | admin | driver, admin | The driver's pickup location. |
| `openingHours` | string | ✅ | admin | customer, admin | **Business hours**, display-only, e.g. `'9am–9pm'`. Renamed from `hours`. |
| `deliveryTime` | string | ✅ | admin | customer | **ETA estimate**, e.g. `'25–35 min'`. **The admin has no input for this today**, which is why every admin-created merchant shows the hardcoded `'25–35 min'` fallback (audit §6.1). P3-01 adds the input. |
| `deliveryFee` | int | ✅ | admin | customer | **Integer JMD** (§a). Replaces `fee: '$250'`. Customer renders "Free delivery" when `0`. This one field is currently three different numbers — configured, displayed, and charged (audit §6.1). |
| `isOpen` | bool | ✅ | admin | customer, admin | §e — `open` is deprecated. |
| `imageUrl` | string \| null | — | admin | customer, admin | Cover image. Written by upload in P4-01; the URL text field is retained as a secondary option since existing records depend on it. |
| `emoji` | string \| null | — | admin | customer | Display icon. **The admin has no input for this today**, so admin-created merchants fall back to a generic 🍽️ while seeded ones have bespoke icons. P4-02 adds a picker. |
| `promo` | string \| null | — | admin | customer | Badge text, e.g. `'🔥 Popular'`. No admin input today. |
| `totalRatings` | int | ✅ | server @ rating | — | |
| `ratingCount` | int | ✅ | server @ rating | admin | |
| `averageRating` | double | ✅ | server @ rating | customer, admin | **Nothing computes this today** — every merchant shows a permanent `5.0` (audit §11). The customer already collects `merchantRating` on the order and throws it away; P3-05 rolls it up. |
| `createdAt` | Timestamp | ✅ | admin | admin | |
| `updatedAt` | Timestamp | — | admin | — | |

**Deprecated / do not write:** `fee` (string), `hours` (→ `openingHours`), `open` (→ `isOpen`),
`rating` (→ `averageRating`), `ordersToday` (violates §d — **derived** in the admin from the loaded
orders array; the data is already in memory and needs no query), `image` (→ `imageUrl`).

### `merchants/{merchantId}/menuItems/{itemId}`

| Field | Type | Required | Written by | Read by |
|---|---|---|---|---|
| `name` | string | ✅ | admin | customer |
| `description` | string \| null | — | admin | customer |
| `price` | int | ✅ | admin | customer |
| `category` | string | ✅ | admin | customer |
| `imageUrl` | string \| null | — | admin | customer |
| `available` | bool | ✅ | admin | customer |

`category` is a lowercase slug: `'mains'` \| `'sides'` \| `'drinks'` \| `'desserts'`.
`available` is not written today; absent means available.

---

## `promoCodes/{CODE}`

**Document ID is the uppercased code itself** — this part is already correct on both sides
(`app.js:1119` writes `setDoc(doc(db,'promoCodes',code))`; the customer reads
`doc(code.toUpperCase())`), which is why lookup works and everything else fails.

Every other field in this collection disagrees between writer and reader (audit §5). The net effect
today: every code validates, applies **J$0**, never expires, and ignores its usage cap.

| Field | Type | Required | Written by | Read by | Notes |
|---|---|---|---|---|---|
| `code` | string | ✅ | admin | customer, admin | Uppercase; matches the document ID. |
| `discountType` | string | ✅ | admin | customer, functions | `'percent'` \| `'fixed'`. **The customer compares against `'percentage'`** today — never matches (audit §5). |
| `discountAmount` | int | ✅ | admin | customer, functions | Percent points, or JMD. **The customer reads `discount`** today — always `null → 0`, which is the J$0 discount. |
| `minOrderTotal` | int | ✅ | admin | customer, functions | `0` for no minimum. Not enforced today. |
| `maxDiscount` | int \| null | — | admin | customer, functions | **Caps percentage discounts.** A 100% code with no cap is an unbounded liability and nothing prevents an admin creating one by typo. |
| `expiresAt` | Timestamp \| null | ✅ | admin | customer, functions | §b. **The admin writes `validUntil` as a string** today; the customer reads `expiresAt` as a Timestamp — so expiry is never enforced. `null` = never expires. |
| `maxUses` | int | ✅ | admin | customer, functions | |
| `usedCount` | int | ✅ | **server only** (P3-03) | customer, admin | Never incremented today, so the cap is fiction. Server-only in rules, so the cap becomes real rather than advisory. |
| `active` | bool | ✅ | admin | customer, functions | The one field that already lines up. |
| `createdAt` | Timestamp | ✅ | admin | admin | |

**Deprecated / do not write:** `validUntil` (string → `expiresAt`), `discount` (→ `discountAmount`).

**Validation order** (both client-side for instant feedback and server-side for authority):
`active` → `expiresAt` → `usedCount < maxUses` → `subtotal >= minOrderTotal` → compute, capped by
`maxDiscount`.

Client validation is **never trusted**. Redemption increments `usedCount` transactionally in a
callable function (P3-03).

---

## `users/{uid}`

**Document ID is the Firebase Auth UID.** Private to its owner; admin gets read-only access
(needed by the Customers page, P5-05).

| Field | Type | Required | Written by | Read by | Notes |
|---|---|---|---|---|---|
| `name` | string | ✅ | customer | customer, admin | Denormalised onto orders. |
| `phone` | string | ✅ | customer | customer, admin | |
| `email` | string | ✅ | customer | customer, admin | Mirrors Auth. |
| `avatarUrl` | string \| null | — | customer | customer | |
| `fcmToken` | string \| null | — | customer | functions | **Nothing writes this today** — `firebase_messaging` is declared in `pubspec.yaml:44` and unused (audit §9). P4-03. Must be written on **login** and **cleared on logout**, or the next user of a shared device receives the previous user's notifications. |
| `notificationsReadAt` | Timestamp \| null | — | customer | customer | Drives the unread badge. |
| `disabled` | bool | — | admin | rules | Account suspension (P5-05). |
| `createdAt` | Timestamp | ✅ | customer | admin | |
| `updatedAt` | Timestamp | — | customer | — | |

### `users/{uid}/addresses/{addressId}`

| Field | Type | Required | Notes |
|---|---|---|---|
| `label` | string | ✅ | `'Home'`, `'Work'`, … |
| `text` | string | ✅ | The address itself. |
| `createdAt` | Timestamp | ✅ | Sort key. |

Same access as the parent: owner-only read/write, admin read-only.

---

## `notifications/{id}`

Admin-written broadcast log. Fanned out to devices by a Cloud Function (P4-04) — today nothing
sends, and the driver app does not read this collection at all, so selecting "All Drivers"
delivers to nobody (audit §9).

| Field | Type | Required | Written by | Read by | Notes |
|---|---|---|---|---|---|
| `title` | string | ✅ | admin | customer, functions | |
| `message` | string | ✅ | admin | customer, functions | |
| `target` | string | ✅ | admin | customer, functions | `'all'` \| `'customers'` \| `'drivers'` \| a specific UID. |
| `sentBy` | string | ✅ | admin | admin | Admin email, audit trail. |
| `createdAt` | Timestamp | ✅ | admin | all | |
| `deliveredCount` | int \| null | — | functions | admin | How many devices actually received it. Closes the loop between "logged" and "sent". |

---

## `settings/pricing`

Single document, admin-editable, introduced by P5-01 so package pricing is not hardcoded in the
client.

| Field | Type | Notes |
|---|---|---|
| `serviceFee` | int | Flat service fee applied to orders. |
| `driverCommissionRate` | double | Currently `0.10`, hardcoded at `driver_constants.dart:13`. **Server reads this** for the authoritative commission (P3-04); the client copy is display-only. |
| `packageRates` | array\<{maxKg: int, price: int}\> | Weight-band pricing for package deliveries. |

---

## Deprecated fields — migration index

Every field below exists in production data and must be migrated (P2-05) then removed. Readers
tolerate both shapes for **one release cycle** — sideloaded APKs may never update, so a hard cutover
would break clients in the field.

| Collection | Deprecated | Canonical | Migration |
|---|---|---|---|
| `orders` | `status: 'accepted'` | `'confirmed'` | Rewrite value. |
| `orders` | `amount` (string) | `total` (int) | Parse; drop. |
| `orders` | — | `discount: 0`, `promoCode: null` | Backfill. |
| `orders` | — | `type: 'food'` | Backfill. |
| `merchants` | `fee: '$250'` | `deliveryFee: 250` | Parse int; drop `fee`. |
| `merchants` | `hours` | `openingHours` | Rename. |
| `merchants` | — | `deliveryTime` | Backfill a default; **flag for manual admin review** — the real value cannot be derived. |
| `merchants` | `open` | `isOpen` | Consolidate; drop. |
| `merchants` | `rating` | `averageRating` | Seed from `rating`; recompute as ratings arrive. |
| `merchants` | `ordersToday` | *(derived)* | Delete the field. |
| `promoCodes` | `validUntil` (string) | `expiresAt` (Timestamp) | Parse; **log every failure** for manual review; `null` if unparseable. |
| `promoCodes` | `discount` | `discountAmount` | Rename where present. |
| `drivers` | `licensePlate` | `licencePlate` | Rename if any American-spelled docs exist. |
| `drivers` | `rating` | `averageRating` | Seed. |
| `drivers` | `todayEarnings` | *(derived)* | Delete the field. |
| `drivers` | *(random-ID docs)* | UID-keyed | **Do not auto-delete.** Export to CSV for manual reconciliation — some correspond to real people needing an account (P4-05). |

---

## Invariants

Assertable properties. The P2-05 verification script checks each; a violation is a bug.

1. `subtotal + deliveryFee + serviceFee - discount == total` on every order.
2. Every `orders.status` is one of the six canonical values.
3. Every `orders.driverId` is either `null` or an existing `drivers/{uid}` document ID.
4. Every `drivers` document ID is a valid Firebase Auth UID.
5. No order transitions out of `delivered` or `cancelled`.
6. `averageRating == totalRatings / ratingCount` wherever `ratingCount > 0`.
7. `usedCount <= maxUses` on every promo code.
8. No monetary field anywhere is a string or a non-integer.
9. Every timestamp field is a `Timestamp`, never a string.
10. No document in `merchants` was written by a client app.
