# Keep Track Landing — Marketing Site

The public marketing/checkout site for Keep Track (Next.js app in `landing/`, a separate nested repo from the Flutter app). Covers the homepage, download, changelog, pricing, legal, and Lemon Squeezy checkout flow.

## Language

**Night Ledger**:
The design language the site is being rebuilt in — dark-first, JetBrains Mono + DM Sans, near-black `#0D0F0E` background, mint `#4ADE9B` accent, lavender `#C7B9FF` links. Chosen from four candidate directions (Paper & Violet — the prior system, The Ledger, Night Ledger, Soft Deposit) explored in the "Keep Track design language" Claude Design project, and now replaces Paper & Violet as the site's one design system — applied to every route, not toggled per page.
_Avoid_: "the new theme", "dark mode" (this isn't a light/dark toggle, it's a full system replacement)

**Paper & Violet**:
The prior design language (superseded by Night Ledger): warm paper `#F1EFE8` background, violet `#534AB7` accent, midnight `#2C2C2A` used sparingly as punctuation, DM Sans + DM Mono. Documented in the design project's `Design Language.dc.html`.
_Avoid_: referring to it as just "the old site" — it was a fully documented system, not an undocumented legacy state

**Day Ledger**:
The light-mode counterpart to Night Ledger, toggled via the sun/moon button in the nav (persisted to `localStorage` under `kt-theme`, defaulting to the visitor's OS preference). Not a separate design mockup — there was no light-mode canvas to work from, so it's derived from Night Ledger's own tokens: every color is a CSS variable (`--color-*` in `globals.css`) that resolves to Night Ledger's dark values by default and to a light, paper-toned set under `[data-theme='light']`. Accent colors (mint, lavender, coral) deliberately invert lightness between the two themes — bright in Night Ledger, deepened in Day Ledger — so `bg-mint text-ink` (and equivalents) keep working as one pairing in both themes rather than needing per-theme overrides at each call site.
_Avoid_: treating it as a from-scratch palette choice — new tokens here should extend the existing CSS-variable pairing, not hardcode a hex value that only works in one theme
