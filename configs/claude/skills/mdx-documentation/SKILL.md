---
name: mdx-documentation
description: Scaffolding, configuring and maintaining an MDX docs site. Use when a repo has an MDX docs project (a `rspress.config.*`, or an `mdx-site/` Astro project) or the user asks for MDX docs / interactive doc components. For plain-Markdown mkdocs sites use the `documentation` skill instead.
---

# mdx-documentation

**What**: How to stand up and maintain an MDX docs site, and the gotchas that bite.
**Why**: MDX buys exactly one thing over mkdocs — **interactive React components inline in docs**. Everything else is equal-or-worse. This skill captures the validated setup so you don't rediscover it. See ADR-008 for the full evaluation.

---

## First: which docs system is this repo using?

- **`rspress.config.ts/js`** → an existing Rspress (MDX) site. This skill.
- **`mkdocs.yml` at repo root** → plain-Markdown mkdocs-material. Use the `documentation` skill.
- A repo can have **both** (mkdocs published + an MDX experiment) — check which the deploy workflow targets before editing.

## Which skill — do NOT guess; the user decides

The choice between MDX and plain-Markdown docs is the **user's**, not something to infer from vibes:

- **User explicitly asked for MDX / interactive doc components / Rspress** → use this skill.
- **User explicitly asked for plain docs / mkdocs** → use the `documentation` skill.
- **A docs system already exists in the repo** → follow it (the markers above).
- **New docs, unspecified** → **ask the user** which they want: an **MDX site** (Rspress — interactive React components, JS toolchain) or **plain Markdown** (mkdocs-material — simpler, lighter). Don't default to one silently.

If MDX is chosen, use **Rspress** specifically. ADR-008 evaluated mkdocs / Rspress / Astro Starlight / Docusaurus on real content: among MDX engines only Rspress keeps **search in the dev server**, resolves `.md` links, and needs no custom CSS — so prefer it over Starlight (no dev search, most custom CSS) and Docusaurus (heaviest, also no dev search). Surface ADR-008's trade-offs if the user wants them, but let them pick.

---

## Scaffold Rspress

```sh
npx -y create-rspress@latest --dir <dir> --template basic --override   # non-interactive
cd <dir> && npm install
npm install rspress-plugin-mermaid                                       # only if docs use ```mermaid
```
Scripts: `rspress dev` / `rspress build` (output **`doc_build/`**) / `rspress preview`. Requires Node 20.19+/22.12+.

## Minimal `rspress.config.ts`

```ts
import * as path from 'node:path';
import { defineConfig } from '@rspress/core';
import pluginMermaid from 'rspress-plugin-mermaid'; // default export, not named

export default defineConfig({
  root: path.join(__dirname, 'docs'),
  title: 'My Docs',
  // base: '/<repo>/',          // GH Pages project-page knob (prefixes all asset URLs)
  search: { codeBlocks: true }, // index code-block text too
  plugins: [pluginMermaid()],
  themeConfig: {
    socialLinks: [{ icon: 'github', mode: 'link', content: 'https://github.com/<user>/<repo>' }],
  },
});
```
Sidebar **auto-generates** from the file tree (label = frontmatter `title` → first H1 → filename). Top nav = `docs/_nav.json`. Per-dir order/labels = `docs/<dir>/_meta.json` (optional). Files/dirs starting with `_` are excluded from routes.

## Interactive component (the reason to use MDX at all)

A React component in a `.tsx`, imported into an `.mdx` page:
```mdx
import Foo from '../../components/Foo';
<Foo />
```

---

## Migrating mkdocs `.md` content (one-off — do NOT maintain custom JS for this)

A throwaway transform; vibe-code a script applying these rules per `.md`, then delete it. Do not keep porting infrastructure around.

```
for each docs/**/*.md:
  - add frontmatter { title }: derive from filename overrides / first "# H1" / filename.
      ADRs & reviews: SHORT title from filename, e.g. "001-foo-bar.md" -> "ADR-001 — Foo Bar".
      (Rspress's auto-title grabs code/snippet text for pages without a clean H1 — set title explicitly.)
  - admonitions -> Rspress container directives (only 5 types: tip/info/warning/danger/details):
      !!! tip "T" / !!! warning "T" / !!! danger "T"   -> :::tip T / :::warning T / :::danger T ... :::
      !!! note|abstract|info|... "T"                    -> :::info T ... :::   (map extras to info)
      ??? type "T"  (collapsible)                       -> :::details T ... :::
      *** ALWAYS put a blank line before the closing ::: *** — a container whose body ends in a
      list leaks a literal ":::" without it. (Real bug; cost debugging time.)
  - content tabs  === "Label"  -> flatten to a **Label** subsection (de-indent body).
  - internal links: ](foo.md) / ](foo.md#x) -> ](foo) / ](foo#x)   (strip .md; index -> dir; skip http(s)).
      Rspress RESOLVES these (unlike Astro, which 404s). It also has a strict dead-link checker that
      will fail the build on a bad internal link — fix the link (often a real pre-existing bug).
  - images: copy assets into docs/public/ and reference with ABSOLUTE /paths (Rspress serves public/ at site root).
  - footnotes [^x], GFM tables, fenced code (Shiki): no changes needed. Drop manual <a id> anchors (auto slugs).
```

---

## Gotchas (each cost real time)

- **Sidebar labels need `title` frontmatter** for any page without a clean first H1, or Rspress shows code/snippet text.
- **Blank line before closing `:::`** when a container's body ends in a list (else `:::` leaks as text).
- **Images live in `docs/public/`**, referenced with absolute `/…` paths — not relative.
- **Mermaid is a community plugin** (`rspress-plugin-mermaid`, default export). Renders client-side, so static HTML has no `<svg>` — verify with a headless browser, not `curl`. (A scary `ERR_MODULE_NOT_FOUND` from its devkit dep under bare Node is a false alarm; Rspress's bundler resolves it.)
- **Dead-link checker is strict** — fails the build on bad internal links. This is a feature (catches real broken links mkdocs ignores); fix the link.
- **Leaf routes are `.html`** in the build. Rspress's own links include `.html`, so navigation works; but a dumb static server (e.g. busybox) won't rewrite extensionless `/page` → `/page.html`. Use `rspress preview` or expect `.html` URLs.

## Hosting on GitHub Pages

`doc_build/` is plain static HTML. For a project page set `base: '/<repo>/'` (prefixes all asset URLs), build, and push `doc_build/` via `actions/deploy-pages`. FlexSearch search ships in the build. A repo can publish only ONE site to Pages — if keeping mkdocs live too, deploy MDX to a different path/branch.

## Dev loop reality

`rspress dev` gives **live-reload AND working search** (live FlexSearch index) — the key reason Rspress beat Starlight/Docusaurus, which have no search in dev. So unlike those, the MDX edit loop here matches mkdocs.
