# Phase 0 — Foundations · Status

**Plan:** [execution-all-three-plan.md](execution-all-three-plan.md) §Phase 0
**Audit:** [all-three-apps-audit.md](all-three-apps-audit.md)
**Branch:** `feat/admin-seds` · **Date:** 2026-07-21

Phase 0's goal is *"make it possible to change things safely"*. It is a prerequisite for every
later phase, and it is deliberately not a code-change phase.

| Item | Status | Notes |
|---|---|---|
| P0-01 — Staging Firebase project | 🟡 **Code prerequisite done; project not created** | Needs Firebase Console access — see below |
| P0-02 — Install and pin the toolchain | 🟡 **Pinned; not installed, no baseline** | Needs a machine with Flutter — see below |
| P0-03 — Add real CI gates | 🟢 **Done** | Branch protection is a repo setting — see below |
| P0-04 — Write the schema of record | 🟢 **Done** | [SCHEMA.md](SCHEMA.md) |
| P0-05 — Freeze feature work | 🟢 **Declared** | Below |

---

## What landed

### P0-04 — `SCHEMA.md` (the phase's main deliverable)

[SCHEMA.md](SCHEMA.md) is the single source of truth every later phase implements against. It
specifies every field of `orders`, `drivers`, `merchants`, `merchants/{id}/menuItems`, `promoCodes`,
`users`, `users/{uid}/addresses`, `notifications`, and `settings/pricing` — with its **type, who
writes it, who reads it, and whether it is required**.

It locks in the six decisions the plan requires:

- **(a) Canonical order status** — `pending → confirmed → picked_up → in_transit → delivered`, plus
  `cancelled`. `accepted` is removed from the vocabulary entirely; nothing ever wrote it. Legal
  transitions are specified once and must be mirrored in three places (the shared constant, the
  admin dropdown, and `firestore.rules`).
- **(b) British spelling** for `licencePlate` / `licenceNumber` — both current *writers* already use
  it; only the customer *reader* is wrong, so this fixes one reader instead of migrating two writers.
- **(c) Money as integer JMD** — no symbols, no decimals, no separators in storage. Kills
  `fee: '$250'` and the `amount`/`rawTotal` dual-read.
- **(d) Timestamps always `Timestamp`** — kills `validUntil: '2026-08-01'`.
- **(e) Merchant field names** — the customer app's names win, and the conflated
  `hours`/`deliveryTime` pair is split into `openingHours` (business hours) and `deliveryTime` (ETA),
  which are two different things the admin form currently cannot both express.
- **(f) Derived vs stored** — counters that reset on a clock boundary are never stored.

It also carries a **deprecated-field migration index** (the input to P2-05) and ten **assertable
invariants** for the post-migration verification script.

Every field currently written by any of the three apps appears in it, either as canonical or as
explicitly deprecated-with-a-migration-path, which is the plan's stated acceptance criterion.

### P0-03 — CI gates

**New: [`.github/workflows/verify.yml`](.github/workflows/verify.yml)**

- Runs on pull requests, pushes to `main`, and manual dispatch.
- Matrix over `[customer_app, driver_app]`: `flutter pub get` → `flutter analyze` → `flutter test`.
- Admin job: `node --check app.js` → `eslint app.js`.
- Reads the Flutter version from `.tool-versions` rather than tracking `channel: stable`, so an
  upstream Flutter release cannot silently change the build.

**Analyzer strictness.** Errors fail the job; warnings and infos are reported but do not. The plan
calls for exactly this until P6-02 clears the pre-existing baseline — gating on the baseline today
would block every PR on unrelated findings.

**Gating the release artifacts.** `verify.yml` is a *reusable* workflow, and both APK workflows now
declare it as a dependency:

```yaml
jobs:
  verify:
    uses: ./.github/workflows/verify.yml
  build-apk:
    needs: verify
```

This matters more than it looks: `needs:` only works between jobs *within one workflow file*, so a
standalone verify workflow could not have gated the APK builds. Before this change, both workflows
built and **published a GitHub Release** on every push to `main` without ever running `analyze` or
`test`.

Both APK workflows now also use the pinned Flutter version, so the APK is built with the same
toolchain that verified it. The driver workflow's `flutter analyze || true` step was removed —
analysis is now a real gate in `verify`, not an informational step that discards its own result.

**Admin lint.** [`admin_panel/eslint.config.js`](admin_panel/eslint.config.js) is scoped to
correctness rules only, not style. `app.js` is 1,400+ lines of terse, internally consistent working
code; a stylistic ruleset would produce hundreds of findings nobody will action and would train the
team to ignore the linter.

`app.js` was **verified clean** against this config. Three findings surfaced and all three were
resolved properly rather than suppressed: `performance` was a genuine gap in my globals list, and
two `catch(e){}` blocks around `localStorage` (which throws when cookies are blocked) became
`catch{}` — the deliberate-empty-catch intent is now explicit and the rule stays strict.

### P0-01 — Environment selection (code prerequisite)

**New: [`admin_panel/config.js`](admin_panel/config.js).** The Firebase config block moved out of
the middle of `app.js`; `app.js` now imports it.

Environment resolves by hostname from an explicit allowlist, with an `?env=` override. Behaviour:

| URL | Environment | Result |
|---|---|---|
| `console.shipeast.app`, `shipeast-1a1f6.web.app` | prod | Config as today, **no banner — production is visually unchanged** |
| `shipeast-staging.web.app`, `localhost` | staging | **Refuses to start** until staging config is filled in |
| `localhost/?env=prod` | prod | Works, with a **red** "PRODUCTION · live customer data" banner |
| any unknown `?env=` | — | Refuses to start |

Two deliberate design points:

- **It fails closed.** An environment with no config refuses to start rather than silently falling
  back to production. A developer who asked for staging and got production without noticing is the
  worst outcome this file can produce.
- **The banner is the real safety control**, not the resolution logic. Any non-production
  environment — and any *forced* production from a non-production host — paints a persistent bar
  across the top. An admin can always see which database they are about to mutate.

The `?env=prod` override exists because mapping `localhost` to staging would otherwise make local
panel development impossible until the staging project exists. A deliberate override is safe; a
silent default is not.

**Verified** by executing the module under stubbed browser globals across all six cases above —
6/6 as specified, including that the production deployment's behaviour is unchanged.

Also added: `admin_panel/.gitignore` (the repo had **no `.gitignore` at all**, so `node_modules/`
would have been committed) and `package.json`/`eslint.config.js`/`package-lock.json` added to the
hosting `ignore` list, since `admin_panel/` is the hosting root and those would otherwise be served
publicly.

### P0-05 — Change freeze (declared)

**`main` is frozen to bug fixes for the duration of Phases 1–3.**

Phases 1–3 rewrite the shape of live data across all three apps. Concurrent feature work on the same
files will conflict badly, and — more dangerously — a feature merged mid-migration can reintroduce
one of the eleven schema mismatches this work exists to remove.

- Bug fixes only, and only with awareness of the in-flight migration.
- Any change touching `orders`, `drivers`, `merchants`, `promoCodes`, or `users` **must** cite the
  `SCHEMA.md` section it complies with.
- New fields land in `SCHEMA.md` first, in their own PR, before any code writes them.

---

## What is blocked, and on whom

These are not oversights. Each needs access or a machine I do not have, and **guessing at them would
have been worse than leaving them**.

### 1. Create the staging Firebase project — *needs Firebase Console access*

P0-01 steps 1–3 and 5. Requires creating `shipeast-staging`, enabling Auth/Firestore/Storage,
exporting production Firestore and importing it, and running `flutterfire configure`.

To finish, once the project exists:

1. Run `firebase apps:sdkconfig web` against `shipeast-staging` and paste the block into the
   `staging:` slot in [`admin_panel/config.js`](admin_panel/config.js) — the slot is already there
   with a comment. **Do not hand-write it**; a typo'd `projectId` either fails opaquely or resolves
   to a real project that is not the intended one.
2. Add a second Hosting target and map it in `.firebaserc`.

**I deliberately did not convert `admin_panel/firebase.json` to a multi-target config.** Doing so
requires `firebase target:apply` to have been run against sites that do not exist yet, and would
break the working production deploy in the meantime.

**I also deliberately did not create `firebase_options_staging.dart` in either app.** Those files
contain real API keys, app IDs, and sender IDs that only `flutterfire configure` can generate.
Fabricating plausible-looking values would produce a file that compiles and fails at runtime in a
confusing way — strictly worse than its absence.

### 2. Install Flutter and capture the analyzer baseline — *needs a machine with the toolchain*

P0-02 steps 1, 3, 4. There is no Flutter or Dart toolchain in this environment
(`flutter: command not found`), so I could not run `flutter analyze`, `flutter test`, or build
either app. This is the same gap the audit called out in its honesty statement.

What *was* done: the version is pinned in [`.tool-versions`](.tool-versions), and the value is
**grounded in the repo's own lockfiles** rather than guessed —
`customer_app/pubspec.lock` and `driver_app/pubspec.lock` both record `flutter: ">=3.38.4"` and
`dart: ">=3.11.5"`. That is the toolchain that produced the committed lockfiles.

**The first CI run on this branch is the baseline capture** (P0-02 step 3). Record its output in the
PR description.

> ⚠️ **Watch that first run.** `customer_app/test/widget_test.dart` pumps `ShipEastApp()`, whose
> splash screen reaches Firebase — but the test never calls `Firebase.initializeApp`, which `main()`
> normally does. I could not run it to confirm, but **it may well fail**, and because the APK
> workflows now depend on `verify`, a failing test blocks releases.
>
> If it fails, that is a real finding, not a CI misconfiguration — it means the only customer-app
> test has never actually verified anything. The proper fix is P6-01 (replace both placeholder
> tests). To unblock releases meanwhile, remove the `- name: Test` step from `verify.yml` and open a
> ticket; do **not** weaken it to `flutter test || true`, which reports false confidence in CI
> exactly the way `driver_app`'s `expect(true, isTrue)` placeholder already does.

### 3. Enable branch protection — *needs repo admin*

P0-03 step 4: require `verify` to pass on `main`. This is a GitHub repository setting, not a file.
Settings → Branches → add a rule for `main` → require status checks → select `Verify`.

Until this is set, `verify` runs and reports but nothing *enforces* it on merge.

---

## Phase 0 exit criteria

| Criterion | Met |
|---|---|
| `SCHEMA.md` reviewed and merged before any Phase 1 code | ⬜ **Needs your review** — this is the gate |
| Every field written by any app appears in `SCHEMA.md` | 🟢 |
| `flutter analyze` / `flutter test` execute and are recorded as a baseline | ⬜ Blocked — first CI run |
| A PR with a deliberate error is blocked by CI | ⬜ Blocked on branch protection |
| APK workflows do not publish when `verify` fails | 🟢 |
| Staging reachable by all three apps with zero writes to prod | ⬜ Blocked — project not created |
| Change freeze announced | 🟢 |

**Phase 1 must not start until `SCHEMA.md` is reviewed.** The plan is explicit that skipping it
re-creates the root cause, and its own estimate calls it *"the highest-leverage document in the
project. Do not rush it."* The status vocabulary in §orders and the money/timestamp conventions are
the parts most worth arguing about now rather than after Phase 1 code implements them.
