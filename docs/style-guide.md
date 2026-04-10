# kyleboon.org — Style Guide

The design system for this site. Reference this document in design conversations so decisions stay consistent over time.

## 1. Principles

1. **Zero JavaScript.** No exceptions. Everything is HTML + CSS, progressively enhanced via media queries and `:has()` if needed.
2. **No CSS framework or library.** One hand-written stylesheet. Tokens via CSS custom properties.
3. **Extremely fast.** Total page weight under ~150KB on first paint. Fonts self-hosted, preloaded, subset to Latin.
4. **Professional without being boring.** Personality comes from typography, color, and craft — **never** from rhetorical flourishes, italic-accent headlines, manifesto copy, or literary poses. When in doubt, choose restraint.
5. **Paper-and-ink metaphor.** The site reads as paper in both light and dark modes. Warm cream by day, cocoa by night. This is the conceptual anchor for every color and type decision.
6. **Accessible by default.** Semantic HTML, `prefers-color-scheme`, `prefers-reduced-motion`, visible focus states, `:visited` links, `aria-current` on nav.

## 2. Typography

### Families

| Role | Family | Format | Source |
|---|---|---|---|
| Display / headings | **Fraunces** (variable, `opsz` + `SOFT` axes) | `.woff2` | Self-hosted `/assets/fonts/fraunces-latin-var.woff2` |
| Body / UI | **Inter** (variable) | `.woff2` | Self-hosted `/assets/fonts/inter-latin-var.woff2` |
| Monospace | `ui-monospace, "SF Mono", "JetBrains Mono", Menlo, monospace` | system fallback chain | No download |

**Rules:**

- Fonts are self-hosted under `/assets/fonts/` (CSP requires `font-src 'self'`).
- `@font-face` declares `font-display: swap` so text paints on system fallback immediately.
- Fraunces and Inter woff2 files are preloaded in `<head>` via `<link rel="preload" as="font" crossorigin>`.
- Only Latin subset. No icon fonts. No extra weights beyond what the variable file provides.

### Scale

Fluid with `clamp()`. All sizes relative to the 18px root.

| Element | Size | Family | Weight | Line height | Letter spacing |
|---|---|---|---|---|---|
| Home H1 | `clamp(3rem, 7vw, 5rem)` | Fraunces | 600 | 0.95 | -0.035em |
| Page H1 | `clamp(2rem, 4vw, 2.75rem)` | Fraunces | 600 | 1.05 | -0.02em |
| H2 | `1.625rem` | Fraunces | 600 | 1.15 | -0.015em |
| H3 | `1.25rem` | Fraunces | 600 | 1.25 | -0.01em |
| Body | `1.125rem` | Inter | 400 | 1.65 | 0 |
| Tagline | `1.25rem` | Inter | 400 | 1.5 | 0 |
| Eyebrow | `0.75rem` | Inter | 600 | 1 | 0.14em |
| Post title in list | `1.25rem` | Fraunces | 500 | 1.3 | -0.005em |
| Meta / date | `0.8125rem` | Inter | 500 | 1.4 | 0.02em |
| Nav | `0.875rem` | Inter | 500 | 1 | 0 |
| Footer | `0.8125rem` | Inter | 400 italic | 1.5 | 0 |

### Fraunces axes

- **Opsz** — optical size. Use larger values (96–144) on display sizes, smaller (14–24) on body-size serifs.
- **SOFT** — softness. Use 30–50 on display headlines for a warmer cut. Default (0) on smaller sizes.
- Set via `font-variation-settings: "opsz" 144, "SOFT" 40;` on the H1, `"opsz" 24;` on post titles, etc.

## 3. Color

All color flows through CSS custom properties. Two palettes, swapped by `prefers-color-scheme`.

### Light palette (`:root`)

| Token | Value | Use |
|---|---|---|
| `--paper` | `#f6f1e8` | Page background |
| `--ink` | `#201612` | Body text, H1/H2/H3 |
| `--ink-muted` | `#3a2b24` | Tagline, post descriptions |
| `--ink-dim` | `#7a5b4a` | Dates, eyebrow labels, metadata |
| `--rust` | `#b5581f` | Links, accent, drop cap, accent period |
| `--rust-visited` | `#8a4520` | Visited links |
| `--rust-soft` | `rgba(181,88,31,0.08)` | Pill fill, quiet highlight |
| `--rule` | `rgba(32,22,18,0.12)` | Dividers, borders |
| `--rule-soft` | `rgba(32,22,18,0.06)` | Subtle separators |

### Dark palette (`@media (prefers-color-scheme: dark)`)

| Token | Value | Use |
|---|---|---|
| `--paper` | `#1c140e` | Page background (cocoa) |
| `--ink` | `#f0e6d6` | Body text, H1/H2/H3 |
| `--ink-muted` | `rgba(240,230,214,0.78)` | Tagline, post descriptions |
| `--ink-dim` | `#c29876` | Dates, eyebrow, metadata |
| `--rust` | `#d08858` | Links, accent, drop cap |
| `--rust-visited` | `#a76a42` | Visited links |
| `--rust-soft` | `rgba(208,136,88,0.10)` | Pill fill |
| `--rule` | `rgba(240,230,214,0.12)` | Dividers, borders |
| `--rule-soft` | `rgba(240,230,214,0.06)` | Subtle separators |

### Usage rules

- **Never introduce a new hue** outside this palette without updating this document first. No green, blue, or purple accents.
- **Rust is for emphasis, not decoration.** It appears on links, visited-link dimming, the eyebrow label, drop caps, and focus outlines. Nothing else.
- **Ink has three weights** (ink / ink-muted / ink-dim) — use them to create hierarchy. Don't reach for additional grays.

## 4. Layout

### Reading measure

| Breakpoint | Max width | Body padding |
|---|---|---|
| Mobile (< 768px) | `100%` | `1.25rem` |
| Tablet (≥ 768px) | `48rem` | `2rem` |
| Desktop (≥ 1200px) | `54rem` | `2rem 3rem` |

Body is centered via `margin: 0 auto`.

### Spacing

- Base unit: `0.25rem` (4px)
- Section gaps: `2.5rem` between major sections, `1.5rem` within a section
- Post list row: `1rem` vertical padding
- Nav: `1rem` vertical padding, `1.75rem` between links

### Radii

Only two allowed:

- `--radius: 4px` — cards, pre/code blocks, book items
- `--radius-pill: 999px` — quick-link pills, tag pills, nothing else

Profile photo is circular (`border-radius: 50%`) — it's a photo, the exception proves the rule.

## 5. Components

### Navigation (page layout)

Sticky top, `border-bottom: 1px solid var(--rule)`, Inter 0.875rem. Hover changes color to `--rust`, no underline. `aria-current="page"` gets `font-weight: 600` and `color: var(--ink)`.

Home layout intentionally does NOT use this nav — it uses the hero pills instead.

### Home hero

Two-column on ≥ 768px, stacked on mobile:

```
[ circular photo ]  PRINCIPAL SOFTWARE ENGINEER      <- eyebrow (Inter, uppercase, dim)
   120×120         Kyle Boon                          <- oversized Fraunces H1
                    Principal Software Engineer …     <- tagline (Inter, muted)
                    [Resume] [GitHub] [LinkedIn] …    <- quick-link pills
```

The eyebrow is the signature element — small, quiet, always there.

### Blog list

Desktop: two-column grid. 9rem date column on left (Inter, uppercase, letter-spaced, `--ink-dim`), title column on right (Fraunces, `--ink`, hovers to `--rust`). Border-top between items using `--rule-soft`.

Mobile: stacks. Date appears above title in the same dim treatment.

### Blog post

Above the H1, a meta row:

```
MARCH 16, 2025 · WRITING       <- eyebrow treatment (Inter, uppercase, dim, rust center dot)
```

H1 follows (Fraunces, Page H1 scale). Body has a **drop cap** on the first paragraph:

- Fraunces italic (`font-style: italic`)
- `font-size: 5.5rem`
- `float: left`
- `line-height: 0.85`
- Margins: `0.5rem 0.75rem -0.25rem 0`
- Color: `var(--rust)`
- `font-variation-settings: "opsz" 144, "SOFT" 50;`

Drop cap only fires on blog posts. Scoped to `.post-body > p:first-of-type::first-letter`.

### Quick-link pills

Inline-block. `padding: 0.4rem 1rem`. `border: 1px solid var(--rule)`. `border-radius: var(--radius-pill)`. `font-size: 0.8125rem`. Hover: border becomes `--rust`, text becomes `--rust`. No background fill change.

### Book cards

Grid with 120px cover column + flexible content. Divider between items is `border-top: 1px solid var(--rule-soft)`, NOT a card box. Cover is 120×180, `border-radius: var(--radius)`. No shadow. No hover lift.

Title is Fraunces H3, author is Inter italic in `--ink-dim`, description is body text.

### Footer

Inter 0.8125rem italic, `color: var(--ink-dim)`. Separators are the pipe character (not bullets or slashes). Stays quiet.

## 6. Motion

- All transitions: `150ms ease` on color/border-color only. No transform, no translate, no scale on UI chrome.
- Hover states change color or border-color. Nothing moves.
- `@media (prefers-reduced-motion: reduce) { *, *::before, *::after { transition: none !important; animation: none !important; } }`

## 7. Accessibility

- `:focus-visible` outline: `2px solid var(--rust)`, `outline-offset: 2px`, `border-radius: var(--radius)` where applicable
- `:visited` links use `var(--rust-visited)`
- Skip-to-content link stays (`.sr-only` until focused)
- `aria-current="page"` on the active nav link
- Color contrast ratio on all text vs paper is ≥ 4.5:1 (WCAG AA)
- `prefers-reduced-motion` honored
- `prefers-color-scheme` honored

## 8. Performance budget

| Resource | Budget | Actual target |
|---|---|---|
| HTML (home) | 5KB | ~3KB |
| CSS | 12KB | ~10KB |
| Fonts (2 variable woff2) | 120KB | ~80–100KB |
| JavaScript | 0 | 0 |
| Images | per-page, lazy loaded below fold | headshot ~10KB webp |
| **Total critical (no below-fold images)** | **150KB** | **~100–120KB** |

Preload fonts in `<head>`. Single CSS file, no `@import`. Inline SVG favicon.

## 9. Don't

Things that violate house style — avoid all of these in future design conversations:

- ❌ Italic-accent headlines ("Kyle Boon, *engineer*.")
- ❌ Manifesto-style taglines or self-descriptive subtitles
- ❌ Purple/blue gradient accents
- ❌ Additional accent colors beyond rust
- ❌ Box shadows on cards or buttons
- ❌ Border-radius values outside {4px, 999px, 50%}
- ❌ Icon fonts or webfonts beyond Fraunces + Inter
- ❌ CSS frameworks, utility libraries, resets beyond a minimal normalize
- ❌ JavaScript for any reason
- ❌ External font CDNs (CSP forbids and perf suffers)
- ❌ Transforms, scales, or translates on hover
- ❌ Scroll animations or parallax
- ❌ Generic Lorem Ipsum copy in real surfaces

## 10. Do

- ✅ Let typography carry personality (size, weight, optical size, letter spacing)
- ✅ Use Fraunces' opsz axis meaningfully — larger `opsz` on big sizes
- ✅ Use the rust accent sparingly — it's emphasis, not decoration
- ✅ Preserve the paper-and-ink metaphor in both light and dark
- ✅ Add new components using the token system, not by introducing new raw values
- ✅ Validate visually with the `website-preview` or `playwright-skill` before committing design changes
- ✅ Question any decoration that isn't load-bearing — can the design say this with type alone?

## 11. When adding new pages or components

1. Read this document first.
2. Compose from existing tokens. If you need a value that isn't here, update this document as part of the PR.
3. Check both light and dark modes.
4. Verify `prefers-reduced-motion` doesn't break anything.
5. Run `bundle exec htmlproofer ./_site` if HTML structure changed.
6. Screenshot desktop + mobile in both themes before merging.
