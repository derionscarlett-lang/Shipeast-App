# ShipEast — Design System Master File

> **LOGIC:** When building a specific page, first check `design-system/shipeast/pages/[page-name].md`.
> If that file exists, its rules **override** this Master file.
> If not, strictly follow the rules below.

**Project:** ShipEast (customer app)
**Platform:** Flutter (Material 3, light mode)
**Category:** Logistics / Food & Package Delivery

> Source of truth in code: `lib/theme/app_theme.dart` (tokens + `ThemeData`)
> and the shared widget library in `lib/widgets/`. Keep this doc and the code in sync.

---

## Brand & Color

Brand primary is **`#C8102E`** on a **soft-white** background. Light mode only.

| Role | Token (`AppTheme.`) | Hex |
|------|---------------------|-----|
| Primary | `primary` | `#C8102E` |
| Primary (pressed) | `primaryDark` | `#A00C24` |
| Primary tint (surfaces) | `primaryLight` | `#FFF0F2` |
| Active input fill | `primaryTint` | `#FFF8F9` |
| On primary | — | `#FFFFFF` |
| Background (scaffold) | `background` | `#F8F8FA` (soft white) |
| Surface (cards) | `surface` | `#FFFFFF` |
| Text primary | `textPrimary` / `dark` | `#111111` |
| Text secondary | `textSecondary` / `gray` | `#666666` |
| Text muted | `textMuted` | `#888888` |
| Hint | `hint` | `#999999` |
| Border | `border` / `inputBorder` | `#EBEBEB` |
| Divider | `divider` | `#EFEFEF` |
| Input fill | `inputBg` | `#F5F5F7` |
| Inactive (nav) | `inactive` | `#C0C0C0` |
| Success | `success` | `#16A34A` |
| Warning / Accent | `warning` / `accent` | `#F97316` |
| Error / Destructive | `error` | `#DC2626` |
| Rating gold | `gold` | `#F5B301` |

## Typography

Google Fonts, loaded via `google_fonts`. Three families by role:

- **Montserrat** — display & headlines (w800–w900). `displayLarge/Medium`, `headlineSmall`, app bar titles.
- **Nunito** — titles, labels, buttons, badges (w700–w900). `titleLarge/Medium/Small`, `labelLarge/Medium`.
- **Inter** — body & hints (w400–w600). `bodyLarge/Medium/Small`.

Type scale (px): 9 · 10 · 11 · 12 · 13 · 14 · 16 · 18 · 24 · 28.

## Spacing (4 / 8 rhythm)

`spaceXs 4` · `spaceSm 8` · `spaceMd 16` · `spaceLg 24` · `spaceXl 32`.

## Radius

`radiusSm 8` · `radiusMd 11` (buttons, inputs) · `radiusLg 16` (cards) · `radiusXl 22` (pills/chips).

## Elevation / Shadow

`shadowSm` (cards, subtle lift) · `shadowMd` (sheets) · `shadowLg` (modals). Soft, low-opacity black.

## Motion

Durations: `fast 150ms` (press feedback) · `normal 220ms` (entrances/state) · `slow 320ms`.
Easing: ease-out for enter, exit faster than enter. Built on `flutter_animate` via
`AppMotion` extension (`fadeSlideIn`, `popIn`). Micro-interactions stay 150–300ms.

---

## Component Library (`lib/widgets/`)

Import everything via the barrel: `import '../widgets/widgets.dart';`

| Component | File | Purpose |
|-----------|------|---------|
| `AppButton` | `app_button.dart` | Primary/secondary/outline/ghost CTA; loading spinner, icon, trailing arrow, press-scale |
| `AppTextField` | `app_text_field.dart` | Labeled input; password toggle, active tint, prefix icon |
| `AppCard` | `app_card.dart` | Standard surface; optional tap + press feedback, border/elevation variants |
| `AppTopBar` | `app_top_bar.dart` | Circular back button + title/subtitle + trailing action (`PreferredSizeWidget`) |
| `AppBottomNav` | `app_bottom_nav.dart` | Fixed ≤5-item bottom nav, icon+label, active tint, badge support |
| `CountBadge` / `StatusBadge` | `app_badge.dart` | Numeric count bubble; coloured status pill |
| `Pressable` | `pressable.dart` | Reusable press-scale wrapper |
| `ShimmerBox` / `ShimmerLine` / `ShimmerCard` / `ShimmerList` | `shimmer_box.dart` | Skeleton loaders |
| `AppMotion` | `app_motion.dart` | `flutter_animate` entrance presets |

Buttons, inputs, cards, app bar, snackbars, chips and FAB are also themed globally
via `AppTheme.theme`, so raw Material widgets inherit the system automatically.

---

## Rules

- One primary CTA per screen; secondary actions visually subordinate.
- Touch targets ≥ 44×44; bottom nav max 5 items with icon **and** label.
- Press feedback within ~150ms; no layout-shifting transforms.
- Text contrast ≥ 4.5:1; never rely on colour alone (pair with icon/text).
- Respect top/bottom safe areas for headers, bottom nav and FAB/CTA bars.
- Use vector `Icons` (Material), never emoji as structural icons.
- Use semantic tokens from `AppTheme`, not ad-hoc hex in screens.

## Anti-Patterns (Do NOT use)

- ❌ Changing the primary away from `#C8102E` or using AI purple/pink gradients.
- ❌ Emoji as navigation/system icons.
- ❌ Instant (0ms) state changes or animations > 500ms.
- ❌ Raw hex scattered in widgets instead of `AppTheme` tokens.
- ❌ Low-contrast gray-on-gray text.
