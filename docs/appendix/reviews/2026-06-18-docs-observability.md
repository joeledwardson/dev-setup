# Docs review — reference/observability (2026-06-18)

Single-page review (Pass 1 project-structure skipped). Page: `docs/reference/observability.md`.

## Visual (Pass 2)

The standard full-page screenshot → Gemini-vision step **could not run**: headless `chromium` times out on this box (exit 124, zero-byte output) regardless of flags — a browser/environment problem, not a page problem. Substituted the pass's actual intent by rendering every diagram and viewing the images directly:

- **RENDERS — OK.** All **11** mermaid diagrams parse and render via `mmdc` (0 failures). All 16 screenshots + the CPU SVG are valid images and serve `200` through mkdocs.
- **LEGIBLE — OK.** Spot-checked the new tool diagrams (Prometheus+Grafana, Healthchecks, SigNoz) and the SVG; labels readable, HTML entities (`<uuid>`) render correctly.
- **COLOUR — USED.** Consistent palette across all diagrams (blue = source, green = tool, purple = the liveness/dead-man concept, grey = the swappable notify leaf). `notify` is correctly grey "any channel/receiver", not a hard-coded ntfy hub.
- **Not verified:** literal top-to-bottom mkdocs page layout / density as a single rendered image (blocked by the chromium issue). Every individual element was verified instead.

## Content (Pass 3 + 4)

- **WHAT_WHY — PRESENT.** Opens with what it is + why.
- **DOES_NOT — PRESENT.** Scope boundary stated (alert delivery is a swappable leaf, not covered in depth).
- **ACRONYMS — FLAG → fixed.** Several used before expansion (IOPS, SaaS, TSDB, PromQL, APL, OTel/OTLP, APM, ML, WAL). Added a collapsible "Acronyms & jargon" glossary near the top.
- **ASSUMED — FLAG → fixed.** Terms used as known (`node_exporter`, `cAdvisor`, `journald`, `Alertmanager`, `Shoutrrr`, PocketBase/ClickHouse/SQLite) — now covered in the same glossary.
- **SIMPLER — FLAG → no change (persona-driven).** The reviewer (junior, no domain) flagged the NixOS recipe as assuming NixOS/systemd knowledge. The page's actual audience is a NixOS user; the block is explicitly framed "(shape)" and is appropriate. Left as-is.
- **Links (Pass 4a) — all 200.** The 5 source posts + tool URLs resolve. One apparent `404` (`ntfy.sh/your-topic`) is an intentional placeholder inside a code example, not a doc link — no action.

**Outcome:** acronym/assumed flags fixed via glossary; visual verified element-by-element (chromium full-page shot unavailable on this host). No factual/link issues.
