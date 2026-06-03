# Keep Track — Design System

Wolf-inspired personal finance app. Light mode: snow surfaces, midnight text. Dark mode: void/midnight surfaces, snow text.

---

## Brand Identity

- **Mascot**: Lobo the wolf
- **Personality**: Minimal, focused, trustworthy — not flashy
- **Voice**: Direct, purposeful ("Give every peso a purpose")
- **Fonts**: DM Sans (all UI text) + DM Mono (all numbers and currency)

---

## Color Tokens

### Source files
- `lib/core/theme/brand_theme.dart` — canonical color definitions (`AppColors`)
- `lib/core/theme/app_theme.dart` — semantic aliases (references `brand_theme.dart` in some places, duplicates in others — prefer `brand_theme.dart`)

### Palette

#### Grayscale (wolf fur)
| Token | Hex | Role |
|---|---|---|
| `AppColors.snow` | `#F1EFE8` | Light bg, primary btn foreground |
| `AppColors.ash` | `#D3D1C7` | Borders (light), tertiary text |
| `AppColors.wolfGray` | `#888780` | Secondary text (both modes) |
| `AppColors.ember` | `#444441` | Borders (dark mode) |
| `AppColors.midnight` | `#2C2C2A` | Primary text (light), dark surfaces |
| `AppColors.void_` | `#1E1E1C` | Dark mode background |

#### Brand accent colors
| Token | Light bg | Main | Dark text |
|---|---|---|---|
| Violet (insight/accent) | `violetLight #EEEDFE` | `violet #534AB7` | `violetDark #3C3489` |
| Teal (success/income) | `tealLight #E1F5EE` | `teal #1D9E75` | `tealDark #0F6E56` |
| Gold (savings/warning) | `goldLight #FAEEDА` | `gold #EF9F27` | `goldDark #633806` |
| Red (danger/expense) | `redLight #FCEBEB` | `red #E24B4A` | `redDark #A32D2D` |
| Blue (pro/cloud) | `blueLight #E6F1FB` | `blue #378ADD` | `blueDark #0C447C` |

#### Semantic aliases
```dart
AppColors.income   = AppColors.teal
AppColors.expense  = AppColors.red
AppColors.savings  = AppColors.gold
AppColors.pro      = AppColors.blue
AppColors.insight  = AppColors.violet
```

### Surfaces (resolved per mode)
| Role | Light | Dark |
|---|---|---|
| Background | `snow` | `void_` |
| Surface / Card | `#FFFFFF` | `midnight` |
| Border | `ash` | `ember` |
| Input fill | `#FFFFFF` | `midnight` |
| Input border | `ash` | `ember` |
| Input focus border | `midnight` | `snow` |

### Usage rules
- **Never** use raw `Color(0xFF...)` literals in widgets. Reference `AppColors.*` always.
- **Never** use `Colors.white` or `Colors.black` directly — use `AppColors.snow` / `AppColors.midnight`.
- For opacity variants (e.g. overlays on dark backgrounds), prefer `AppColors.snow.withValues(alpha: 0.06)` over raw literals.
- Text colors must be resolved via `AppTextStyles.*` or `Theme.of(context).colorScheme.*` — never hardcoded.

---

## Typography

### Source files
- `brand_theme.dart` → `AppTextStyles` (context-aware methods, preferred)
- `app_theme.dart` → `AppTextStyles` with static fallbacks (for `ThemeData` where no `BuildContext` is available)

### Type scale
| Token | Font | Size | Weight | Use |
|---|---|---|---|---|
| `display` | DM Sans | 36 | 600 | Hero numbers, splash |
| `h1` | DM Sans | 30 | 600 | Page titles |
| `h2` | DM Sans | 24 | 600 | Section headers |
| `h3` | DM Sans | 20 | 600 | Card titles, app bar |
| `h4` | DM Sans | 16 | 600 | Sub-section labels |
| `bodyLarge` | DM Sans | 16 | 400 | Primary body copy |
| `bodyMedium` | DM Sans | 14 | 400 | Default body |
| `bodySmall` | DM Sans | 13 | 400 | Secondary body (wolfGray) |
| `label` | DM Sans | 14 | 500 | Form labels, buttons |
| `labelSmall` | DM Sans | 12 | 500 | Tags, chip text |
| `caption` | DM Sans | 12 | 400 | Timestamps, hints |
| `muted` | DM Sans | 14 | 400 | Placeholder, empty states |
| `currency` | DM Mono | 24 | 500 | Amounts in cards |
| `currencyLarge` | DM Mono | 32 | 500 | Hero amounts |
| `currencySmall` | DM Mono | 14 | 500 | Inline amounts |
| `currencyMono` | DM Mono | 16 | 400 | Tabular figures in lists |

### Usage rules
- Use `AppTextStyles.h3(context)` (context-aware) everywhere except `ThemeData` construction.
- Use static variants (`AppTextStyles.h3Static`) only inside `ThemeData` builders.
- **Never** call `GoogleFonts.dmSans(...)` directly in widget files. Go through `AppTextStyles`.
- All currency/amount text must use a `DM Mono` style (`currency*` tokens) for tabular alignment.

---

## Spacing

4px base grid. Source: `AppSpacing` in `brand_theme.dart`.

| Token | Value | Use |
|---|---|---|
| `xs` | 4px | Icon gaps, tight padding |
| `sm` | 8px | Between related elements |
| `md` | 16px | Standard content padding |
| `lg` | 24px | Section separation |
| `xl` | 32px | Between major blocks |
| `xxl` | 48px | Hero sections |
| `xxxl` | 64px | Screen-level vertical rhythm |

### Preset insets
```dart
AppSpacing.screenPadding      // EdgeInsets.all(16)
AppSpacing.screenPaddingH     // EdgeInsets.symmetric(horizontal: 16)
AppSpacing.screenPaddingV     // EdgeInsets.symmetric(vertical: 16)
AppSpacing.cardPadding        // EdgeInsets.all(16)
AppSpacing.cardPaddingLarge   // EdgeInsets.all(24)
```

---

## Border Radius

Source: `AppRadius` in `brand_theme.dart`.

| Token | Value | Use |
|---|---|---|
| `sm` | 6px | Small chips, tight containers |
| `md` | 8px | Inputs, standard buttons |
| `lg` | 12px | Cards, sheets |
| `xl` | 16px | Large cards, modals |
| `full` | 9999px | Pills, avatar circles |

### Convenience getters
```dart
AppRadius.circularSm   // BorderRadius.circular(6)
AppRadius.circularMd   // BorderRadius.circular(8)
AppRadius.circularLg   // BorderRadius.circular(12)
AppRadius.circularXl   // BorderRadius.circular(16)
```

---

## Shadows

Source: `AppShadows` in `brand_theme.dart`. All use near-black with very low opacity — keep UI feeling light.

| Token | Blur | Offset | Use |
|---|---|---|---|
| `subtle` | 2px | (0,1) | Hover state, focused input |
| `sm` | 4px | (0,1) | Cards, chips |
| `md` | 8px | (0,2) | Elevated cards, dropdowns |
| `lg` | 16px | (0,4) | Modals, sheets |

Usage: always wrap in a `List<BoxShadow>`:
```dart
decoration: BoxDecoration(
  boxShadow: [AppShadows.sm],
)
```

---

## Buttons

Source: `AppButtons` in `brand_theme.dart`.

| Style | Background | Foreground | Use |
|---|---|---|---|
| `primary` | midnight | snow | Main CTA (light mode) |
| `primaryDark` | snow | midnight | Main CTA (dark mode) |
| `secondary` | ash | midnight | Secondary action |
| `outline` | transparent | midnight/snow | Tertiary, bordered |
| `ghost` | transparent | midnight/snow | Inline, low emphasis |
| `destructive` | red | white | Destructive confirm |
| `pro` | blue | white | Pro-tier feature gate |

All buttons share:
- `elevation: 0`
- `padding: 24h × 12v`
- `borderRadius: AppRadius.md (8px)`
- `textStyle: DM Sans 14 w500`

---

## Badges / Status Pills

Source: `AppBadgeColors` in `brand_theme.dart`.

Each badge state has `bg` + `text` variants for both light and dark mode.

| State | Light bg | Light text | Dark bg | Dark text |
|---|---|---|---|---|
| Under budget | `tealLight` | `tealDark` | `#04342C` | `#9FE1CB` |
| Over budget | `redLight` | `redDark` | `#501313` | `#F7C1C1` |
| Goal / savings | `goldLight` | `goldDark` | `#412402` | `#FAC775` |
| Pro | `blueLight` | `blueDark` | `#042C53` | `#85B7EB` |
| Insight / AI | `violetLight` | `violetDark` | `#26215C` | `#CECBF6` |

---

## Status Colors (priority / task state)

Resolved via `AppTheme` helper methods in `app_theme.dart`.

```dart
AppTheme.getPriorityColor('urgent')    // red
AppTheme.getPriorityColor('high')      // gold
AppTheme.getPriorityColor('medium')    // violet
AppTheme.getPriorityColor('low')       // wolfGray

AppTheme.getStatusColor('completed')   // teal
AppTheme.getStatusColor('in_progress') // blue
AppTheme.getStatusColor('todo')        // gold
```

---

## Theme

Light and dark `ThemeData` are constructed in `brand_theme.dart` and exposed via `AppTheme.lightTheme` / `AppTheme.darkTheme` from `theme.dart`.

```dart
MaterialApp(
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
)
```

Key ThemeData mappings:
- `scaffoldBackgroundColor` → `snow` / `void_`
- `colorScheme.primary` → `midnight` / `snow`
- `cardTheme` → 0 elevation, `lg` radius, `0.5px` border
- `inputDecorationTheme` → filled white/midnight, `md` radius, 2px focus border
- `dividerTheme` → `0.5px`, `borderLight` / `borderDark`
- `appBarTheme` → 0 elevation, `h3Static` title

---

## Known Inconsistencies (to fix)

These are places where the design system is not yet followed:

1. **`welcome_screen.dart`** — uses `const Color(0xFF1E1E1C)` instead of `AppColors.void_`
2. **`welcome_screen.dart`** — calls `GoogleFonts.dmSans(...)` directly instead of `AppTextStyles.*`
3. **`welcome_screen.dart`** — uses `Colors.white.withValues(alpha: ...)` instead of `AppColors.snow.withValues(...)`
4. **`finance_main_screen.dart`** — uses `.withOpacity()` (deprecated) and raw `TextStyle(fontSize: 13)` instead of `AppTextStyles`
5. **`app_theme.dart` vs `brand_theme.dart`** — both define `AppColors` and `AppTextStyles`, causing duplication. `brand_theme.dart` is canonical; `app_theme.dart`'s local `AppColors` class should be deleted and imports updated to use `brand_theme.dart`.

---

## File Reference

```
frontend/lib/core/theme/
├── brand_theme.dart   ← canonical: AppColors, AppTextStyles, AppButtons, AppSpacing,
│                                   AppRadius, AppShadows, AppBadgeColors, getLightTheme(), getDarkTheme()
├── app_theme.dart     ← AppTheme entry point: exposes lightTheme/darkTheme, getPriorityColor, getStatusColor
│                        (also contains a duplicate AppColors — should be removed)
├── gcash_theme.dart   ← legacy reference theme (do not use)
└── theme.dart         ← re-exports AppTheme
```
