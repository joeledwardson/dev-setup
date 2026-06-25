---
name: mdx-documentation
description: Scaffolding, configuring and maintaining an MDX docs site (Astro Starlight). Use when a repo has an `mdx-site/` (or the user asks for MDX docs / interactive doc components). For plain-Markdown mkdocs sites use the `documentation` skill instead.
---

# mdx-documentation

**What**: How to stand up and maintain an Astro Starlight (MDX) docs site, and the gotchas that bite.
**Why**: MDX docs buy you one real thing over mkdocs — **interactive React components inline in docs**. Everything else is equal-or-worse, and the JS toolchain has real version-coupling fragility. This skill captures the working setup so you don't rediscover it.

---

## First: which docs system is this repo using?

- **`mkdocs.yml` at repo root** → plain-Markdown mkdocs-material site. Use the `documentation` skill.
- **`mdx-site/` directory (an Astro project: `astro.config.mjs` + `src/content/docs/`)** → this skill.
- A repo can have **both** (e.g. mkdocs as the published site, `mdx-site/` as an experiment). Check which one the deploy workflow targets before editing.

---

## Decision guide (be honest with the user)

**Default to mkdocs.** It's lower-friction for almost every docs need: one `pip install`, live-reload **with** search in dev, native `.md` link resolution, deep TOC, admonitions/tabs/collapsibles built in, no version coupling.

**Reach for MDX/Starlight only when you want interactive React components** (live calculators, filterable tables, embedded widgets). That is the entire upside. If the user doesn't need components, recommend staying on / moving to mkdocs.

Known trade-offs to state up front:
- **No search in `astro dev`** (Pagefind is build-time only). Search works in `astro build` + `preview` and when deployed — but the fast edit loop has none. mkdocs has live dev search.
- **Version coupling**: Astro ↔ Starlight ↔ plugins ↔ themes must agree; releases break things (and sometimes self-heal — see Mermaid below). Pin versions if a release breaks you.

---

## Scaffold (latest works as of mid-2026)

```sh
npm create astro@latest mdx-site -- --template starlight --install --no-git --skip-houston --yes
cd mdx-site
npx astro add react --yes          # only if you want React component islands
npm install astro-mermaid mermaid  # only if docs use ```mermaid diagrams
```

`@astrojs/starlight` bundles `@astrojs/mdx`, so `.mdx` files work without adding it. If a future release breaks something, the last known-good Astro-5 line is `astro@^5.5 + @astrojs/starlight@0.37 + @astrojs/react@^4`.

## Minimal `astro.config.mjs`

```js
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import react from '@astrojs/react';
import mermaid from 'astro-mermaid';

export default defineConfig({
  // For GitHub project Pages: site = your pages origin, base = /<repo>
  // site: 'https://<user>.github.io', base: '/<repo>',
  server: { host: true, port: 9043 },                 // bind all interfaces for remote access
  vite: { server: { allowedHosts: ['<your-host>'] } },// dev only; `astro preview` ignores this (see gotchas)
  integrations: [
    mermaid({ theme: 'default', autoTheme: true }),    // must precede starlight
    starlight({
      title: 'My Docs',
      customCss: ['./src/styles/custom.css'],
      tableOfContents: { minHeadingLevel: 2, maxHeadingLevel: 4 }, // include H4 (mkdocs showed deep TOC)
      sidebar: [
        // NOTE: Starlight 0.39+ requires autogenerate NESTED in items.
        { label: 'Reference', items: [{ autogenerate: { directory: 'reference' } }] },
        // Starlight <=0.37 instead wanted: { label: 'Reference', autogenerate: { directory: 'reference' } }
      ],
    }),
    react(),
  ],
});
```

## Minimal `src/styles/custom.css` (glanceable, no magic)

```css
:root {
  --sl-font: 'Inter', ui-sans-serif, system-ui, sans-serif;
  --sl-font-mono: 'JetBrains Mono', ui-monospace, monospace;
}
/* Starlight renders inline code oversized — size it down */
.sl-markdown-content :not(pre) > code { font-size: 0.875em; padding: 0.1em 0.35em; }
/* Tone down the bright accent-filled active sidebar item */
a[aria-current='page'], a[aria-current='page']:hover, a[aria-current='page']:focus {
  color: var(--sl-color-text-accent); background-color: var(--sl-color-gray-6);
}
/* Collapsible blocks migrated from mkdocs ??? admonitions (<details>) */
.sl-markdown-content details {
  border: 1px solid var(--sl-color-gray-5); border-radius: 0.5rem;
  background: var(--sl-color-gray-6); padding: 0.4rem 1rem; margin: 1rem 0;
}
.sl-markdown-content details > summary { cursor: pointer; font-weight: 600; }
```

## Interactive component (the reason to use MDX at all)

A React island in `src/components/Foo.tsx`, used in an `.mdx` page:
```mdx
import Foo from '../../components/Foo';
<Foo client:load />
```
Style islands with Starlight's CSS vars (`--sl-color-*`) so they theme correctly.

---

## Migrating existing mkdocs `.md` content (one-off — do NOT maintain custom JS for this)

This is a one-time transform. Vibe-code a throwaway script (or do it by hand) applying these rules per `.md` file, then delete the script. Do not keep porting infrastructure around.

```
for each docs/**/*.md:
  - strip frontmatter down to { title }; Starlight rejects unknown keys (created/updated/etc.)
  - derive title: frontmatter.title  ->  first "# H1" (and strip that H1)  ->  filename
      (ADRs/reviews: prefer a SHORT title from the filename, e.g. "001-foo-bar.md" -> "ADR-001 — Foo Bar")
  - mkdocs admonitions:
      !!! type "Title"      ->  :::type[Title] ... :::        (de-indent the 4-space body)
      ??? type "Title"      ->  <details><summary>Title</summary> ... </details>   (collapsible)
      ???+ ...              ->  <details open> ...
  - content tabs:  === "Label"  ->  flatten to a **Label** subsection (Starlight Tabs need MDX, not worth it for a bulk port)
  - internal links:  ](foo.md) / ](foo.md#frag)  ->  ](foo/) / ](foo/#frag)
      * index.md -> the directory; SKIP links starting with http(s):// (don't rewrite external .md links)
  - copy image assets alongside; reference relative paths with a leading ./
  - leave ```mermaid fences as-is (astro-mermaid handles them)
  - KEEP files as .md unless a page embeds a component. Blanket .md->.mdx breaks on bare < and { in prose.
```

---

## Gotchas (each cost real time — read before debugging)

- **Search only in builds.** Pagefind indexes built HTML. `astro dev` has no search; use `astro build && astro preview` (or serve `dist/`) to test it. Deployed sites always have it.
- **Mermaid + Astro version.** `astro-mermaid` works via a rehype plugin. Astro 7's default markdown processor ("satteri") briefly ignored rehype plugins (broke it); `astro-mermaid` ≥2.1.0 fixed it. If Mermaid renders as a raw code block, check the plugin/Astro versions before hacking — verify the built HTML has `class="mermaid"` (good) vs `data-language="mermaid"` (broken).
- **Sidebar config format flipped.** ≤0.37 wants group-level `autogenerate`; 0.39+ wants it nested in `items`. The error message tells you which.
- **`.md` links don't auto-resolve.** Unlike mkdocs, Astro leaves `href="foo.md"` as-is → 404. The migration rewrite handles it; if authoring natively, write Starlight routes (`/section/page/`).
- **Deep TOC hidden by default.** Right-side TOC is H2–H3; set `tableOfContents.maxHeadingLevel: 4` to match mkdocs.
- **`astro preview` ignores `allowedHosts`.** For remote review over a hostname, serve the static `dist/` with any plain static server instead (it has no host check) — search still works.

## Hosting on GitHub Pages

Astro builds static `dist/` → deploys exactly like mkdocs. Set `site` + `base` (above), then use the official `withastro/action` → `actions/deploy-pages` in a workflow (replaces `mkdocs gh-deploy`). Pagefind search ships in the build, so deployed search works. A repo can only publish ONE site to Pages — if keeping mkdocs live too, deploy MDX to a different path/branch.

## Dev loop reality

- `astro dev` — instant hot-reload, **no search**. Use for writing.
- `astro build && astro preview` — search + exact production output, **no hot-reload**. Use to verify before deploy.
- There is no single command that gives both (mkdocs `serve` does — a genuine point in mkdocs's favour).
