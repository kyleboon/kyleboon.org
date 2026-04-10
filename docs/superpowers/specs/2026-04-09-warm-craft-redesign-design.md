# Warm Craft Redesign — Design Spec

**Date:** 2026-04-09
**Status:** Approved, ready for implementation plan
**Owner:** Kyle Boon

## Purpose

Redesign kyleboon.org to address shortfalls identified in an initial design review while strengthening the commitment to the original principles: zero JavaScript, no CSS framework, extremely fast, accessible, responsive. The current site is competent but generic — the goal is to move it from "default developer blog" to "this person has taste" without sacrificing any of the engineering discipline that defines it.

The companion document to this spec is [`docs/style-guide.md`](../../style-guide.md), which captures the resulting design system as a living reference. This spec captures *the decisions* made in this session; the style guide captures *the system* those decisions produced.

## Constraints (inherited, non-negotiable)

- Zero JavaScript
- No CSS framework or library
- Single self-written stylesheet
- All assets (fonts, images, CSS) self-hosted — dictated by the existing CSP:
  `default-src 'none'; style-src 'self'; img-src 'self'; font-src 'self'; base-uri 'self'; form-action 'self'`
- Jekyll + GitHub Pages deployment
- Must pass `htmlproofer` on `_site`
- Mobile-first responsive

## Design direction

**Warm Craft · D2** — a serif/sans hybrid with a paper-and-ink metaphor.

This direction was selected after evaluating four personality candidates (Editorial Quiet, Technical Journal, Refined Monochrome, Warm Craft). Within Warm Craft, three executions were compared (all-serif gentle, serif+sans hybrid, full serif bold) — the hybrid won because it delivers editorial character in headlines while keeping body text crisp at reading sizes.

**Dark mode:** Warm Dark. The cream-paper background becomes cocoa (`#1c140e`) rather than near-black, keeping the paper-and-ink metaphor consistent day and night.

**Signature moments:**

1. **Role eyebrow** on the home hero — small uppercase "PRINCIPAL SOFTWARE ENGINEER" above the oversized Fraunces H1. Communicates role before the tagline paints; quiet enough to not feel like a manifesto.
2. **Drop cap** on blog posts — oversized italic Fraunces drop cap on the first paragraph of post content. Fires only on post pages, not on index or informational pages.

**Explicitly rejected alternatives** (documented so we don't relitigate):

- Italic-accent headline ("Kyle Boon, *engineer*.") — rejected as pretentious.
- Paper grain SVG background — rejected as unnecessary decoration; typography carries enough.
- Marginalia rail — rejected as extra chrome that doesn't earn its weight.
- Cool dark mode — rejected because it breaks the paper metaphor.

## Typography

- **Display:** Fraunces variable font (Latin subset, `opsz` + `SOFT` axes), self-hosted as `.woff2`
- **Body:** Inter variable font (Latin subset), self-hosted as `.woff2`
- **Monospace:** system fallback chain — no download

Both fonts preloaded in `<head>` with `font-display: swap`. Type scale is fluid (`clamp()`). Full scale, axis settings, and usage rules in the style guide §2.

## Color

Two palettes swapped by `prefers-color-scheme`. Seven light tokens, seven dark tokens. Full values in style guide §3.

Headline choices:
- Light: cream paper `#f6f1e8`, ink `#201612`, rust `#b5581f`
- Dark: cocoa `#1c140e`, cream ink `#f0e6d6`, copper `#d08858`

No other hues anywhere on the site.

## Layout

- **Reading measure:** 48rem tablet, 54rem desktop (up from the current ~50em cap — wider for better density but still optimized for prose).
- **Home hero:** circular photo (120px) on the left, eyebrow + oversized H1 + tagline + pills on the right. Stacks on mobile.
- **Nav:** unchanged structure — sticky header with `aria-current`, present on every page *except* home (home keeps its existing pill-nav pattern).
- **Blog list:** new two-column grid on desktop (9rem date column + title column). Stacks on mobile.
- **Blog post:** new meta row above H1 ("MARCH 16, 2025 · WRITING" in eyebrow treatment), Fraunces H1, drop-cap first paragraph.
- **Books page:** cards lose box shadows and heavy borders. Item divider is a single `border-top`. Cleaner, more editorial, same information density.

## Scope of changes

### New files

- `_layouts/post.html` — inherits from `page` (via `layout: page` front matter) and wraps `{{ content }}` in `<article class="post-body">` so drop-cap CSS can scope to post content only. No nav markup duplication — the nav comes from the inherited `page` layout.
- `assets/fonts/fraunces-latin-var.woff2` — self-hosted Fraunces variable (Latin subset only)
- `assets/fonts/inter-latin-var.woff2` — self-hosted Inter variable (Latin subset only)
- `docs/style-guide.md` — living design system reference (written alongside this spec)

### Modified files

- `_config.yml` — add `defaults` block to apply `layout: post` to all posts without touching existing post front matter
- `_layouts/home.html` — restructure hero with eyebrow markup
- `_layouts/page.html` — minor semantic tweaks only. Does NOT wrap content in `<article>` (that happens in the new `post` layout) because `page` also serves static pages like About and Books where an `<article>` wrapper would be semantically wrong.
- `_includes/head.html` — add `<link rel="preload">` for the two font files with `crossorigin` attribute
- `_includes/footer.html` — restyle classes to match new token system
- `index.html` — add eyebrow, restructure hero to match home layout spec
- `blog.html` — no structural change (CSS handles the two-column date list)
- `assets/css/main.css` — full rewrite using new token system, type scale, and component styles

### Unchanged files (verified in scope)

- `aboutme.html`, `books.html`, `presentations.html`, `resume.md` — no content changes; CSS update automatically restyles them
- Post markdown files — no front matter changes (handled by `_config.yml` defaults)

## Shortfalls addressed

This spec resolves every item from the original design review. Cross-reference:

| Original shortfall | Resolution |
|---|---|
| Generic system font stack | Fraunces + Inter, self-hosted variable woff2 |
| Desktop whitespace feels orphaned | Wider reading measure (54rem) + oversized hero typography anchors the column |
| Shape inconsistency (4 radii) | Two-token system: `--radius: 4px`, `--radius-pill: 999px` |
| Blog list has no rhythm | Two-column date-title grid on desktop |
| No visited link state | `:visited` uses `--rust-visited` token |
| Wikipedia-blue `#16c` link | Rust (`#b5581f` light, `#d08858` dark) |
| Post pages don't show date prominently | Eyebrow meta row above H1 |
| Generic monospace | Explicit monospace fallback chain |
| No `prefers-reduced-motion` | Full reduce override in CSS |
| Link color contrast (default blue) | New rust tokens meet AA at both light and dark |
| No memorable moment | Oversized Fraunces H1 + role eyebrow + drop cap signature |
| Footer feels unintentional | Restyled with token system, italic, dimmed, quiet |
| Book cards feel generic | Shadow/border removed, reduced to a single divider line |

## Performance budget

- Total critical-path weight for home page: ≤ 150KB
  - HTML: ~3KB
  - CSS: ~10KB
  - Fonts (2 woff2, preloaded): ~80–100KB
  - Headshot (lazy-loaded below fold, but shown on home so counts): ~10KB webp
  - JavaScript: 0
- CSS remains a single file (no `@import`)
- Fonts subset to Latin only — no Cyrillic, Greek, or extended Latin blocks

## Accessibility additions

- `:focus-visible` outline (2px rust, 2px offset)
- `:visited` link color
- `prefers-reduced-motion` honored
- `prefers-color-scheme` honored (already present; no regression)
- Existing skip-to-content link and `aria-current` preserved
- Color contrast verified at AA for all combinations

## Non-goals

Explicitly out of scope for this redesign:

- Adding a blog search, tag system, or pagination
- Restructuring the URL scheme or breaking existing permalinks
- Adding analytics, comments, or any third-party embed
- Building any kind of CMS or content editor
- Adding a newsletter signup
- Bringing in any JavaScript, including for "progressive enhancement"
- Supporting browsers without CSS custom properties or `clamp()` (IE, old Android)

## Open questions

None at spec-writing time. All design questions resolved during the brainstorming session:

1. Direction — D (Warm Craft) ✓
2. Execution — D2 (Serif + Sans Hybrid) ✓
3. Dark mode — A (Warm Dark) ✓
4. Signature decoration — A (typography-led) + D (drop cap on posts) ✓
5. Headline treatment — #2 (role eyebrow, no italic accent) ✓
6. Scope — all pages ✓
7. Drop cap scope — blog posts only ✓

## Next step

Hand off to the `writing-plans` skill to produce a detailed, ordered implementation plan covering: font acquisition and subsetting, CSS rewrite, layout changes, new post layout, `_config.yml` defaults, and visual verification across all pages × 2 viewports × 2 themes.
