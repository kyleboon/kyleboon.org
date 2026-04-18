# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Jekyll-based personal website hosted on GitHub Pages at www.kyleboon.org. It contains blog posts, a resume, presentations page, about page, and books page.

## Commands

- **Install dependencies:** `bundle install`
- **Run locally:** `bundle exec jekyll serve` (serves at http://localhost:4000)
- **Build site:** `bundle exec jekyll build` (outputs to `_site/`)
- **Validate HTML:** `bundle exec htmlproofer ./_site`

## Architecture

- **Layouts:** Four layouts in `_layouts/`:
  - `home.html` — no nav, used for index page (hero + recent posts)
  - `page.html` — includes sticky nav header, used for About, Blog, Books, Presentations
  - `post.html` — inherits from `page`, adds meta row (date + category) and wraps content in `<article class="post-body">` with Liquid-injected drop cap
  - `resume.html` — inherits from `page`, renders header from front matter variables (display_name, role, specialties, summary)
- **Includes:** `_includes/head.html` (meta tags, font preloads, CSS) and `_includes/footer.html`
- **Posts:** Markdown files in `_posts/` using `YYYY-MM-DD-slug.md` naming convention with `layout: post` front matter. The `_config.yml` defaults block sets `layout: post` for all posts automatically.
- **Top-level pages:** `index.html`, `aboutme.html`, `blog.html`, `books.html`, `presentations.html`, `resume.md`
- **CSS:** Single stylesheet at `assets/css/main.css` using the Warm Craft design system (Fraunces + Inter, cream/cocoa palette, rust accent). All design tokens are CSS custom properties.
- **Fonts:** Self-hosted variable fonts in `assets/fonts/` — Fraunces (display) and Inter (body), Latin subset woff2 files. CSP requires `font-src 'self'`.
- **Design system:** `docs/style-guide.md` is the living reference for typography, color tokens, components, and do/don't rules. Read this before making visual changes.
- **Scripts:**
  - `scripts/fetch_covers.sh` downloads book cover images from Google Books API into `assets/images/books/`
  - `scripts/optimize_images.sh [directory]` resizes images to 1200px wide, converts to WebP, and removes originals. Run before committing new images.

## Images

**ALWAYS** verify images before committing:
1. Run `scripts/optimize_images.sh` on any directory with new images.
2. Confirm all images are WebP format and no larger than ~200KB each.
3. Remove any images not referenced in HTML/Markdown files.

## Post Front Matter

Posts use this front matter format:
```yaml
---
layout: post
title: Post Title
date: YYYY-MM-DD
---
```

## Design

The site uses the **Warm Craft** design system: Fraunces serif for display/headings, Inter sans for body/UI, a paper-and-ink metaphor (cream `#f6f1e8` light / cocoa `#1c140e` dark), and a rust accent (`#b5581f` / `#d08858`). Zero JavaScript, no CSS framework. See `docs/style-guide.md` for the full token reference, component patterns, and do/don't rules.

Key visual patterns:
- **Eyebrow labels** (uppercase tracked Inter) above H1s on every content page
- **Two-column date grid** on the blog list and resume job entries
- **Drop cap** (Fraunces italic, rust) on the first paragraph of blog posts
- **Quick-link pills** (border + radius) on the home page and presentation links

## Deployment

The site is deployed via GitHub Pages. The `CNAME` file maps to www.kyleboon.org. The `github-pages` gem pins compatible dependency versions.
