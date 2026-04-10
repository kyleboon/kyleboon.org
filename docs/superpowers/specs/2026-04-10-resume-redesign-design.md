# Resume Page Redesign — Design Spec

**Date:** 2026-04-10
**Status:** Approved, ready for implementation plan
**Owner:** Kyle Boon
**Depends on:** Warm Craft redesign (merged 2026-04-09)

## Purpose

The resume page currently inherits the generic `page` layout and renders raw markdown with no resume-specific design treatment. While the typography and palette match the rest of the site, the page lacks the intentional structure that the home page (role eyebrow + oversized H1), blog list (two-column date grid), and blog posts (meta row + drop cap) all have. The resume is the single most important page for professional self-presentation and should feel designed, not just styled.

This spec describes a dedicated resume layout (`_layouts/resume.html`) and restructured markup that brings the resume up to the same design quality as the rest of the site using patterns already established in the style guide.

## Constraints (inherited)

- Zero JavaScript
- No CSS framework
- Single stylesheet (`assets/css/main.css`)
- All existing design tokens from `docs/style-guide.md`
- Self-hosted Fraunces + Inter fonts (already in place)
- Must pass `htmlproofer`
- Mobile-first responsive

## Design direction

**Editorial Column (A)** — selected after comparing against a single-column timeline layout. The editorial column reuses the site's two-column date grid pattern (established on the blog list) for job entries, and introduces a label-value grid for skills. This is the most internally consistent option: the resume's visual grammar matches the blog index.

## Header

Replace the current pipe-separated H1 (`## Principal Software Engineer | Distributed Systems | ...`) with:

1. **Eyebrow label:** "RESUME" — Inter, 0.75rem, uppercase, letter-spacing 0.16em, `--ink-dim`. Same treatment as "RECENT WRITING" on home and post meta rows.
2. **H1:** "Kyle Boon" — Fraunces, page-scale H1 (`clamp(2rem, 4vw, 2.75rem)`), NOT the oversized home H1. The resume is a document, not a splash page.
3. **Role line:** "Principal Software Engineer · Distributed Systems · Cloud Architecture" — Inter, 1rem, `--ink-muted`. Middot-separated (not pipes). This replaces the old H1 keyword string.
4. **Summary paragraph:** The existing summary text, rendered as Inter body in `--ink-muted`.

The header is rendered by `_layouts/resume.html` using front matter variables, NOT from the markdown body. This lets the layout control the structure precisely.

## Section headers

"EXPERIENCE", "SKILLS", "EDUCATION" use the established section-label pattern:

```css
.resume-section-title {
  font-family: var(--font-body);
  font-size: 0.75rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.16em;
  color: var(--ink-dim);
  border-bottom: 1px solid var(--rule);
  padding-bottom: 0.5rem;
  margin: 2.5rem 0 1rem;
}
```

First section ("EXPERIENCE") gets `margin-top: 0` since the summary paragraph provides spacing.

## Job entries

Each job renders as a two-column CSS grid on desktop (≥ 768px):

| Column | Width | Content | Style |
|---|---|---|---|
| Date | 9rem | "APR 2025 – PRESENT" | Inter, 0.75rem, uppercase, tracked, `--ink-dim`, `line-height: 1.4` |
| Content | 1fr | Company name, role, location, bullets | See below |

Content column structure:
- **Company:** Fraunces H3, `font-variation-settings: "opsz" 24`, `--ink`, margin-bottom 0.15rem
- **Role + location:** Inter italic, 0.875rem, `--ink-dim`, margin-bottom 0.6rem. Format: "Principal Software Engineer · Remote"
- **Bullets:** `<ul>` with Inter body text at 0.875rem, `--ink-muted`, `line-height: 1.55`. Bullet marker color: `--rust`.

Between jobs: `border-top: 1px solid var(--rule-soft)`. First job has no top border.

**Mobile (< 768px):** Grid collapses to single column. Date becomes an eyebrow-style label above the company name (same visual treatment, just stacked).

**Bloom Health special case:** Two roles at the same company. Each renders as its own job entry with its own date range. The company name repeats — this is intentional for scannability and avoids complex nested layout.

## Skills section

Two-column CSS grid:

| Column | Width | Content | Style |
|---|---|---|---|
| Label | 10rem | "LANGUAGES" | Inter, 0.6875rem, uppercase, tracked, `--ink-dim`, `font-weight: 600` |
| Values | 1fr | "Kotlin, Java, Python, ..." | Inter, 0.875rem, `--ink-muted` |

Each category is one row. Gap: 0.5rem vertical, 1.5rem horizontal.

**Mobile (< 768px):** Grid collapses. Label stacks above values with 0.25rem gap between them, 1rem gap between categories.

The "Leadership" category (currently "Technical Mentorship, Distributed Team Leadership, Cross-functional Collaboration, ...") stays as comma-separated values — same as the technical skills. This is NOT a skills section that needs pills or tags; it's a reference list.

## Education

Same two-column grid as jobs:

| Date column | Content column |
|---|---|
| MAR 2005 | **The Ohio State University** (Fraunces H3) |
| | B.S. Computer Science & Engineering, Columbus OH (Inter, `--ink-dim`) |

## New layout: `_layouts/resume.html`

Inherits from `page` (via `layout: page` in front matter). The layout renders:

1. The header (eyebrow + H1 + role line + summary) from front matter variables
2. `{{ content }}` — which is the structured HTML in `resume.md`

Front matter variables the layout reads:
- `name:` — "Kyle Boon"
- `role:` — "Principal Software Engineer"
- `specialties:` — ["Distributed Systems", "Cloud Architecture", "Technical Leadership"]
- `summary:` — the summary paragraph text

## Restructured `resume.md`

The current `resume.md` is pure markdown with `##` and `###` headings. The new version uses HTML with semantic classes that the CSS can target for the two-column grid. Markdown within the HTML blocks is NOT processed by kramdown, so bullet lists must use `<ul><li>` tags.

Structure:

```html
---
layout: resume
title: Resume
name: Kyle Boon
role: Principal Software Engineer
specialties:
  - Distributed Systems
  - Cloud Architecture
  - Technical Leadership
summary: >-
  Principal Software Engineer with 20+ years of experience...
---

<section class="resume-section">
  <h2 class="resume-section-title">Experience</h2>

  <div class="resume-entry">
    <div class="resume-date">Apr 2025 –<br>Present</div>
    <div class="resume-content">
      <h3 class="resume-company">RB Global</h3>
      <p class="resume-role">Principal Software Engineer · Remote</p>
      <ul class="resume-bullets">
        <li>Provide technical leadership across...</li>
        ...
      </ul>
    </div>
  </div>

  <!-- more entries -->
</section>

<section class="resume-section">
  <h2 class="resume-section-title">Skills</h2>

  <div class="resume-skills">
    <div class="resume-skill-label">Languages</div>
    <div class="resume-skill-values">Kotlin, Java, Python, ...</div>
    ...
  </div>
</section>

<section class="resume-section">
  <h2 class="resume-section-title">Education</h2>

  <div class="resume-entry">
    <div class="resume-date">Mar 2005</div>
    <div class="resume-content">
      <h3 class="resume-company">The Ohio State University</h3>
      <p class="resume-role">B.S. Computer Science & Engineering, Columbus OH</p>
    </div>
  </div>
</section>
```

## Scope of changes

### New files

- `_layouts/resume.html` — inherits from `page`, renders the header from front matter, wraps `{{ content }}`

### Modified files

- `resume.md` — restructured from pure markdown to HTML with semantic resume classes. Front matter gains `name`, `role`, `specialties`, `summary` fields. Layout changes from `page` to `resume`.
- `assets/css/main.css` — append ~80–100 lines of resume-specific CSS (section titles, date grid, skills grid, mobile breakpoints)

### Unchanged files

- All other pages, layouts, includes — no changes
- `docs/style-guide.md` — should be updated AFTER implementation to document the new resume component classes

## What this does NOT include

- Print-specific styles (deferred to a future pass)
- A downloadable PDF version
- Any content changes beyond restructuring existing text into the new markup format

## Shortfalls addressed (from the design review)

| Shortfall | Resolution |
|---|---|
| Pipe-separated H1 clashes with Fraunces display type | Replaced with eyebrow + H1 + middot-separated role line |
| No signature moment on the resume | Header treatment with eyebrow label, matching the site's pattern |
| Visual hierarchy inverted (company > role) | Company in Fraunces H3, role in italic Inter — correct hierarchy |
| Dates buried in parentheses | Date column on left (matches blog list), uppercase tracked Inter |
| No separator between jobs | `border-top: 1px solid var(--rule-soft)` |
| Skills section is eye-hostile comma runs | Label-value grid with uppercase category labels |
| H2 "Experience" is generic | Section-label eyebrow treatment with bottom rule |
| No resume-specific layout | New `_layouts/resume.html` with front matter–driven header |
