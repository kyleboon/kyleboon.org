# Resume Page Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the resume page with a dedicated layout, two-column date grid for job entries, label-value skills grid, and a header that matches the site's editorial-eyebrow pattern.

**Architecture:** New `_layouts/resume.html` inherits from `page` and renders the header from front matter variables. The resume content in `resume.md` is restructured from pure markdown to semantic HTML with classes that CSS targets for the two-column grids. All styling appended to the existing single `assets/css/main.css`.

**Tech Stack:** Jekyll 4.4, Liquid templates, CSS Grid, kramdown (though HTML blocks bypass kramdown processing).

**Reference documents:**
- Spec: `docs/superpowers/specs/2026-04-10-resume-redesign-design.md`
- Style guide: `docs/style-guide.md`
- Warm Craft redesign spec (for context): `docs/superpowers/specs/2026-04-09-warm-craft-redesign-design.md`

---

## Pre-flight

Verify you can build and serve the site:

```bash
cd <worktree-path>
bundle install
bundle exec jekyll serve --host 0.0.0.0
```

Confirm http://localhost:4000/resume/ renders the current (pre-redesign) resume page. Leave Jekyll running.

---

## Task 1: Create the resume layout

**Why:** The resume header (eyebrow + H1 + role line + summary) must be rendered from front matter variables by the layout, not from the markdown body. A dedicated layout gives us this control while inheriting nav + footer from `page`.

**Files:**
- Create: `_layouts/resume.html`

- [ ] **Step 1: Create the layout file**

Create `_layouts/resume.html` with exactly this content:

```html
---
layout: page
---
<header class="resume-header">
  <p class="resume-eyebrow">Resume</p>
  <h1 class="resume-name">{{ page.name }}</h1>
  <p class="resume-specialties">
    {{ page.role }}
    {%- for s in page.specialties %} · {{ s }}{%- endfor -%}
  </p>
  <p class="resume-summary">{{ page.summary }}</p>
</header>
{{ content }}
```

**How this works:**
- `layout: page` in the front matter tells Jekyll to wrap this layout's output inside `_layouts/page.html`, giving us the nav, `<main>`, and footer for free.
- The `<header>` block reads `page.name`, `page.role`, `page.specialties` (an array), and `page.summary` from the resume page's front matter.
- The `for` loop over `specialties` joins them with middots: "Principal Software Engineer · Distributed Systems · Cloud Architecture · Technical Leadership".
- `{{ content }}` renders whatever HTML is in `resume.md` below its front matter.

- [ ] **Step 2: Verify the layout file exists and is syntactically valid**

```bash
cat _layouts/resume.html
```

Confirm it matches the content above. Check that Liquid tags have matching `{%` / `%}` pairs and no stray characters.

- [ ] **Step 3: Commit**

```bash
git add _layouts/resume.html
git commit -m "$(cat <<'EOF'
Add dedicated resume layout with front matter-driven header

New _layouts/resume.html inherits from page and renders the resume
header from front matter variables: name (Fraunces H1), role +
specialties (middot-separated Inter), and summary paragraph. This
replaces the pipe-separated H1 that was previously in the markdown
body. The layout passes {{ content }} through for the structured
HTML job entries and skills grid.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Restructure resume.md

**Why:** The current `resume.md` is pure markdown (`##`, `###`, `**bold**`, `-` bullets). The new design needs semantic HTML classes (`.resume-entry`, `.resume-date`, `.resume-company`, etc.) for the CSS two-column grid to work. Kramdown does NOT process markdown inside HTML blocks, so all bullet lists must use `<ul><li>` tags.

**Files:**
- Modify: `resume.md` (complete rewrite)

- [ ] **Step 1: Replace the entire contents of resume.md**

Replace the full contents of `resume.md` with exactly this content. This preserves ALL existing text content — only the markup structure changes.

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
  Principal Software Engineer with 20+ years of experience specializing in
  distributed systems, cloud architecture, and technical transformations.
  Proven track record of modernizing monolithic applications into scalable
  microservices while mentoring engineering teams to deliver high-quality
  solutions. Expert in designing systems that balance performance,
  reliability, and business outcomes, from customer MDM systems supporting
  800M+ users to platform modernization across enterprise-scale global
  operations.
---

<section class="resume-section">
  <h2 class="resume-section-title">Experience</h2>

  <div class="resume-entry">
    <div class="resume-date">Apr 2025 –<br>Present</div>
    <div class="resume-content">
      <h3 class="resume-company">RB Global</h3>
      <p class="resume-role">Principal Software Engineer · Remote</p>
      <ul class="resume-bullets">
        <li>Provide technical leadership across enterprise-scale platforms, driving architecture and design decisions for large-scale, business-critical systems supporting global operations.</li>
        <li>Drive technical direction across multiple teams, ensuring alignment with enterprise standards, security, and data governance practices.</li>
        <li>Partner with product, data, and business stakeholders to design systems that balance velocity, quality, and maintainability.</li>
        <li>Influence platform evolution in master data management, domain modeling, and regulatory-driven system design including data residency and compliance initiatives.</li>
        <li>Contribute to enterprise architecture forums and guilds, shaping shared patterns, principles, and best practices across the organization.</li>
        <li>Mentor senior and mid-level engineers, raising the bar for engineering excellence across the organization.</li>
      </ul>
    </div>
  </div>

  <div class="resume-entry">
    <div class="resume-date">Jun 2022 –<br>Mar 2025</div>
    <div class="resume-content">
      <h3 class="resume-company">Wayfair</h3>
      <p class="resume-role">Staff Software Engineer · Remote</p>
      <ul class="resume-bullets">
        <li>Architected and implemented B2B Project Shopping features through federated GraphQL schema design, successfully integrating order management, supply chain, and internal sales workflows.</li>
        <li>Designed and delivered a scalable customer master data management system handling 800M+ global customers, improving B2B enrollment time by 95% and reducing data synchronization errors by over 99%.</li>
        <li>Established domain-driven design practices to help teams properly identify bounded contexts and negotiated those boundaries across the Wayfair organization to ensure data and processes were owned by a single team.</li>
        <li>Developed a RAG LLM pipeline for customer service agents that increased the number of concurrent chats an agent could handle by recommending responses to customer questions.</li>
      </ul>
    </div>
  </div>

  <div class="resume-entry">
    <div class="resume-date">Apr 2017 –<br>Jun 2022</div>
    <div class="resume-content">
      <h3 class="resume-company">Target</h3>
      <p class="resume-role">Lead Software Engineer · Minneapolis, MN</p>
      <ul class="resume-bullets">
        <li>Developed Target's Inventory Position and Control systems migration from the legacy mainframe to a microservices architecture built on Kafka which positioned over $100 billion worth of inventory across 1900 stores.</li>
        <li>Architected and implemented the task management system as part of a greenfield warehousing management system.</li>
        <li>Mentored college new hires as a part of the Target Leadership Program.</li>
        <li>Interviewed college students for internship and new hire positions.</li>
        <li>Served as track lead for Target's internal technology conference for two consecutive years, organizing 25+ technical sessions and personally delivering presentations on microservices architecture and distributed systems.</li>
      </ul>
    </div>
  </div>

  <div class="resume-entry">
    <div class="resume-date">Mar 2015 –<br>Apr 2017</div>
    <div class="resume-content">
      <h3 class="resume-company">SmartThings</h3>
      <p class="resume-role">Senior Software Engineer / Team Lead · Minneapolis, MN</p>
      <ul class="resume-bullets">
        <li>Led a cross-functional distributed team of 10 engineers across three global locations to successfully revamp the SmartThings App Marketplace.</li>
        <li>Architected and implemented critical microservices during SmartThings' monolith decomposition, establishing best practices for API design and service boundaries.</li>
        <li>Executed zero-downtime database migrations from MySQL to Cassandra and Aurora for high-traffic services.</li>
      </ul>
    </div>
  </div>

  <div class="resume-entry">
    <div class="resume-date">Jun 2012 –<br>Mar 2015</div>
    <div class="resume-content">
      <h3 class="resume-company">Bloom Health</h3>
      <p class="resume-role">Technical Lead · Minneapolis, MN</p>
      <ul class="resume-bullets">
        <li>Scaled engineering organization from 8 to 30 developers.</li>
        <li>Led architectural transformation from monolith to microservices architecture, establishing patterns and practices.</li>
        <li>Architected integration between core platform and external Benefits Administration PaaS, enabling Bloom Health to expand service offerings to enterprise clients.</li>
        <li>Designed and implemented SSO solution across application suite using CAS and SAML, enhancing security posture while simplifying user experience.</li>
      </ul>
    </div>
  </div>

  <div class="resume-entry">
    <div class="resume-date">Jun 2011 –<br>Jun 2012</div>
    <div class="resume-content">
      <h3 class="resume-company">Bloom Health</h3>
      <p class="resume-role">Senior Software Developer · Minneapolis, MN</p>
      <ul class="resume-bullets">
        <li>Built financial integrations for HSA/FSA/HRA management.</li>
        <li>Implemented Redis caching layer that reduced page load times by 70% and improved system resilience during traffic spikes.</li>
      </ul>
    </div>
  </div>

  <div class="resume-entry">
    <div class="resume-date">Jul 2006 –<br>Jun 2011</div>
    <div class="resume-content">
      <h3 class="resume-company">IBM</h3>
      <p class="resume-role">IT Specialist · Minneapolis, MN</p>
      <ul class="resume-bullets">
        <li>Led development of healthcare data visualization platform for Georgia residents, delivering MVP in under 3 months using Ruby on Rails and Google Maps.</li>
        <li>Awarded US Patent #7406689 – "Jobstream Planner Considering Network Contention and Resource Availability."</li>
      </ul>
    </div>
  </div>

  <div class="resume-entry">
    <div class="resume-date">Mar 2005 –<br>Jun 2006</div>
    <div class="resume-content">
      <h3 class="resume-company">What If Sports</h3>
      <p class="resume-role">Software Developer · Cincinnati, OH</p>
      <ul class="resume-bullets">
        <li>Developed company's highest-grossing product (HardBallDynasty), generating $20,000 in first-day sales.</li>
        <li>Implemented quality engineering practices including automated testing and defect tracking systems.</li>
      </ul>
    </div>
  </div>
</section>

<section class="resume-section">
  <h2 class="resume-section-title">Skills</h2>

  <div class="resume-skills">
    <div class="resume-skill-label">Languages</div>
    <div class="resume-skill-values">Kotlin, Java, Python, Go, TypeScript, JavaScript, SQL</div>

    <div class="resume-skill-label">Frameworks &amp; APIs</div>
    <div class="resume-skill-values">Spring Boot, Http4k, Hibernate, GraphQL, gRPC, Protocol Buffers, REST</div>

    <div class="resume-skill-label">AI / ML</div>
    <div class="resume-skill-values">RAG pipelines, LLM integration, OpenAI API, Anthropic API</div>

    <div class="resume-skill-label">Infrastructure</div>
    <div class="resume-skill-values">AWS, Google Cloud, Kubernetes, Docker, Terraform, Kafka, Redis, Elasticsearch, RabbitMQ, PostgreSQL, MySQL, DynamoDB, Cassandra, Snowflake</div>

    <div class="resume-skill-label">CI/CD &amp; Observability</div>
    <div class="resume-skill-values">GitHub Actions, GitLab CI, Gradle, Maven, Git, Datadog, Grafana, ELK</div>

    <div class="resume-skill-label">Leadership</div>
    <div class="resume-skill-values">Technical Mentorship, Distributed Team Leadership, Cross-functional Collaboration, Strategic Technical Planning, System Design &amp; Architecture Review, Technical Debt Management, Legacy System Modernization</div>
  </div>
</section>

<section class="resume-section">
  <h2 class="resume-section-title">Education</h2>

  <div class="resume-entry">
    <div class="resume-date">Mar 2005</div>
    <div class="resume-content">
      <h3 class="resume-company">The Ohio State University</h3>
      <p class="resume-role">B.S. Computer Science &amp; Engineering · Columbus, OH</p>
    </div>
  </div>
</section>
```

**Important notes on this content:**
- All `&` characters in HTML must be `&amp;` (e.g., "Frameworks &amp; APIs", "CI/CD &amp; Observability").
- The `<br>` in date divs creates the line break between "Jun 2022 –" and "Mar 2025" in the date column.
- Bloom Health appears twice (two separate entries with different dates and roles) per the spec's "Bloom Health special case" decision.
- Every single bullet from the original `resume.md` is preserved — zero content changes, only markup changes.

- [ ] **Step 2: Verify the front matter is valid YAML**

```bash
bundle exec jekyll build 2>&1 | tail -5
```

If there's a YAML error, it will appear here. Common issues: missing closing `>-` on the summary, incorrect indentation on the specialties array, tabs instead of spaces.

- [ ] **Step 3: Verify the resume page renders**

```bash
grep -c "resume-entry" _site/resume/index.html
```

Expected: `8` (one per job entry).

```bash
grep -c "resume-skill-label" _site/resume/index.html
```

Expected: `6` (one per skill category).

```bash
grep "resume-eyebrow" _site/resume/index.html
```

Expected: a match showing the "Resume" eyebrow from the layout.

```bash
grep "resume-name" _site/resume/index.html
```

Expected: a match showing "Kyle Boon" in the H1.

- [ ] **Step 4: Verify no content was lost**

Spot-check key content items are present in the generated HTML:

```bash
grep "US Patent" _site/resume/index.html && echo "IBM patent: ✓"
grep "HardBallDynasty" _site/resume/index.html && echo "What If Sports: ✓"
grep "800M" _site/resume/index.html && echo "Wayfair MDM: ✓"
grep "Ohio State" _site/resume/index.html && echo "Education: ✓"
```

All four should succeed.

- [ ] **Step 5: Commit**

```bash
git add resume.md
git commit -m "$(cat <<'EOF'
Restructure resume.md with semantic HTML for two-column grid

Converts resume from pure markdown to HTML with semantic classes
(.resume-entry, .resume-date, .resume-content, .resume-company,
.resume-role, .resume-bullets, .resume-skills, .resume-skill-label,
.resume-skill-values) that the CSS will target for the editorial
column layout.

Front matter gains name, role, specialties (array), and summary
fields that the resume layout renders as the page header. Layout
changed from page to resume.

All original content preserved verbatim — only markup structure
changed. Bloom Health appears as two separate entries (Senior
Developer 2011-2012, Technical Lead 2012-2015) per the design spec.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Resume CSS — header, section titles, job grid, skills grid, mobile

**Why:** This is the visual heart of the redesign. All resume-specific styles go in one CSS append since they form a cohesive component block and depend on each other (the header flows into sections which contain the grid entries).

**Files:**
- Modify: `assets/css/main.css` (append to end, BEFORE the accessibility block)

- [ ] **Step 1: Find the insertion point**

The accessibility rules (`/* --------- Focus --------- */`) must remain at the END of the stylesheet for cascade priority. Find the line number:

```bash
grep -n "Focus ---------" assets/css/main.css
```

Note the line number. The new resume block goes IMMEDIATELY BEFORE this line.

- [ ] **Step 2: Insert the resume CSS block**

Insert this entire block into `assets/css/main.css` immediately before the `/* --------- Focus --------- */` comment:

```css
/* --------- Resume --------- */

.resume-header {
  margin-bottom: 2rem;
}

.resume-eyebrow {
  font-family: var(--font-body);
  font-size: 0.75rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.16em;
  color: var(--ink-dim);
  margin: 0 0 0.75rem;
  line-height: 1;
}

.resume-name {
  font-family: var(--font-display);
  font-size: clamp(2rem, 4vw, 2.75rem);
  line-height: 1.05;
  letter-spacing: -0.02em;
  font-variation-settings: "opsz" 72, "SOFT" 30;
  font-weight: 600;
  color: var(--ink);
  margin: 0 0 0.5rem;
}

.resume-specialties {
  font-family: var(--font-body);
  font-size: 1rem;
  color: var(--ink-muted);
  margin: 0 0 1.25rem;
  line-height: 1.5;
}

.resume-summary {
  font-family: var(--font-body);
  font-size: 0.9375rem;
  line-height: 1.6;
  color: var(--ink-muted);
  margin: 0;
  max-width: 60ch;
}

/* Section titles (EXPERIENCE, SKILLS, EDUCATION) */
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
  font-variation-settings: normal;
}

.resume-section:first-of-type .resume-section-title {
  margin-top: 0;
}

/* Job entries — two-column date grid */
.resume-entry {
  padding: 1.1rem 0;
  border-top: 1px solid var(--rule-soft);
}

.resume-entry:first-of-type {
  border-top: none;
  padding-top: 0;
}

.resume-date {
  font-family: var(--font-body);
  font-size: 0.75rem;
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  color: var(--ink-dim);
  line-height: 1.4;
  margin-bottom: 0.5rem;
}

.resume-company {
  font-family: var(--font-display);
  font-size: 1.25rem;
  font-weight: 600;
  font-variation-settings: "opsz" 24;
  color: var(--ink);
  margin: 0 0 0.15rem;
  line-height: 1.25;
}

.resume-role {
  font-family: var(--font-body);
  font-size: 0.875rem;
  font-style: italic;
  color: var(--ink-dim);
  margin: 0 0 0.6rem;
  line-height: 1.4;
}

.resume-bullets {
  margin: 0;
  padding-left: 1.1rem;
  list-style: disc;
}

.resume-bullets li {
  font-family: var(--font-body);
  font-size: 0.875rem;
  line-height: 1.55;
  color: var(--ink-muted);
  margin-bottom: 0.35rem;
}

.resume-bullets li::marker {
  color: var(--rust);
}

.resume-bullets li:last-child {
  margin-bottom: 0;
}

/* Skills grid */
.resume-skills {
  display: grid;
  grid-template-columns: 10rem 1fr;
  gap: 0.5rem 1.5rem;
}

.resume-skill-label {
  font-family: var(--font-body);
  font-size: 0.6875rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  color: var(--ink-dim);
  padding-top: 0.15rem;
}

.resume-skill-values {
  font-family: var(--font-body);
  font-size: 0.875rem;
  color: var(--ink-muted);
  line-height: 1.55;
}

/* Desktop — two-column grid for entries */
@media (min-width: 768px) {
  .resume-entry {
    display: grid;
    grid-template-columns: 9rem 1fr;
    gap: 0 1.5rem;
  }

  .resume-date {
    margin-bottom: 0;
    padding-top: 0.2rem;
  }
}

/* Mobile — skills grid stacks */
@media (max-width: 767px) {
  .resume-skills {
    grid-template-columns: 1fr;
    gap: 0.25rem;
  }

  .resume-skill-label {
    margin-top: 0.75rem;
  }

  .resume-skill-label:first-of-type {
    margin-top: 0;
  }
}
```

- [ ] **Step 3: Verify the CSS is syntactically correct**

```bash
bundle exec jekyll build 2>&1 | tail -3
```

Expected: build succeeds with no errors.

Check brace balance:
```bash
open=$(grep -c "{" assets/css/main.css)
close=$(grep -c "}" assets/css/main.css)
echo "Open: $open, Close: $close"
```

Must be equal.

- [ ] **Step 4: Verify the resume page structure in the generated HTML**

```bash
grep -c "resume-header" _site/resume/index.html
grep -c "resume-entry" _site/resume/index.html
grep -c "resume-skills" _site/resume/index.html
```

Expected: `1` header, `8` entries (or `9` including education), `1` skills grid.

- [ ] **Step 5: Commit**

```bash
git add assets/css/main.css
git commit -m "$(cat <<'EOF'
CSS: resume layout — header, job grid, skills grid, mobile

Adds all resume-specific styles: eyebrow + Fraunces H1 + role line +
summary header, section title treatment matching RECENT WRITING on
the home page, two-column date grid for job entries (9rem date column,
1fr content) on tablet+, label-value grid for skills (10rem labels),
and mobile stacking for both grids. Rust-colored bullet markers. All
rules use existing design tokens — no new values introduced.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Visual verification and htmlproofer

**Why:** The resume has the most structured HTML on the site. Verify it renders correctly across viewports and themes, and that htmlproofer is clean.

**Files:**
- Create: `/tmp/playwright-resume-verify.js` (temp, not committed)

- [ ] **Step 1: Take screenshots**

Write `/tmp/playwright-resume-verify.js`:

```javascript
const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const ctx = await browser.newContext();
  const page = await ctx.newPage();

  const configs = [
    { name: 'desktop-light', width: 1440, height: 900, theme: 'light' },
    { name: 'desktop-dark', width: 1440, height: 900, theme: 'dark' },
    { name: 'mobile-light', width: 390, height: 844, theme: 'light' },
    { name: 'tablet-light', width: 820, height: 1180, theme: 'light' },
  ];

  for (const c of configs) {
    await page.emulateMedia({ colorScheme: c.theme });
    await page.setViewportSize({ width: c.width, height: c.height });
    await page.goto('http://localhost:4000/resume/', { waitUntil: 'networkidle' });
    await page.screenshot({ path: `/tmp/resume-new-${c.name}.png`, fullPage: true });
    console.log(`Saved /tmp/resume-new-${c.name}.png`);
  }

  await browser.close();
})();
```

Run it:
```bash
cd <playwright-skill-path> && node run.js /tmp/playwright-resume-verify.js
```

- [ ] **Step 2: Review screenshots against the spec**

Open each PNG and verify:

- [ ] Header shows: "RESUME" eyebrow, "Kyle Boon" in Fraunces, middot-separated role line, summary paragraph
- [ ] Experience section: "EXPERIENCE" section label with bottom rule
- [ ] Job entries: date on left, company in Fraunces, role in italic, rust bullet markers
- [ ] Separators between jobs (thin border-top)
- [ ] Skills section: label-value grid with uppercase labels
- [ ] Education section at bottom
- [ ] Dark mode: cocoa background, cream text, copper accents
- [ ] Mobile: grids stack, date becomes eyebrow above company
- [ ] Tablet: two-column grid works at 820px width

- [ ] **Step 3: Fix any visual regressions**

If any screenshot shows a problem (misaligned grid, missing styles, wrong colors), identify the CSS rule, fix it, rebuild, re-screenshot, verify. Commit each fix individually.

- [ ] **Step 4: Run htmlproofer**

```bash
bundle exec jekyll build && bundle exec htmlproofer ./_site --disable-external --allow-missing-href 2>&1 | tail -10
```

Expected: "HTML-Proofer finished successfully."

Common issues with the restructured resume:
- Unescaped `&` in HTML (must be `&amp;`) — check "Frameworks & APIs", "CI/CD & Observability", "Computer Science & Engineering"
- Missing closing `</ul>`, `</div>`, `</section>` tags — verify all are balanced

Fix any errors, rebuild, rerun htmlproofer until clean. Commit fixes.

- [ ] **Step 5: Commit verification fixes if any**

Skip if htmlproofer and screenshots passed on first try.

---

## Task 5: Update style guide

**Why:** The style guide is the living reference for the design system. The new resume component classes need to be documented so future design sessions know they exist.

**Files:**
- Modify: `docs/style-guide.md`

- [ ] **Step 1: Add a resume section to the style guide**

Open `docs/style-guide.md`. Find the section `### Footer` (inside `## 5. Components`). After the Footer section, add:

```markdown
### Resume

Dedicated layout (`_layouts/resume.html`) with header rendered from front matter variables.

**Header structure:** `.resume-eyebrow` (same treatment as home "RECENT WRITING") → `.resume-name` (Fraunces page-scale H1) → `.resume-specialties` (Inter, `--ink-muted`, middot-separated) → `.resume-summary` (Inter body, `--ink-muted`, `max-width: 60ch`).

**Section titles:** `.resume-section-title` — same eyebrow treatment as blog list section header (uppercase, tracked, `--ink-dim`, bottom rule).

**Job entries:** `.resume-entry` uses a two-column CSS grid on ≥ 768px:
- Left: `.resume-date` (9rem, uppercase tracked Inter, `--ink-dim`)
- Right: `.resume-content` containing `.resume-company` (Fraunces H3, opsz 24), `.resume-role` (italic Inter, `--ink-dim`), and `.resume-bullets` (Inter 0.875rem, `--ink-muted`, rust bullet markers)
- Separator: `border-top: 1px solid var(--rule-soft)` between entries
- Mobile: stacks — date becomes eyebrow above company

**Skills:** `.resume-skills` grid (10rem label column, 1fr values). Labels use uppercase tracked treatment. Mobile stacks.

**Education:** Same `.resume-entry` grid as job entries.
```

- [ ] **Step 2: Commit**

```bash
git add docs/style-guide.md
git commit -m "$(cat <<'EOF'
Document resume component classes in style guide

Adds the resume section to the components documentation: header
structure from front matter, section titles, two-column job entry
grid, skills label-value grid, and education. References the same
pattern language (eyebrow, date column, rule-soft separator) used
across the rest of the site.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Coverage check against the spec

| Spec item | Covered by |
|---|---|
| New `_layouts/resume.html` | Task 1 |
| Front matter variables (name, role, specialties, summary) | Tasks 1, 2 |
| Eyebrow "RESUME" label | Task 1 (layout), Task 3 (CSS) |
| H1 "Kyle Boon" in Fraunces page-scale | Task 1 (layout), Task 3 (CSS) |
| Middot-separated role line | Task 1 (Liquid loop) |
| Summary paragraph | Task 1 (layout), Task 3 (CSS) |
| Section title treatment | Task 3 (CSS) |
| Two-column date grid for jobs (≥ 768px) | Tasks 2, 3 |
| Company in Fraunces H3 | Task 3 (CSS) |
| Role in italic Inter | Task 3 (CSS) |
| Rust bullet markers | Task 3 (CSS) |
| Separator between jobs | Task 3 (CSS) |
| Mobile grid collapse | Task 3 (CSS media query) |
| Skills label-value grid | Tasks 2, 3 |
| Skills mobile collapse | Task 3 (CSS media query) |
| Education entry | Task 2 |
| Bloom Health two separate entries | Task 2 |
| Restructured resume.md with HTML classes | Task 2 |
| htmlproofer passes | Task 4 |
| Visual verification | Task 4 |
| Style guide updated | Task 5 |

All spec items accounted for.
