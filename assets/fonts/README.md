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
