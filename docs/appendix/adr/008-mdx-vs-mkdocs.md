# ADR-008 — Docs engine: MDX frameworks vs mkdocs-material

**Status:** Rejected for general docs — mkdocs-material retained. **Rspress** designated as the MDX engine if interactive components are ever needed (not Astro Starlight, not Docusaurus).

**Date:** 2026-06-25

**Context:**

The docs site runs on **mkdocs-material** (Python, plain Markdown, deployed to GitHub Pages). The question: is it worth moving to **MDX** — Markdown plus JSX, so you can render interactive components inline — which means replacing mkdocs with a JavaScript static-site generator?

The only thing MDX buys over mkdocs is **interactive React components**; everything else is equal-or-worse. We evaluated it on *real content*, not in the abstract.

**Decision**: **Stay on mkdocs-material.** If interactive components are ever genuinely needed, use **Rspress** — of the MDX frameworks it was the only one that keeps a good authoring loop. Astro Starlight and Docusaurus are both dominated by Rspress for our priorities.

## What we did (concise)

1. Built a full **Astro Starlight** spike — ported all 33 pages, Mermaid, a real React component (`mdx-site/`, parked on the `mdx` branch).
2. Hit a string of friction (below), the worst being **no search in the dev server**.
3. Ran head-to-head spikes of **Rspress** and **Docusaurus**, porting the same real pages, scored on the axis that actually matters for an authoring workflow: *does search work while you edit?*
4. Concluded mkdocs already wins for plain docs; Rspress is the best MDX option if components are wanted.

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

Stay on mkdocs-material — it wins on friction for plain docs on every axis except interactive components: one install, live dev search, native link resolution and Mermaid, deep TOC, near-zero version coupling. **If** a concrete interactive-component need ever appears, reach for **Rspress** (it uniquely keeps live dev search, resolves `.md` links, and needed the least custom CSS) — and see the `mdx-documentation` skill for the validated setup and the migration transform. Do not reach for Starlight (no dev search, most CSS) or Docusaurus (heaviest, also no dev search).
