# ADR-008 — Docs engine: MDX frameworks vs mkdocs-material

**Status:** **Accepted** — adopt **Rspress** as the MDX docs engine going forward; retain **mkdocs-material** for existing projects (backwards-compatible, not worth porting). Two skills route by config file.

**Date:** 2026-06-25

**Context:**

Existing docs (this repo included) run on **mkdocs-material** (Python, plain Markdown, GitHub Pages). The goal: gain **MDX** — Markdown plus JSX, so docs can render interactive React components inline — without a forced migration of every existing project. MDX requires a JavaScript static-site generator, so this is a choice of *engine going forward*, not a rip-and-replace.

**Decision:**

**Adopt Rspress as the MDX docs engine.** New docs (or any project that wants interactive components) use **Rspress**; existing mkdocs sites stay on mkdocs — there's no value in porting them, and both coexist happily. Which engine a given repo uses is detected from its config files, and the two Claude skills route accordingly:

- `mkdocs.yml` present → **`documentation`** skill (mkdocs-material).
- `rspress.config.*` present → **`mdx-documentation`** skill (Rspress).
- New/greenfield docs → pick Rspress for MDX, mkdocs for plain Markdown (ask the user if unspecified).

Of the MDX frameworks, Rspress was the clear pick: it's the only one that keeps a good authoring loop (see below). Astro Starlight and Docusaurus were both rejected.

## What we did (concise)

1. Built a full **Astro Starlight** spike — ported all 33 pages, Mermaid, a real React component (`mdx-site/`, parked on the `mdx` branch).
2. Hit a string of friction (below), the worst being **no search in the dev server**.
3. Ran head-to-head spikes of **Rspress** and **Docusaurus**, porting the same real pages, scored on the axis that actually matters for an authoring workflow: *does search work while you edit?*
4. Concluded: Rspress is the best MDX engine (adopt it); mkdocs stays the no-fuss option for plain docs and all existing projects.

## The four-way comparison

| | **mkdocs-material** | **Rspress** | **Astro Starlight** | **Docusaurus** |
|---|---|---|---|---|
| Engine | Python | React / Rust (Rsbuild) | Astro | React / webpack |
| Search **in `dev`** | ✅ built-in | ✅ live FlexSearch | ❌ build-only (Pagefind) | ❌ build-only |
| Mermaid | ✅ native, server-side | 🟡 community plugin | 🟡 community plugin | ✅ first-party, lockstep |
| Internal `.md` links | ✅ resolve | ✅ resolve | ❌ 404 (need rewrite) | ❌ 404 (need rewrite) |
| Interactive components | ❌ (vanilla JS only) | ✅ MDX/React | ✅ MDX/React | ✅ MDX/React |
| Weight | 🟢 1 Python pkg | 🟡 ~210 npm pkgs | 🟡 version-coupled | 🔴 ~3,400 pkgs / 1.2 GB |
| GitHub Pages | ✅ | ✅ (`base`) | ✅ | ✅ |

**The deciding axis was dev-time search.** mkdocs `serve` gives live-reload *and* search in one command. Of the MDX engines, **only Rspress** matches that; Starlight and Docusaurus only build the search index at `build` time, so the edit loop has no search. For docs you edit constantly, that's a real regression — and it ruled out both Starlight and Docusaurus.

## Custom code / maintenance each engine required

This is the honest cost — what we had to write/configure to get each working on our content:

| Engine | Custom code & config we had to add |
|---|---|
| **mkdocs-material** | Essentially nothing — one `extra_css` line to widen the content column. Mermaid, search, admonitions, collapsibles, `.md` links, deep TOC all native. |
| **Rspress** | A one-off migration script (admonitions `!!!`/`???` → `:::` 5 types + **blank line before closing `:::`**, content-tabs flattened, `.md` link strip, derived `title` frontmatter so the sidebar reads cleanly); images moved to `docs/public/` with absolute paths; `_nav.json` for top nav. Mermaid = one community-plugin line. No custom CSS needed (default theme is good). Its strict **dead-link checker caught a real pre-existing broken link** in our source docs that mkdocs had silently allowed. |
| **Astro Starlight** | `.md`→route link-rewriter script (which itself then needed a fix to stop mangling *external* `.md` links); ~50 lines of `custom.css` (fonts, inline-code size, collapsible styling, toning down the over-bright active-sidebar highlight); config for Mermaid + React + `customCss` + TOC depth + sidebar; a migration script for admonitions/titles. Plus a version-pinning dance (see below). |
| **Docusaurus** | The heaviest: 1.2 GB `node_modules`, ~88 s cold build. `future.v4: true` (scaffold default) **breaks `## Heading {#id}`** — had to disable it; dead `<a id>` anchors converted to `{#id}`; admonitions → `:::`; a local-search plugin that *still* only indexes at build time; `prism.additionalLanguages` for nix/bash; `baseUrl` handling. Most config, heaviest footprint — and it doesn't even fix dev-search. |

## The Mermaid story — *not* a deciding factor (correcting the earlier draft)

An earlier version of this ADR treated Mermaid as a Starlight dealbreaker. That was wrong. What actually happened: Astro 7's new markdown processor ("satteri") briefly ignored rehype plugins, breaking the `astro-mermaid` plugin, and a client-side workaround was written. But **`astro-mermaid` 2.1.0 fixed satteri compatibility upstream**, so on the current latest stack Mermaid works with no workaround. The episode is a good illustration of JS-ecosystem **version coupling** (a major bump broke a plugin; the ecosystem then self-healed) — but Mermaid itself was *not* a reason to reject any engine. The real reasons were **dev-time search** and **maintenance weight/coupling**.

## So what

**Rspress is adopted for MDX docs; mkdocs-material is retained for existing projects.** No big-bang migration — the two coexist and the right skill is chosen per-repo from its config files (`rspress.config.*` → `mdx-documentation`; `mkdocs.yml` → `documentation`). Reach for Rspress when you want interactive React components (it uniquely keeps live dev search among MDX engines, resolves `.md` links, and needs the least custom CSS); reach for mkdocs for plain Markdown and anything already on it (lowest friction, nothing to port). Do **not** use Starlight (no dev search, most CSS) or Docusaurus (heaviest, also no dev search). The `mdx-documentation` skill carries the validated Rspress setup and the one-off migration transform.
