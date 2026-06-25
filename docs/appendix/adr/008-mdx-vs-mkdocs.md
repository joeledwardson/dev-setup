# ADR-008 — Docs engine: MDX (Astro Starlight) vs mkdocs-material

**Status**: Rejected for general docs — mkdocs-material retained; MDX parked as an escape hatch
**Date**: 2026-06-25
**Context**: The docs site runs on **mkdocs-material** (Python, plain Markdown, deployed to GitHub Pages). The question was whether to move to **MDX** — Markdown plus JSX, so you can render interactive components inline — which means replacing mkdocs entirely with a JavaScript static-site generator. We built a full working spike (`mdx-site/` on the `mdx` branch: all 33 pages ported, Mermaid, a real React component) to evaluate it on real content rather than in the abstract.

**Decision**: **Stay on mkdocs-material.** The only thing MDX buys over our setup is interactive React components; everything else is equal-or-worse, and the JS toolchain carries a real fragility tax. The `mdx-site/` spike is kept on a parked branch as the "when I genuinely need an interactive widget" option, not as the docs home.

## What MDX actually adds (the entire upside)

Interactive components inside docs — e.g. a filterable comparison table or a live calculator as a real React island. Plain Markdown can't do this. mkdocs can approximate it with hand-written vanilla JS, but not with first-class components. **If you don't want interactive components, there is no reason to migrate.**

## The fragility tax (what the spike actually cost)

Each of these was a real time sink, and none have an equivalent in mkdocs:

| Friction | What happened |
|---|---|
| **Version coupling** | Astro ↔ Starlight ↔ React adapter ↔ Mermaid plugin ↔ themes must all agree. Latest Starlight requires latest Astro; a theme (Ion) required a *different* Starlight; pinning one forces older everything else. |
| **Mermaid broke on a major version** | Astro 7's new markdown processor ("satteri") ignored rehype plugins, silently breaking `astro-mermaid`. Needed a hand-written client-side workaround… |
| **…then self-healed** | `astro-mermaid` 2.1.0 fixed satteri compatibility, so on the *current* latest it works again with no workaround. Honest nuance: the coupling is real, but the ecosystem does catch up. |
| **Config format churn** | The sidebar `autogenerate` syntax changed between Starlight 0.37 and 0.39 — the same config is valid, then invalid, then valid again across versions. |
| **`.md` links don't resolve** | mkdocs rewrites `[x](foo.md)` natively; Astro leaves it as a 404. Required a migration script to rewrite every internal link (which then needed a fix to stop mangling *external* `.md` links). |
| **Deep TOC hidden** | Right-side TOC defaults to H2–H3; deeply-nested pages (networking) silently lost their sub-section links until configured to H4. |
| **`astro preview` ignores `allowedHosts`** | Couldn't serve over the Tailscale hostname via `preview`; had to serve the static `dist/` with a plain server instead. |

## The dealbreaker for an authoring workflow: dev search

mkdocs-material's `mkdocs serve` gives **live-reload *and* working search simultaneously**, with one command. Starlight's search (Pagefind) is **build-time only**, so:

- `astro dev` — instant hot-reload, **no search**.
- `astro build` + `astro preview` — search works, **no hot-reload**.

There is no single command that gives both. Getting live edits + search would mean a watcher that runs a full `astro build` (~6–15s) on every save — a strictly worse loop. For docs you edit constantly, this is a genuine regression. (Algolia DocSearch doesn't fix it — it indexes the *deployed* site via a crawler, not local edits, and adds an external hosted dependency.)

## Themes / styling

Starlight's default theme is clean but deliberately plain. Community themes (Rapide, Flexoki, Ion, the shadcn-style Black) swap in via one plugin line and were compared side-by-side. The default + a few lines of `custom.css` (font, inline-code size, toned-down active-sidebar highlight) was preferred — and is the lowest-maintenance choice. Styling is genuinely extensible, which is a point in Starlight's favour *if* you want to invest in it.

## Maintenance reality (free vs. bespoke)

Most of the site comes free from Starlight (theme, nav, search, highlighting, routing) — you bump versions. The bespoke surface is small: ~85 lines (`custom.css` + config) plus optional React components. The one-time migration scripts are throwaway (see the `mdx-documentation` skill for the transform as pseudo-code — not worth maintaining as code). **The fragility is not code volume; it's version coupling and ecosystem churn.** mkdocs has almost none.

## So what

Stay on mkdocs-material. It wins on friction for this use case on every axis except interactive components: one `pip install`, live dev search, native link resolution, deep TOC, no version coupling. Revisit MDX only when a concrete interactive-component need appears — the parked `mdx-site/` branch (and the `mdx-documentation` skill) make that a fast on-ramp without re-deciding from scratch.
