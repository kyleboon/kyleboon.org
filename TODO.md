# Site Improvements TODO

## Structure
- [x] Upgrade Jekyll version (switch to GitHub Actions deployment for Jekyll 4.x)
- [x] Remove or draft the empty blog post (`_posts/2025-06-04-software-engineering-best-reads.md`)
- [x] Add GitHub Actions CI workflow (run htmlproofer on PRs)
- [x] Enrich blog.html to show dates and descriptions like the homepage
- [x] Flesh out `_config.yml` (add `plugins`, `permalink`, `markdown`, `timezone` settings)

## Design / CSS
- [x] Fix mobile base font size (24px -> 18px)
- [x] Add `<meta name="theme-color">` tag for mobile browser chrome
- [x] Scope book hover effects to hover-capable devices with `@media (hover: hover)`

## Security
- [x] Add Content Security Policy meta tag in `head.html`
- [x] Consider adding AI crawler rules to `robots.txt` (GPTBot, CCBot, etc.)
- [x] Evaluate removing `keybase.txt` if no longer using Keybase (keeping it)

## Performance
- [x] Add `width` and `height` attributes to all `<img>` tags
- [x] Add `loading="lazy"` to below-the-fold images (book covers)
- [ ] Consider image optimization pipeline (WebP, compression)

## Accessibility
- [x] Add `lang="en"` to `<html>` in both layouts (already present)
- [x] Review and improve image `alt` text

## SEO
- [x] Add `<link rel="canonical">` URL tags in `head.html`
- [x] Make Open Graph tags dynamic per page (title, description, image)
- [x] Use dynamic copyright year in footer (`{{ site.time | date: '%Y' }}`)
