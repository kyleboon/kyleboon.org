# Warm Craft Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the Warm Craft redesign of kyleboon.org — self-hosted Fraunces + Inter, warm cream/cocoa paper-and-ink palette with rust accent, new home hero with role eyebrow, two-column blog list, drop cap on posts — while preserving zero JavaScript, no CSS framework, and the existing CSP.

**Architecture:** Jekyll site with a single hand-written stylesheet at `assets/css/main.css`, two fonts self-hosted as `.woff2` under `assets/fonts/`, a new `post` layout that inherits from `page` to scope drop-cap styling. Design tokens flow through CSS custom properties; `prefers-color-scheme` swaps between light and dark palettes.

**Tech Stack:** Jekyll 4.4, kramdown, Ruby `html-proofer` for link checking, Playwright via `playwright-skill` for visual verification. No npm/Node dependencies, no Python tooling required — fonts are downloaded pre-subset from fontsource via jsdelivr.

**Reference documents:**
- Spec: `docs/superpowers/specs/2026-04-09-warm-craft-redesign-design.md`
- Style guide (living): `docs/style-guide.md`

Read the spec and style guide before starting Task 1. Every token value, type scale entry, and component rule is in the style guide — use it as the authoritative source while implementing.

---

## Pre-flight

Before Task 1, verify you can build and serve the site:

```bash
cd /Users/kyleboon/code/kyleboon.org
bundle install
bundle exec jekyll serve --host 0.0.0.0
```

Confirm http://localhost:4000/ renders the current (pre-redesign) site. Leave Jekyll running in a background terminal — it auto-rebuilds on file changes, which is how you'll verify CSS/layout changes throughout this plan.

---

## Task 1: Download self-hosted font files

**Why:** The site's existing CSP (`font-src 'self'`) forbids loading fonts from CDNs at runtime. We'll commit two `.woff2` files to the repo. Both are pre-subset to Latin only by the fontsource project, so no `fonttools` install is needed.

**Files:**
- Create: `assets/fonts/fraunces-latin-full.woff2`
- Create: `assets/fonts/inter-latin-wght.woff2`
- Create: `assets/fonts/README.md`

- [ ] **Step 1: Create the fonts directory**

Run:

```bash
mkdir -p /Users/kyleboon/code/kyleboon.org/assets/fonts
```

- [ ] **Step 2: Download Fraunces variable font (Latin, full axes)**

Run:

```bash
curl -L -o /Users/kyleboon/code/kyleboon.org/assets/fonts/fraunces-latin-full.woff2 \
  "https://cdn.jsdelivr.net/npm/@fontsource-variable/fraunces/files/fraunces-latin-full-normal.woff2"
```

Verify size is reasonable (50–120KB):

```bash
ls -l /Users/kyleboon/code/kyleboon.org/assets/fonts/fraunces-latin-full.woff2
```

If the file is under 10KB, the download failed — check the URL and retry. If jsdelivr has renamed the file, try the alternate path:

```bash
curl -L -o /Users/kyleboon/code/kyleboon.org/assets/fonts/fraunces-latin-full.woff2 \
  "https://cdn.jsdelivr.net/npm/@fontsource-variable/fraunces@latest/files/fraunces-latin-full-normal.woff2"
```

- [ ] **Step 3: Download Inter variable font (Latin, wght axis)**

Run:

```bash
curl -L -o /Users/kyleboon/code/kyleboon.org/assets/fonts/inter-latin-wght.woff2 \
  "https://cdn.jsdelivr.net/npm/@fontsource-variable/inter/files/inter-latin-wght-normal.woff2"
```

Verify size (30–80KB):

```bash
ls -l /Users/kyleboon/code/kyleboon.org/assets/fonts/inter-latin-wght.woff2
```

- [ ] **Step 4: Verify the files are valid woff2**

Run:

```bash
file /Users/kyleboon/code/kyleboon.org/assets/fonts/*.woff2
```

Expected output: both files should be reported as `Web Open Font Format (Version 2)`.

- [ ] **Step 5: Write a README documenting the source**

Create `/Users/kyleboon/code/kyleboon.org/assets/fonts/README.md` with exactly this content:

```markdown
# Self-hosted fonts

These `.woff2` files are self-hosted to satisfy the site's Content Security Policy (`font-src 'self'`) and to eliminate a third-party network dependency.

| File | Family | Axes | Source |
|---|---|---|---|
| `fraunces-latin-full.woff2` | Fraunces (variable) | wght, opsz, SOFT, WONK | `@fontsource-variable/fraunces` via jsdelivr, `fraunces-latin-full-normal.woff2` |
| `inter-latin-wght.woff2` | Inter (variable) | wght | `@fontsource-variable/inter` via jsdelivr, `inter-latin-wght-normal.woff2` |

Both files are pre-subset to the Latin unicode range by the fontsource project. To refresh, re-run the download commands in `docs/superpowers/plans/2026-04-09-warm-craft-redesign.md` Task 1.

## Licenses

- Fraunces is licensed under the SIL Open Font License 1.1: https://github.com/undercasetype/Fraunces
- Inter is licensed under the SIL Open Font License 1.1: https://github.com/rsms/inter
```

- [ ] **Step 6: Commit**

```bash
cd /Users/kyleboon/code/kyleboon.org
git add assets/fonts/
git commit -m "$(cat <<'EOF'
Add self-hosted Fraunces and Inter variable fonts

Adds Fraunces (full variable: wght, opsz, SOFT, WONK axes) and Inter
(wght axis) as Latin-subset woff2 files under assets/fonts/. Required
for the Warm Craft redesign and to satisfy the site's CSP font-src
'self' directive. Sourced from the fontsource project via jsdelivr.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Create post layout and wire up Jekyll defaults

**Why:** Drop-cap CSS needs a scoping selector (`.post-body > p:first-of-type::first-letter`) so it fires only on blog post content, not on About, Books, or home page paragraphs. We create a new `post` layout that inherits from `page` and wraps `{{ content }}` in `<article class="post-body">`. Instead of editing the front matter of all 8 existing posts, we add a `defaults` block to `_config.yml` so every post in `_posts/` automatically uses `layout: post`.

**Files:**
- Create: `_layouts/post.html`
- Modify: `_layouts/page.html`
- Modify: `_config.yml`

- [ ] **Step 1: Fix invalid skip-link placement in page.html**

The current `_layouts/page.html` has a structural bug — the skip-to-content link is rendered between `{% include head.html %}` (which closes `</head>`) and `<body>`, which is invalid HTML. Browsers parser-recover, but it's not semantically correct and the spec promised to fix the page.html semantics.

Open `/Users/kyleboon/code/kyleboon.org/_layouts/page.html`. It currently looks like:

```html
---
common-css:
  - "/assets/css/main.css"
---
<!DOCTYPE html>
<html lang="en">
  {% include head.html %}
  <a class="sr-only" href="#maincontent">Skip to content</a>
  <body>
    <header>
      <nav> 
        <a href="/">Home</a>
        ...
```

Replace its entire contents with:

```html
---
common-css:
  - "/assets/css/main.css"
---
<!DOCTYPE html>
<html lang="en">
  {% include head.html %}
  <body>
    <a class="sr-only" href="#maincontent">Skip to content</a>
    <header>
      <nav>
        <a href="/" {% if page.url == '/' %}aria-current="page"{% endif %}>Home</a>
        <a href="/aboutme" {% if page.url == '/aboutme' %}aria-current="page"{% endif %}>About</a>
        <a href="/blog" {% if page.url == '/blog' %}aria-current="page"{% endif %}>Blog</a>
        <a href="/presentations" {% if page.url == '/presentations' %}aria-current="page"{% endif %}>Technical Presentations</a>
        <a href="/resume" {% if page.url == '/resume' %}aria-current="page"{% endif %}>Resume</a>
      </nav>
    </header>
    <main id="maincontent">
        {{ content }}
    </main>
    {% include footer.html %}
  </body>
</html>
```

Two changes from the original:
1. Skip link moved inside `<body>` (it's the first focusable child of body, where it belongs)
2. Added `aria-current="page"` to the Home link for consistency with the others

- [ ] **Step 2: Create the new post layout**

Create `/Users/kyleboon/code/kyleboon.org/_layouts/post.html` with exactly this content:

```html
---
layout: page
---
<header class="post-header">
  <div class="post-meta">
    <time datetime="{{ page.date | date_to_xmlschema }}">{{ page.date | date: "%B %-d, %Y" }}</time>
    {% if page.categories.size > 0 %}
    &middot; <span class="post-category">{{ page.categories | first | upcase }}</span>
    {% else %}
    &middot; <span class="post-category">WRITING</span>
    {% endif %}
  </div>
</header>
<article class="post-body">
  {{ content }}
</article>
```

**Note on Jekyll inheritance:** The `layout: page` front matter in `post.html` tells Jekyll to use `_layouts/page.html` as the parent — the post layout's rendered HTML becomes the `{{ content }}` of the page layout. This gives us the nav + footer for free without duplicating markup.

- [ ] **Step 3: Add the defaults block to _config.yml**

Open `/Users/kyleboon/code/kyleboon.org/_config.yml` and add these lines at the end of the file (after the `exclude:` block):

```yaml

defaults:
  - scope:
      path: ""
      type: "posts"
    values:
      layout: "post"
```

The leading blank line separates this block from `exclude:`. Final section of `_config.yml` should look like:

```yaml
exclude:
  - CNAME
  - LICENSE
  - README.md
  - CLAUDE.md
  - TODO.md
  - scripts
  - Gemfile
  - Gemfile.lock

defaults:
  - scope:
      path: ""
      type: "posts"
    values:
      layout: "post"
```

- [ ] **Step 4: Restart Jekyll to pick up the config change**

Jekyll's `--watch` mode does NOT reload `_config.yml` — you must restart it. Stop the running Jekyll process and restart:

```bash
cd /Users/kyleboon/code/kyleboon.org
bundle exec jekyll serve --host 0.0.0.0
```

- [ ] **Step 5: Verify a post renders through the new layout**

Open http://localhost:4000/2025/03/16/old-dogs-new-tricks/ in a browser. You should see:

- A new meta row at the top: `March 16, 2025 · WRITING`
- The post's original `# Keeping My Skills Sharp` markdown H1 right below it
- The post body wrapped in an `<article class="post-body">` — inspect element to confirm

If the meta row doesn't appear, the `defaults` block isn't picking up. Verify `_config.yml` indentation uses spaces (not tabs) and that Jekyll was fully restarted.

- [ ] **Step 6: Verify a non-post page still uses the page layout**

Open http://localhost:4000/aboutme/ — it should render unchanged (no meta row, no `<article>` wrapper). If it now has a meta row, the defaults block is over-scoped — double-check `type: "posts"` (not `"pages"`).

- [ ] **Step 7: Commit**

```bash
cd /Users/kyleboon/code/kyleboon.org
git add _layouts/page.html _layouts/post.html _config.yml
git commit -m "$(cat <<'EOF'
Add post layout, fix page.html semantics, scope drop-cap content

New _layouts/post.html inherits from page and wraps {{ content }} in
<article class="post-body"> so CSS can scope drop-cap styling to post
content only. Adds a meta row above the content showing the date and
category (or "WRITING" if no category).

Fixes page.html: moves the skip-to-content link inside <body> where it
belongs (was sitting between </head> and <body>, which is invalid HTML
that browsers parser-recover) and adds aria-current to the Home nav
link for consistency with the others.

_config.yml gains a defaults block that applies layout: post to all
files in _posts/ without touching any post front matter.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Update head.html for font preloading

**Why:** Preloading fonts with `<link rel="preload" as="font" crossorigin>` tells the browser to fetch them immediately in parallel with the CSS, so text paints in the correct face on the first render rather than flashing from fallback. The `crossorigin` attribute is required on preload links for fonts even when same-origin, or the browser will make a second fetch.

**Files:**
- Modify: `_includes/head.html`

- [ ] **Step 1: Add preload links to head.html**

Open `/Users/kyleboon/code/kyleboon.org/_includes/head.html`. Find the line:

```html
    <link rel="stylesheet" href="/assets/css/main.css">
```

Replace it with these lines (preload fonts first, then stylesheet):

```html
    <link rel="preload" href="/assets/fonts/fraunces-latin-full.woff2" as="font" type="font/woff2" crossorigin>
    <link rel="preload" href="/assets/fonts/inter-latin-wght.woff2" as="font" type="font/woff2" crossorigin>
    <link rel="stylesheet" href="/assets/css/main.css">
```

- [ ] **Step 2: Update theme-color meta tags to match the new palette**

Find these two lines in head.html:

```html
    <meta name="theme-color" content="#fafafa" media="(prefers-color-scheme: light)">
    <meta name="theme-color" content="#1a1a1a" media="(prefers-color-scheme: dark)">
```

Replace with:

```html
    <meta name="theme-color" content="#f6f1e8" media="(prefers-color-scheme: light)">
    <meta name="theme-color" content="#1c140e" media="(prefers-color-scheme: dark)">
```

These color the mobile browser chrome bar to match the new paper/cocoa backgrounds.

- [ ] **Step 3: Verify Jekyll rebuilds and the head is correct**

Reload http://localhost:4000/ and view the page source. Confirm:
- Both `<link rel="preload">` entries are present
- Both have `crossorigin` attribute
- Theme-color meta tags show `#f6f1e8` and `#1c140e`

At this point the fonts won't be styled yet (the CSS hasn't been rewritten) but the preloads should show in the browser's Network tab with `Initiator: (Preload)`.

- [ ] **Step 4: Commit**

```bash
cd /Users/kyleboon/code/kyleboon.org
git add _includes/head.html
git commit -m "$(cat <<'EOF'
Preload self-hosted fonts and update theme colors

Adds <link rel=preload> for the two woff2 files so the browser fetches
them in parallel with the CSS rather than after the CSS parses
@font-face declarations. Updates the theme-color meta tags to the new
paper (#f6f1e8) and cocoa (#1c140e) palette so the mobile chrome bar
matches the new design.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Update index.html with the role eyebrow

**Why:** The role eyebrow ("PRINCIPAL SOFTWARE ENGINEER" above the H1) is the signature element on the home page. It must render in the document order `eyebrow → h1 → tagline → pills` so screen readers read it naturally.

**Files:**
- Modify: `index.html`

- [ ] **Step 1: Add the eyebrow to index.html**

Open `/Users/kyleboon/code/kyleboon.org/index.html`. Find the `.intro-text` block:

```html
    <div class="intro-text">
        <h1>Hi, I'm Kyle Boon</h1>
        <p class="tagline">Principal Software Engineer specializing in distributed systems and cloud architecture</p>
```

Replace with:

```html
    <div class="intro-text">
        <p class="role-eyebrow">Principal Software Engineer</p>
        <h1>Kyle Boon</h1>
        <p class="tagline">Distributed systems, cloud architecture, and things I've shipped.</p>
```

**Note:** We're shortening the tagline because the role is now separate. The old tagline repeated the role; the new one focuses on what the writing is about.

- [ ] **Step 2: Verify the page still renders**

Reload http://localhost:4000/. The home page will look broken (no new CSS yet), but the structure should be: small text "Principal Software Engineer", then "Kyle Boon" as H1, then the shorter tagline, then the pills.

- [ ] **Step 3: Commit**

```bash
cd /Users/kyleboon/code/kyleboon.org
git add index.html
git commit -m "$(cat <<'EOF'
Add role eyebrow to home hero and shorten tagline

Splits the home page hero into a small uppercase role label above an
oversized H1, with a shorter tagline below. This is the "role eyebrow"
signature element from the redesign spec — communicates the role before
the tagline paints, without using a literary italic-accent headline.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Rewrite main.css — foundation (reset, tokens, @font-face, body)

**Why:** This is the biggest change. We're replacing the current `main.css` with a new stylesheet built on the Warm Craft design tokens. We split the rewrite into three tasks (foundation, layout/components, refinements) so each can be verified visually and committed independently. Task 5 sets up the token system, font faces, and base body styles — after this task the site will look broken (unstyled nav, no hero layout) but the typography and colors should already match the spec.

**Files:**
- Modify: `assets/css/main.css` (complete rewrite begins here — further tasks append to it)

- [ ] **Step 1: Replace the entire contents of main.css with the foundation block**

Open `/Users/kyleboon/code/kyleboon.org/assets/css/main.css` and **replace its entire contents** with exactly:

```css
/* ============================================================
   kyleboon.org — Warm Craft
   See docs/style-guide.md for the full system reference.
   ============================================================ */

/* --------- Font faces (self-hosted) --------- */

@font-face {
  font-family: "Fraunces";
  src: url("/assets/fonts/fraunces-latin-full.woff2") format("woff2-variations"),
       url("/assets/fonts/fraunces-latin-full.woff2") format("woff2");
  font-weight: 100 900;
  font-style: normal;
  font-display: swap;
  unicode-range: U+0000-00FF, U+0131, U+0152-0153, U+02BB-02BC, U+02C6, U+02DA, U+02DC, U+2000-206F, U+2074, U+20AC, U+2122, U+2191, U+2193, U+2212, U+2215, U+FEFF, U+FFFD;
}

@font-face {
  font-family: "Inter";
  src: url("/assets/fonts/inter-latin-wght.woff2") format("woff2-variations"),
       url("/assets/fonts/inter-latin-wght.woff2") format("woff2");
  font-weight: 100 900;
  font-style: normal;
  font-display: swap;
  unicode-range: U+0000-00FF, U+0131, U+0152-0153, U+02BB-02BC, U+02C6, U+02DA, U+02DC, U+2000-206F, U+2074, U+20AC, U+2122, U+2191, U+2193, U+2212, U+2215, U+FEFF, U+FFFD;
}

/* --------- Tokens (light) --------- */

:root {
  /* Color */
  --paper: #f6f1e8;
  --ink: #201612;
  --ink-muted: #3a2b24;
  --ink-dim: #7a5b4a;
  --rust: #b5581f;
  --rust-visited: #8a4520;
  --rust-soft: rgba(181, 88, 31, 0.08);
  --rule: rgba(32, 22, 18, 0.12);
  --rule-soft: rgba(32, 22, 18, 0.06);

  /* Shape */
  --radius: 4px;
  --radius-pill: 999px;

  /* Motion */
  --ease: 150ms ease;

  /* Typography */
  --font-display: "Fraunces", Georgia, "Times New Roman", serif;
  --font-body: "Inter", -apple-system, "Segoe UI", sans-serif;
  --font-mono: ui-monospace, "SF Mono", "JetBrains Mono", Menlo, monospace;

  /* Layout */
  --measure-mobile: 100%;
  --measure-tablet: 48rem;
  --measure-desktop: 54rem;

  /* Base size */
  --base-font-size: 18px;
}

/* --------- Tokens (dark) --------- */

@media (prefers-color-scheme: dark) {
  :root {
    --paper: #1c140e;
    --ink: #f0e6d6;
    --ink-muted: rgba(240, 230, 214, 0.78);
    --ink-dim: #c29876;
    --rust: #d08858;
    --rust-visited: #a76a42;
    --rust-soft: rgba(208, 136, 88, 0.10);
    --rule: rgba(240, 230, 214, 0.12);
    --rule-soft: rgba(240, 230, 214, 0.06);
  }
}

/* --------- Reset (minimal) --------- */

*, *::before, *::after { box-sizing: border-box; }

html {
  overflow-y: scroll;
  -webkit-text-size-adjust: 100%;
  font-size: var(--base-font-size);
}

body {
  margin: 0 auto;
  padding: 1.25rem;
  max-width: var(--measure-mobile);
  min-height: 100vh;
  font-family: var(--font-body);
  font-size: 1.125rem;
  line-height: 1.65;
  color: var(--ink);
  background: var(--paper);
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-rendering: optimizeLegibility;
}

@media (min-width: 768px) {
  body {
    padding: 2rem;
    max-width: var(--measure-tablet);
  }
}

@media (min-width: 1200px) {
  body {
    padding: 2rem 3rem;
    max-width: var(--measure-desktop);
  }
}

/* --------- Skip link --------- */

.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  border: 0;
}

.sr-only:focus {
  position: static;
  width: auto;
  height: auto;
  margin: 0;
  overflow: visible;
  clip: auto;
  padding: 0.5rem 1rem;
  background: var(--rust);
  color: var(--paper);
  text-decoration: none;
}

/* --------- Links (base) --------- */

a {
  color: var(--rust);
  text-decoration: none;
  transition: color var(--ease);
}

a:hover, a:focus, a:active {
  text-decoration: underline;
  text-decoration-thickness: 1px;
  text-underline-offset: 0.2em;
}

a:visited {
  color: var(--rust-visited);
}

/* --------- Images --------- */

img {
  display: block;
  max-width: 100%;
  height: auto;
  margin: 1.5em 0;
}
```

- [ ] **Step 2: Reload and verify the baseline**

Reload http://localhost:4000/. Expected state:
- Background is warm cream (`#f6f1e8`) in light mode, cocoa (`#1c140e`) in dark mode
- Body text is in Inter (noticeable change from the previous -apple-system stack)
- Links are rust-colored
- Everything is stacked and unstyled — no nav bar, no hero grid, no blog list formatting (we haven't written those rules yet)

If the background is still the old cream `#fafafa`, hard-reload (Cmd+Shift+R) to bypass CSS cache.

If the font doesn't load, open DevTools → Network tab, filter by "Font". You should see both woff2 files with status 200. If not:
- Verify files exist at `assets/fonts/fraunces-latin-full.woff2` and `assets/fonts/inter-latin-wght.woff2`
- Verify the paths in `@font-face` match (must start with `/` for absolute path)

- [ ] **Step 3: Take a screenshot for reference**

Use the `playwright-skill` to capture a baseline at this stage. Write a script to `/tmp/playwright-warm-craft-baseline.js`:

```javascript
const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const ctx = await browser.newContext();
  const page = await ctx.newPage();
  await page.emulateMedia({ colorScheme: 'light' });
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.goto('http://localhost:4000/', { waitUntil: 'networkidle' });
  await page.screenshot({ path: '/tmp/warm-craft-baseline.png', fullPage: true });
  console.log('Saved baseline screenshot');
  await browser.close();
})();
```

Run it:

```bash
cd /Users/kyleboon/.claude/plugins/marketplaces/playwright-skill/skills/playwright-skill && node run.js /tmp/playwright-warm-craft-baseline.js
```

View `/tmp/warm-craft-baseline.png`. The home page should show unstyled Inter text on the cream background. This is intentional — we're at the foundation stage.

- [ ] **Step 4: Commit**

```bash
cd /Users/kyleboon/code/kyleboon.org
git add assets/css/main.css
git commit -m "$(cat <<'EOF'
CSS foundation: tokens, font faces, base body

Replaces main.css with the Warm Craft foundation — @font-face
declarations for self-hosted Fraunces and Inter, full light and dark
token systems (paper, ink, rust, rules, shape, motion), minimal reset,
responsive body widths (48rem tablet, 54rem desktop), and base link
styling with visited state. Typography scale, layouts, and components
follow in later commits.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: Typography scale — headings, eyebrow, tagline, meta

**Why:** The type scale is the center of the design. Getting it right before layout work means every subsequent component renders with the correct hierarchy from the start.

**Files:**
- Modify: `assets/css/main.css` (append to end)

- [ ] **Step 1: Append the typography block to main.css**

Open `assets/css/main.css` and append this block at the end of the file:

```css
/* --------- Typography --------- */

h1, h2, h3, h4, h5, h6 {
  font-family: var(--font-display);
  font-weight: 600;
  color: var(--ink);
  margin: 1.5em 0 0.5em;
  text-wrap: balance;
}

h1 {
  font-size: clamp(2rem, 4vw, 2.75rem);
  line-height: 1.05;
  letter-spacing: -0.02em;
  font-variation-settings: "opsz" 72, "SOFT" 30;
  margin-top: 0.5em;
}

h2 {
  font-size: 1.625rem;
  line-height: 1.15;
  letter-spacing: -0.015em;
  font-variation-settings: "opsz" 36, "SOFT" 20;
}

h3 {
  font-size: 1.25rem;
  line-height: 1.25;
  letter-spacing: -0.01em;
  font-variation-settings: "opsz" 24;
}

p {
  margin: 0 0 1.25em;
}

p:last-child {
  margin-bottom: 0;
}

strong {
  font-weight: 600;
}

em {
  font-style: italic;
}

/* Role eyebrow — the signature element on the home hero */
.role-eyebrow {
  font-family: var(--font-body);
  font-size: 0.75rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.14em;
  color: var(--ink-dim);
  margin: 0 0 0.75rem;
  line-height: 1;
}

/* Oversized home H1 */
.home-h1, #maincontent > .hero-section h1 {
  font-size: clamp(3rem, 7vw, 5rem);
  line-height: 0.95;
  letter-spacing: -0.035em;
  font-variation-settings: "opsz" 144, "SOFT" 40;
  margin: 0 0 0.75rem;
}

/* Tagline below the home H1 */
.tagline {
  font-family: var(--font-body);
  font-size: 1.25rem;
  line-height: 1.5;
  color: var(--ink-muted);
  margin: 0 0 1.5rem;
  max-width: 38ch;
}

/* Generic meta (dates, category labels) */
.post-meta, .post-date, .talk-meta {
  font-family: var(--font-body);
  font-size: 0.8125rem;
  font-weight: 500;
  letter-spacing: 0.02em;
  color: var(--ink-dim);
  line-height: 1.4;
}

/* Post-header row (above blog post H1) */
.post-header {
  margin-bottom: 1.5rem;
}

.post-header .post-meta {
  text-transform: uppercase;
  letter-spacing: 0.12em;
  font-size: 0.75rem;
  font-weight: 600;
}

.post-header .post-meta .post-category {
  color: var(--rust);
}
```

- [ ] **Step 2: Verify heading and eyebrow rendering**

Reload http://localhost:4000/. The home page now shows:
- Small uppercase "PRINCIPAL SOFTWARE ENGINEER" eyebrow
- Large Fraunces "Kyle Boon" headline (oversized per `clamp()`)
- Inter tagline in muted ink color

Reload http://localhost:4000/2025/03/16/old-dogs-new-tricks/. The post page now shows:
- A small uppercase meta row: "MARCH 16, 2025 · WRITING" (with WRITING in rust)
- The post's H1 in Fraunces
- Body text in Inter

The layout is still not quite right (no two-column hero yet, no blog grid), but typography should be dialed in.

- [ ] **Step 3: Commit**

```bash
cd /Users/kyleboon/code/kyleboon.org
git add assets/css/main.css
git commit -m "$(cat <<'EOF'
CSS: typography scale and eyebrow

Adds the Fraunces heading hierarchy with opsz + SOFT variation settings,
the oversized home H1 (clamp 3-5rem), the role-eyebrow rule for the home
hero signature element, the tagline treatment, and the post-meta row
style used above blog post titles.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 7: Navigation

**Why:** The page layout's top nav needs the new type and color treatment. Home layout has no nav (intentional — it uses pills), so nav CSS only affects `page` and `post` layouts.

**Files:**
- Modify: `assets/css/main.css` (append)

- [ ] **Step 1: Append the nav block**

Append to `assets/css/main.css`:

```css
/* --------- Navigation --------- */

nav {
  font-family: var(--font-body);
  font-size: 0.875rem;
  font-weight: 500;
  padding: 1rem 0;
  border-bottom: 1px solid var(--rule);
  margin-bottom: 2.5rem;
  width: 100%;
  position: sticky;
  top: 0;
  background: var(--paper);
  z-index: 100;
  backdrop-filter: saturate(180%) blur(8px);
  -webkit-backdrop-filter: saturate(180%) blur(8px);
}

nav a {
  color: var(--ink);
  margin-right: 1.75rem;
  display: inline-block;
}

nav a:last-child {
  margin-right: 0;
}

nav a:hover {
  color: var(--rust);
  text-decoration: none;
}

nav a[aria-current="page"] {
  font-weight: 600;
  color: var(--ink);
}

nav a[aria-current="page"]:hover {
  color: var(--rust);
}

main#maincontent {
  margin-top: 0;
}
```

- [ ] **Step 2: Verify nav on non-home pages**

Reload http://localhost:4000/aboutme/, http://localhost:4000/blog/, http://localhost:4000/books/. The nav should:
- Span the top
- Use Inter 14px
- Have a thin bottom rule
- Show rust on hover
- Bold the current page

Home page should still have NO nav (it uses the pills in the hero).

- [ ] **Step 3: Commit**

```bash
cd /Users/kyleboon/code/kyleboon.org
git add assets/css/main.css
git commit -m "$(cat <<'EOF'
CSS: nav styling with rust hover and aria-current bold

Inter 14px sticky nav with a bottom rule and rust hover color. Current
page gets bolded via the existing aria-current="page" attribute. The
paper-colored backdrop-filter keeps the nav legible when it sticks over
scrolled content without washing out the typography.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 8: Home hero layout + quick-link pills

**Why:** This is the highest-visibility component on the site. It must feel anchored, not orphaned in whitespace.

**Files:**
- Modify: `assets/css/main.css` (append)

- [ ] **Step 1: Append the hero block**

Append to `assets/css/main.css`:

```css
/* --------- Home hero --------- */

.hero-section {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1.5rem;
  padding: 1rem 0 0;
  text-align: center;
}

.profile-image {
  width: 120px;
  height: 120px;
  flex-shrink: 0;
}

.profile-image img, .profile-image picture {
  width: 100%;
  height: 100%;
  object-fit: cover;
  border-radius: 50%;
  margin: 0;
  display: block;
}

.intro-text {
  width: 100%;
}

.intro-text h1 {
  font-size: clamp(3rem, 9vw, 5rem);
  line-height: 0.95;
  letter-spacing: -0.035em;
  font-variation-settings: "opsz" 144, "SOFT" 40;
  margin: 0 0 0.75rem;
}

/* Quick-link pills under the tagline */
.quick-links {
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  gap: 0.5rem;
  margin-top: 1.25rem;
}

.quick-links a {
  font-family: var(--font-body);
  font-size: 0.8125rem;
  font-weight: 500;
  padding: 0.4rem 1rem;
  border: 1px solid var(--rule);
  border-radius: var(--radius-pill);
  color: var(--ink);
  transition: border-color var(--ease), color var(--ease);
}

.quick-links a:hover, .quick-links a:focus {
  border-color: var(--rust);
  color: var(--rust);
  text-decoration: none;
}

/* Blog section under the hero */
.blog-section {
  padding: 0;
  margin-top: 3rem;
}

.blog-section h2 {
  font-size: 0.75rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.14em;
  color: var(--ink-dim);
  font-family: var(--font-body);
  margin: 0 0 1rem;
  padding-bottom: 0.5rem;
  border-bottom: 1px solid var(--rule);
  font-variation-settings: normal;
}

/* Tablet+ — side-by-side hero */
@media (min-width: 768px) {
  .hero-section {
    flex-direction: row;
    align-items: center;
    text-align: left;
    gap: 2rem;
    padding: 2rem 0 0;
  }

  .quick-links {
    justify-content: flex-start;
  }

  .blog-section {
    margin-top: 3.5rem;
  }
}
```

- [ ] **Step 2: Verify the home page**

Reload http://localhost:4000/. On desktop (≥ 768px) you should see:
- Round profile photo on the left
- Eyebrow + oversized H1 + tagline + pills on the right
- Everything left-aligned inside the column
- "RECENT WRITING" small caps label with a border under it
- Post list below (still unstyled — Task 9 fixes this)

On mobile, stack everything center-aligned.

**Troubleshooting:** If the H1 doesn't get oversized, there's a selector specificity issue — verify the `.intro-text h1` rule is being applied using DevTools.

- [ ] **Step 3: Commit**

```bash
cd /Users/kyleboon/code/kyleboon.org
git add assets/css/main.css
git commit -m "$(cat <<'EOF'
CSS: home hero layout and quick-link pills

Two-column hero on tablet+ (circular photo left, eyebrow + oversized
Fraunces H1 + tagline + pills right), stacks center-aligned on mobile.
Quick-link pills use the border-color hover treatment instead of a fill
shift. RECENT WRITING label uses the same eyebrow treatment as the role
label for visual rhyme.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 9: Blog list two-column date grid

**Why:** Addresses a shortfall from the original review ("blog list has no rhythm"). Desktop uses a date-title grid; mobile stacks.

**Files:**
- Modify: `assets/css/main.css` (append)

- [ ] **Step 1: Append the post-list block**

Append to `assets/css/main.css`:

```css
/* --------- Blog list (index + home recent) --------- */

.post-list {
  list-style: none;
  padding: 0;
  margin: 0;
}

.post-item {
  padding: 1rem 0;
  border-top: 1px solid var(--rule-soft);
}

.post-item:first-child {
  border-top: none;
  padding-top: 0;
}

.post-item .post-date {
  display: block;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  margin-bottom: 0.35rem;
}

.post-link {
  display: block;
  font-family: var(--font-display);
  font-size: 1.25rem;
  font-weight: 500;
  font-variation-settings: "opsz" 24;
  line-height: 1.3;
  color: var(--ink);
  letter-spacing: -0.005em;
  margin: 0;
  transition: color var(--ease);
}

.post-link:hover, .post-link:focus {
  color: var(--rust);
  text-decoration: none;
}

.post-item .post-description {
  font-family: var(--font-body);
  font-size: 0.9375rem;
  color: var(--ink-muted);
  margin: 0.5rem 0 0;
  line-height: 1.55;
}

/* Desktop — two-column date | title */
@media (min-width: 768px) {
  .post-item {
    display: grid;
    grid-template-columns: 9rem 1fr;
    align-items: baseline;
    gap: 1.5rem;
    padding: 1.1rem 0;
  }

  .post-item .post-date {
    margin: 0;
    padding-top: 0.25rem;
  }

  .post-item .post-description {
    grid-column: 2;
  }
}
```

- [ ] **Step 2: Verify the blog index and home recent list**

Reload http://localhost:4000/blog/ (desktop). You should see a two-column grid: dates on the left in uppercase Inter, titles on the right in Fraunces. Hover a title — it should turn rust.

Reload http://localhost:4000/ — the "Recent Writing" list on the home page uses the same treatment.

Resize the browser below 768px — the list should stack, with the date above the title.

- [ ] **Step 3: Commit**

```bash
cd /Users/kyleboon/code/kyleboon.org
git add assets/css/main.css
git commit -m "$(cat <<'EOF'
CSS: two-column date-title blog list on desktop

Adds the date-column grid for .post-list on tablet+ (9rem date column,
flexible title column). Mobile stacks with the date as an eyebrow-style
label above the title. Dates use uppercase tracked Inter; titles use
Fraunces at post-title optical size.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 10: Blog post — drop cap and body prose

**Why:** The drop cap is the second signature element. It must scope to `.post-body` content only so it never fires on about/books/etc.

**Files:**
- Modify: `assets/css/main.css` (append)

- [ ] **Step 1: Append the post-body block**

Append to `assets/css/main.css`:

```css
/* --------- Blog post body prose --------- */

.post-body {
  font-family: var(--font-body);
  font-size: 1.125rem;
  line-height: 1.65;
  color: var(--ink);
}

.post-body > h1:first-of-type {
  font-size: clamp(2rem, 5vw, 3rem);
  line-height: 1.02;
  letter-spacing: -0.025em;
  font-variation-settings: "opsz" 96, "SOFT" 35;
  margin: 0 0 1.5rem;
}

.post-body h2 {
  margin-top: 2rem;
}

.post-body h3 {
  margin-top: 1.5rem;
}

.post-body p {
  margin: 0 0 1.25em;
  color: var(--ink);
}

.post-body ul, .post-body ol {
  margin: 0 0 1.25em;
  padding-left: 1.5rem;
}

.post-body li {
  margin-bottom: 0.5em;
}

.post-body blockquote {
  margin: 1.5em 0;
  padding-left: 1.25rem;
  border-left: 2px solid var(--rust);
  color: var(--ink-muted);
  font-style: italic;
}

.post-body hr {
  border: 0;
  border-top: 1px solid var(--rule);
  margin: 2.5rem 0;
}

/* Drop cap — ONLY on the first paragraph after the post H1 */
.post-body > h1:first-of-type + p::first-letter {
  font-family: var(--font-display);
  font-variation-settings: "opsz" 144, "SOFT" 50;
  font-size: 5.5rem;
  line-height: 0.85;
  font-style: italic;
  font-weight: 500;
  color: var(--rust);
  float: left;
  margin: 0.5rem 0.75rem -0.25rem 0;
  padding: 0;
}

/* Fallback — if there is no H1 in the markdown (future posts might rely on layout title), drop cap the very first paragraph instead */
.post-body > p:first-of-type::first-letter {
  font-family: var(--font-display);
  font-variation-settings: "opsz" 144, "SOFT" 50;
  font-size: 5.5rem;
  line-height: 0.85;
  font-style: italic;
  font-weight: 500;
  color: var(--rust);
  float: left;
  margin: 0.5rem 0.75rem -0.25rem 0;
  padding: 0;
}
```

- [ ] **Step 2: Verify drop cap fires on a post**

Reload http://localhost:4000/2025/03/16/old-dogs-new-tricks/. The first paragraph after the H1 should begin with an oversized italic rust "U" (from "Update: I started..."). The drop cap should float left and the rest of the paragraph should flow around it.

Reload http://localhost:4000/2016/06/30/validating-an-http-post-with-ratpack/. Drop cap should also appear.

Reload http://localhost:4000/aboutme/ — NO drop cap (it's not a post, no `.post-body` wrapper).

**Troubleshooting:** If the drop cap doesn't render, inspect the first `<p>` in DevTools. `::first-letter` pseudo-elements appear under the parent in DevTools with their own style rules. If the selector isn't matching, check the structure — the h1 in the markdown might have a slightly different nesting than expected.

If the drop cap fires on the WRONG paragraph (e.g., a blockquote), the paragraph order in the markdown might start with a non-`<p>` element. That's a content problem, not a CSS problem — just note it and move on.

- [ ] **Step 3: Commit**

```bash
cd /Users/kyleboon/code/kyleboon.org
git add assets/css/main.css
git commit -m "$(cat <<'EOF'
CSS: post body prose and drop cap signature

Styles blog post prose (h1-h3, p, ul, blockquote, hr) with the new type
scale, and adds the drop cap via ::first-letter scoped to .post-body
content. Primary selector targets the first paragraph after the post
H1; fallback covers posts where the layout provides the H1 externally.
Fraunces italic at opsz 144, SOFT 50, rust color, float left.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 11: Books, presentations, footer, code/pre

**Why:** These are the remaining component-level styles. Grouped into one task because each is small and self-contained.

**Files:**
- Modify: `assets/css/main.css` (append)

- [ ] **Step 1: Append the remaining components block**

Append to `assets/css/main.css`:

```css
/* --------- Books list --------- */

.book-list {
  padding: 0;
  margin: 2.5rem 0;
}

.book-item {
  padding: 1.5rem 0;
  border-top: 1px solid var(--rule-soft);
  display: grid;
  grid-template-columns: 120px 1fr;
  gap: 1.5rem;
  align-items: start;
}

.book-item:first-child {
  border-top: none;
  padding-top: 0;
}

.book-cover {
  width: 120px;
  height: 180px;
  border-radius: var(--radius);
  object-fit: cover;
  margin: 0;
  transition: opacity var(--ease);
}

.book-item:hover .book-cover {
  opacity: 0.92;
}

.book-content {
  min-width: 0;
}

.book-item h3 {
  margin: 0 0 0.35em;
  font-size: 1.375rem;
  font-variation-settings: "opsz" 30, "SOFT" 20;
}

.book-author {
  font-family: var(--font-body);
  font-size: 0.9375rem;
  font-style: italic;
  color: var(--ink-dim);
  margin-bottom: 0.75em;
}

.book-item p {
  margin: 0.5em 0;
  font-size: 1rem;
  line-height: 1.6;
  color: var(--ink-muted);
}

@media (max-width: 640px) {
  .book-item {
    grid-template-columns: 90px 1fr;
    gap: 1rem;
    padding: 1.1rem 0;
  }

  .book-cover {
    width: 90px;
    height: 135px;
  }

  .book-item h3 {
    font-size: 1.25rem;
  }
}

/* --------- Presentations / talks --------- */

.talk-section {
  margin-bottom: 2.5rem;
}

.talk-section h2 {
  margin-bottom: 0.35em;
  margin-top: 0;
}

.talk-subtitle {
  font-family: var(--font-display);
  font-style: italic;
  font-size: 1.125rem;
  color: var(--ink-muted);
  margin-bottom: 0.5em;
  font-variation-settings: "opsz" 18;
}

.talk-meta {
  margin-bottom: 1em;
}

.talk-links {
  margin-top: 1em;
}

.talk-links ul {
  list-style: none;
  padding: 0;
  margin: 0;
}

.talk-links li {
  display: inline-block;
  margin-right: 1.5em;
}

/* --------- Code and pre --------- */

pre {
  font-family: var(--font-mono);
  font-size: 0.95rem;
  line-height: 1.55;
  padding: 1.1rem 1.25rem;
  margin: 1.5rem 0;
  overflow-x: auto;
  background: var(--rust-soft);
  border: 1px solid var(--rule);
  border-radius: var(--radius);
}

code {
  font-family: var(--font-mono);
  font-size: 0.92em;
  background: var(--rust-soft);
  padding: 0.1em 0.35em;
  border-radius: 3px;
  color: var(--ink);
}

pre code {
  background: transparent;
  padding: 0;
}

/* --------- Figure captions (markdown: ![alt](img)*caption*) --------- */

img + em {
  position: relative;
  top: -0.75em;
  display: block;
  margin: 0 auto;
  text-align: center;
  font-size: 0.875rem;
  color: var(--ink-dim);
  font-style: italic;
}

/* --------- Footer --------- */

footer {
  font-family: var(--font-body);
  font-size: 0.8125rem;
  font-style: italic;
  color: var(--ink-dim);
  margin: 4rem 0 2rem;
  padding-top: 1.5rem;
  border-top: 1px solid var(--rule-soft);
  line-height: 1.5;
}

footer a {
  color: var(--ink-dim);
}

footer a:hover {
  color: var(--rust);
}
```

- [ ] **Step 2: Verify books, presentations, and footer**

Reload http://localhost:4000/books/. Expected:
- No box-shadow card treatment
- Book items divided by a single top border rule
- Cover images on the left, title + author + description on the right
- Cover opacity dims slightly on hover

Reload http://localhost:4000/presentations/. Expected:
- Talk subtitles in Fraunces italic
- Meta rows in the small eyebrow treatment
- Clean typography hierarchy

Reload any page and scroll to the footer. Expected:
- Italic Inter in the dim-ink color
- A thin top border above it
- Muted but legible

- [ ] **Step 3: Commit**

```bash
cd /Users/kyleboon/code/kyleboon.org
git add assets/css/main.css
git commit -m "$(cat <<'EOF'
CSS: books, presentations, code blocks, footer

Books lose their box-shadow card treatment in favor of a single
border-top divider. Presentations page gets Fraunces italic subtitles.
Code and pre blocks use the monospace fallback chain with a rust-soft
tint background. Footer becomes quiet italic Inter in dim-ink.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 12: Accessibility — focus-visible, reduced motion, print

**Why:** Three accessibility improvements identified in the original review. All should be at the END of main.css so they have the highest specificity where needed (the reduced-motion override must come last).

**Files:**
- Modify: `assets/css/main.css` (append)

- [ ] **Step 1: Append the accessibility block**

Append to `assets/css/main.css`:

```css
/* --------- Focus --------- */

:focus-visible {
  outline: 2px solid var(--rust);
  outline-offset: 2px;
  border-radius: var(--radius);
}

a:focus-visible,
.quick-links a:focus-visible,
.post-link:focus-visible {
  outline: 2px solid var(--rust);
  outline-offset: 3px;
  text-decoration: none;
}

/* --------- Reduced motion --------- */

@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}

/* --------- Print --------- */

@media print {
  body {
    max-width: 100%;
    background: white;
    color: black;
    font-size: 11pt;
  }

  nav, footer, .quick-links {
    display: none;
  }

  a {
    color: black;
    text-decoration: underline;
  }

  .post-body > h1:first-of-type + p::first-letter,
  .post-body > p:first-of-type::first-letter {
    font-size: inherit;
    float: none;
    margin: 0;
    color: black;
  }
}
```

- [ ] **Step 2: Verify focus-visible and reduced motion**

In the browser, Tab through the home page. Each link and pill should get a visible rust outline on focus (keyboard only, not mouse — that's what `:focus-visible` enforces).

To verify reduced motion: open DevTools → Rendering → "Emulate CSS media feature prefers-reduced-motion: reduce" → reload page. Hover a link — the color should change instantly instead of fading.

To verify print: Cmd+P (macOS) or Ctrl+P. The preview should show the content without nav or footer, in black on white.

- [ ] **Step 3: Commit**

```bash
cd /Users/kyleboon/code/kyleboon.org
git add assets/css/main.css
git commit -m "$(cat <<'EOF'
CSS: focus-visible, reduced motion, print styles

Adds :focus-visible outlines in rust with offset, a full
prefers-reduced-motion override that disables transitions/animations,
and print styles that drop nav/footer/pills, remove the drop cap float,
and switch to black on white for ink economy. Addresses the
accessibility gaps called out in the original review.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 13: Visual verification across all pages

**Why:** Hand-verify that every page renders correctly in both themes and both viewports. This is the equivalent of running the test suite.

**Files:**
- Create: `/tmp/playwright-warm-craft-verify.js`
- Create: `/tmp/warm-craft-screenshots/*.png`

- [ ] **Step 1: Write the verification script**

Create `/tmp/playwright-warm-craft-verify.js` with exactly this content:

```javascript
const { chromium } = require('playwright');
const fs = require('fs');

const TARGET_URL = 'http://localhost:4000';
const OUT = '/tmp/warm-craft-screenshots';

const pages = [
  { name: 'home', path: '/' },
  { name: 'about', path: '/aboutme/' },
  { name: 'blog', path: '/blog/' },
  { name: 'books', path: '/books/' },
  { name: 'presentations', path: '/presentations/' },
  { name: 'resume', path: '/resume/' },
  { name: 'post-2025', path: '/2025/03/16/old-dogs-new-tricks/' },
  { name: 'post-2016', path: '/2016/06/30/validating-an-http-post-with-ratpack/' },
];

const viewports = [
  { name: 'desktop', width: 1440, height: 900 },
  { name: 'mobile', width: 390, height: 844 },
];

const themes = ['light', 'dark'];

(async () => {
  if (!fs.existsSync(OUT)) fs.mkdirSync(OUT);
  const browser = await chromium.launch({ headless: true });
  const ctx = await browser.newContext();

  for (const theme of themes) {
    for (const viewport of viewports) {
      const page = await ctx.newPage();
      await page.emulateMedia({ colorScheme: theme });
      await page.setViewportSize({ width: viewport.width, height: viewport.height });

      for (const p of pages) {
        try {
          await page.goto(`${TARGET_URL}${p.path}`, { waitUntil: 'networkidle', timeout: 15000 });
          const filename = `${OUT}/warm-craft-${p.name}-${viewport.name}-${theme}.png`;
          await page.screenshot({ path: filename, fullPage: true });
          console.log('Saved', filename);
        } catch (e) {
          console.error('Failed', p.name, viewport.name, theme, '-', e.message);
        }
      }
      await page.close();
    }
  }

  await browser.close();
  console.log('Done — 32 screenshots in', OUT);
})();
```

- [ ] **Step 2: Run it**

```bash
cd /Users/kyleboon/.claude/plugins/marketplaces/playwright-skill/skills/playwright-skill && node run.js /tmp/playwright-warm-craft-verify.js
```

Expected output: "Saved" lines for 32 combinations (8 pages × 2 viewports × 2 themes), then "Done".

- [ ] **Step 3: Review each screenshot**

Use the `Read` tool to open each PNG and compare against the style guide:

```
Read /tmp/warm-craft-screenshots/warm-craft-home-desktop-light.png
Read /tmp/warm-craft-screenshots/warm-craft-home-desktop-dark.png
Read /tmp/warm-craft-screenshots/warm-craft-home-mobile-light.png
Read /tmp/warm-craft-screenshots/warm-craft-blog-desktop-light.png
Read /tmp/warm-craft-screenshots/warm-craft-post-2025-desktop-light.png
```

...and so on.

**Review checklist (against docs/style-guide.md):**

- [ ] Home page shows oversized Fraunces H1, role eyebrow, cream paper background in light mode
- [ ] Home page shows oversized Fraunces H1, role eyebrow, cocoa background in dark mode
- [ ] Nav is present on about/blog/books/presentations/resume but NOT on home
- [ ] Blog list is two-column (date | title) on desktop, stacked on mobile
- [ ] Blog post has uppercase meta row (MARCH 16, 2025 · WRITING) above the H1
- [ ] Blog post has a visible drop cap on the first paragraph
- [ ] Books page has no card shadows — just top-border dividers
- [ ] Footer is italic Inter in dim ink
- [ ] Dark mode uses cocoa `#1c140e` not near-black — verify visually
- [ ] Links are rust, not blue, in both themes

- [ ] **Step 4: Fix any visual regressions discovered**

If any screenshot shows a problem (misaligned element, missing style, wrong color), identify the rule in `assets/css/main.css` that needs adjusting, fix it, save, re-run the relevant screenshots, verify, commit with a descriptive message.

Do NOT batch fixes — commit each visual fix as its own commit so the history stays clear.

- [ ] **Step 5: Commit verification artifacts and move on**

The screenshots live in `/tmp` and don't need to be committed. If you made fix commits in Step 4, that's sufficient.

---

## Task 14: HTML validity and link check

**Why:** html-proofer verifies there are no broken internal links, missing alt text, or malformed HTML in the built site. Required before declaring the redesign done.

**Files:**
- None (runs against `_site/`)

- [ ] **Step 1: Build the site**

```bash
cd /Users/kyleboon/code/kyleboon.org
bundle exec jekyll build
```

Expected: no errors, `_site/` directory populated.

- [ ] **Step 2: Run html-proofer**

```bash
cd /Users/kyleboon/code/kyleboon.org
bundle exec htmlproofer ./_site --disable-external --allow-missing-href
```

The `--disable-external` flag skips external link checks (social media, etc.) which can fail for network reasons unrelated to our changes. `--allow-missing-href` is kept for compatibility with any anchor tags that intentionally lack href.

Expected: "HTML-Proofer finished successfully." or similar success message.

- [ ] **Step 3: Fix any html-proofer errors**

Common issues:
- Broken internal link: update the href
- Missing alt on an image: add `alt=""` (decorative) or a descriptive string
- Duplicate IDs: ensure no two elements share the same `id`

Fix inline, rebuild, rerun htmlproofer until clean.

- [ ] **Step 4: Commit any fixes**

```bash
cd /Users/kyleboon/code/kyleboon.org
git add <fixed-files>
git commit -m "Fix htmlproofer issues: <short summary>

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

Skip this step if htmlproofer passed on the first run.

---

## Task 15: Performance budget verification

**Why:** The spec sets a ≤150KB critical-path budget. Verify we're under it before closing out.

**Files:**
- None (reads from `_site/`)

- [ ] **Step 1: Check CSS file size**

```bash
cd /Users/kyleboon/code/kyleboon.org
ls -l _site/assets/css/main.css
```

Expected: under 15KB. If over, something is bloated — inspect the file and remove unused rules.

- [ ] **Step 2: Check font file sizes**

```bash
ls -l _site/assets/fonts/
```

Expected: combined total under 200KB (Fraunces full variable ~80-120KB + Inter wght ~40-60KB).

If Fraunces is significantly over 120KB, the "full" file includes more axes than necessary. Consider swapping to `fraunces-latin-wght-normal.woff2` (wght only) — you'll lose opsz/SOFT control but save 30-40KB. This is a tradeoff to discuss with the user before committing.

- [ ] **Step 3: Measure home page total byte weight**

Build a fresh copy and read the file sizes:

```bash
cd /Users/kyleboon/code/kyleboon.org
bundle exec jekyll build
du -h _site/index.html \
       _site/assets/css/main.css \
       _site/assets/fonts/fraunces-latin-full.woff2 \
       _site/assets/fonts/inter-latin-wght.woff2 \
       _site/assets/images/headshot.webp
```

Sum these. Expected: ≤ 200KB total before transfer compression (gzip/brotli on the GitHub Pages edge will shrink the text assets by ~3–5x). The fonts are already compressed (woff2 = brotli) so they don't shrink further.

Record the result in a local note — it'll be useful for future performance regressions.

- [ ] **Step 4: Confirm zero JavaScript**

```bash
grep -r "<script" _site/ 2>/dev/null | grep -v ".js:" || echo "No <script> tags found — good"
find _site -name "*.js" 2>/dev/null | grep -v "sitemap\|feed" || echo "No .js files — good"
```

Both should report "No ... found". If anything slips in, track it down.

---

## Task 16: Final review and optional PR

**Why:** Step back, look at the full diff against main, decide whether to merge directly or open a PR for review.

- [ ] **Step 1: Review the full diff**

```bash
cd /Users/kyleboon/code/kyleboon.org
git log --oneline main..HEAD
git diff main..HEAD --stat
```

Expected: ~14 commits covering fonts, layouts, CSS tasks, and any fix commits.

- [ ] **Step 2: Ask the user how to proceed**

Present options:

1. **Push directly to main** — if working alone on a personal site
2. **Open a PR for self-review** — if you want a pre-merge checkpoint on GitHub
3. **Iterate more** — if any screenshots from Task 13 still need fixing

Wait for the user to choose. Do NOT push or open a PR without explicit authorization — this site is deployed from the main branch via GitHub Pages and any push triggers a redeploy.

---

## Coverage check against the spec

Before declaring done, confirm each spec item has a task:

| Spec item | Covered by |
|---|---|
| Self-hosted Fraunces + Inter fonts | Task 1 |
| Font preload in head | Task 3 |
| Theme-color meta tags updated | Task 3 |
| Role eyebrow on home | Tasks 4, 6, 8 |
| New post layout with meta row | Task 2 |
| Drop cap on blog posts | Task 10 |
| Two-column blog list on desktop | Task 9 |
| Books page without card shadows | Task 11 |
| Light palette tokens | Task 5 |
| Dark palette tokens | Task 5 |
| Wider reading measure | Task 5 |
| Monospace fallback chain | Task 11 |
| `:visited` link color | Task 5 |
| `:focus-visible` outline | Task 12 |
| `prefers-reduced-motion` override | Task 12 |
| `prefers-color-scheme` (existing, preserved) | Task 5 |
| Print styles | Task 12 (bonus, not in spec but harmless) |
| Zero JavaScript | Task 15 verification |
| Performance budget | Task 15 verification |
| htmlproofer passes | Task 14 |
| Visual verification across all pages | Task 13 |

All 20 items accounted for.
