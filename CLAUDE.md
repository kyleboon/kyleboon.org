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

- **Layouts:** Two layouts in `_layouts/` — `home.html` (no nav, used for index) and `page.html` (includes nav header with Home, About, Blog, Presentations, Resume links)
- **Includes:** `_includes/head.html` and `_includes/footer.html` are shared partials
- **Posts:** Markdown files in `_posts/` using `YYYY-MM-DD-slug.md` naming convention with `layout: page` front matter
- **Top-level pages:** `index.html`, `aboutme.html`, `blog.html`, `books.html`, `presentations.html`, `resume.md` — these are standalone pages, not in `_posts/`
- **CSS:** Single stylesheet at `assets/css/main.css`
- **Scripts:** `scripts/fetch_covers.sh` downloads book cover images from Google Books API into `assets/images/books/`

## Post Front Matter

Posts use this front matter format:
```yaml
---
layout: page
title: Post Title
date: YYYY-MM-DD
---
```

## Deployment

The site is deployed via GitHub Pages. The `CNAME` file maps to www.kyleboon.org. The `github-pages` gem pins compatible dependency versions.
