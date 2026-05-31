# ADR-001 — Claude Code external orchestration options

**Status**: Proposed  
**Date**: 2026-05-31  
**Context**: The current setup uses Claude Code skills (claude-master, review-code, review-docs) invoked manually. The goal is a closed loop: spec → implement → review → fix, driven externally with minimal human input per cycle.  
**Decision**: Not yet made — this document captures the options.

---

## The loop we're trying to build

```mermaid
flowchart LR
    S["📄 Spec"] --> I["⚙️ Implement"]
    I --> R["🔍 Review\n(code + docs)"]
    R -->|flags| F["🔧 Fix"]
    F --> R
    R -->|clean| D["✅ Done / PR"]

    style S fill:#85c1e9,color:#1a252f,stroke:#2471a3
    style I fill:#52be80,color:#145a32,stroke:#196f3d
    style R fill:#c39bd3,color:#4a235a,stroke:#7d3c98
    style F fill:#f0b27a,color:#784212,stroke:#e67e22
    style D fill:#52be80,color:#145a32,stroke:#196f3d
```

The question is: what drives the arrows between those boxes?

---

## Options

### Option A — Claude drives itself (path of least resistance)

Tell Claude Code in YOLO mode to run the full loop: implement, then `/review-code`, then act on the output, then re-review. No external tooling.

```mermaid
flowchart TD
    H["Human: 'implement spec.md\nthen review and fix until clean'"]
    C["Claude Code (YOLO)"]
    A["Agent tool → child Claude\n(/review-code)"]
    H --> C
    C -->|spawns| A
    A -->|flags| C
    C -->|fixes + re-runs| A

    style H fill:#85c1e9,color:#1a252f,stroke:#2471a3
    style C fill:#52be80,color:#145a32,stroke:#196f3d
    style A fill:#c39bd3,color:#4a235a,stroke:#7d3c98
```

**In practice:**
```
/implement spec.md then run /review-code and fix all flags, repeat until clean
```

Claude uses the built-in `Agent` tool to spawn a reviewer subagent, reads the output, and loops. Already possible with the current setup.

| | |
|---|---|
| **Cost** | Claude API tokens only — no extra infra |
| **Maturity** | Works today via claude-master + YOLO |
| **Limit** | Context window is the loop budget; no parallelism; Claude decides when "clean" |

---

### Option B — Shell script + Claude Code headless (`claude -p`)

Claude Code's `--print` / `-p` flag runs non-interactively. Chain invocations in bash — the output of one becomes the input of the next.

```mermaid
flowchart LR
    SC["shell script"]
    C1["claude -p\n'implement spec'"]
    C2["claude -p\n'review: $(git diff)'"]
    C3["claude -p\n'fix: $(review output)'"]
    SC --> C1 --> C2 --> C3
    C3 -->|"exit 0 = clean"| PR["git push / PR"]
    C3 -->|"exit 1 = flags"| C2

    style SC fill:#85c1e9,color:#1a252f,stroke:#2471a3
    style C1 fill:#52be80,color:#145a32,stroke:#196f3d
    style C2 fill:#c39bd3,color:#4a235a,stroke:#7d3c98
    style C3 fill:#f0b27a,color:#784212,stroke:#e67e22
    style PR fill:#52be80,color:#145a32,stroke:#196f3d
```

**In practice:**
```bash
claude -p "read spec.md and implement" --allowedTools Edit,Write,Bash
REVIEW=$(claude -p "review git diff, output flags as JSON" --print)
while echo "$REVIEW" | grep -q '"flags"'; do
  claude -p "fix these: $REVIEW" --allowedTools Edit
  REVIEW=$(claude -p "re-review git diff" --print)
done
```

| | |
|---|---|
| **Cost** | API tokens; can be tight-looped cheaply with Haiku for review pass |
| **Maturity** | `claude -p` is stable; scripting is DIY |
| **Limit** | No persistent memory between invocations; diff context can get large |

---

### Option C — GitHub Actions (CI-driven loop)

Trigger Claude Code on PR events. Review runs automatically; comments posted back; Claude auto-pushes fixes to the branch.

```mermaid
flowchart TD
    PR["PR opened / pushed"]
    GHA["GitHub Actions\nworkflow"]
    CC["claude -p 'review PR #N'\n--allowedTools GH"]
    COM["gh pr comment\n(flags posted)"]
    FIX["claude -p 'fix comments\non PR #N'"]
    PUSH["git push to branch"]

    PR --> GHA --> CC --> COM
    COM -->|auto-trigger| FIX --> PUSH --> PR

    style PR fill:#85c1e9,color:#1a252f,stroke:#2471a3
    style GHA fill:#717d7e,color:#fff,stroke:#5d6d7e
    style CC fill:#52be80,color:#145a32,stroke:#196f3d
    style COM fill:#c39bd3,color:#4a235a,stroke:#7d3c98
    style FIX fill:#f0b27a,color:#784212,stroke:#e67e22
    style PUSH fill:#52be80,color:#145a32,stroke:#196f3d
```

**In practice:** This is essentially what Anthropic's own [claude-code-action](https://github.com/anthropics/claude-code-action) does — a GHA that runs Claude Code headlessly against a PR. Already production-hardened.

| | |
|---|---|
| **Cost** | GHA minutes (free for public repos) + API tokens |
| **Maturity** | `claude-code-action` is official and actively maintained |
| **Limit** | Async (minutes per loop turn); needs repo write perms; loop depth limited by GHA timeouts |

---

### Option D — Aider

Aider is a battle-tested CLI AI pair-programmer. Supports Claude natively. Has `--yes-always` for fully unattended runs and `--auto-commits`. 

```mermaid
flowchart LR
    SPEC["spec.md"]
    A["aider --model claude-sonnet\n--yes-always\n--message 'implement spec.md'"]
    REPO["git commits\n(auto)"]
    REVIEW["aider --message\n'review and fix'"]

    SPEC --> A --> REPO --> REVIEW

    style SPEC fill:#85c1e9,color:#1a252f,stroke:#2471a3
    style A fill:#52be80,color:#145a32,stroke:#196f3d
    style REPO fill:#717d7e,color:#fff,stroke:#5d6d7e
    style REVIEW fill:#c39bd3,color:#4a235a,stroke:#7d3c98
```

**In practice:**
```bash
aider --model claude-sonnet-4-5 --yes-always \
  --message "implement everything in spec.md" \
  src/

aider --model claude-sonnet-4-5 --yes-always \
  --message "review your last changes, fix any issues" \
  src/
```

| | |
|---|---|
| **Cost** | API tokens; Aider itself is free/OSS |
| **Maturity** | Very mature — 3+ years, active community, battle-tested on real codebases |
| **Limit** | Less flexible than Claude Code for complex tool use; no built-in review loop |

---

### Option E — OpenHands (formerly OpenDevin)

Open-source software development agent with a web UI, sandboxed Docker execution, and multi-agent support. Self-hostable.

```mermaid
flowchart TD
    UI["Web UI / API call"]
    OH["OpenHands runtime\n(Docker sandbox)"]
    LLM["Claude API"]
    FS["filesystem ops\n(isolated)"]
    GH["GitHub API\n(PRs, issues)"]

    UI --> OH
    OH <-->|"tool calls"| LLM
    OH --> FS
    OH --> GH

    style UI fill:#85c1e9,color:#1a252f,stroke:#2471a3
    style OH fill:#52be80,color:#145a32,stroke:#196f3d
    style LLM fill:#c39bd3,color:#4a235a,stroke:#7d3c98
    style FS fill:#717d7e,color:#fff,stroke:#5d6d7e
    style GH fill:#717d7e,color:#fff,stroke:#5d6d7e
```

**In practice:** Point it at a GitHub issue, it clones the repo, implements a fix, opens a PR. All automated.

| | |
|---|---|
| **Cost** | Self-host free; managed cloud ~$25/task rough estimate |
| **Maturity** | Actively developed; production-usable but occasionally flaky on complex tasks |
| **Limit** | Heavy infra (Docker required); overkill for single-repo use |

---

### Option F — LangGraph / AutoGen

Frameworks for building stateful multi-agent graphs. You define nodes (agents, tools, conditions) and edges (transitions). Full control over the loop logic.

```mermaid
flowchart LR
    SPEC["spec node"]
    IMPL["implementer\nagent"]
    REV["reviewer\nagent"]
    COND{{"flags?"}}
    FIX["fixer\nagent"]
    DONE["done"]

    SPEC --> IMPL --> REV --> COND
    COND -->|yes| FIX --> REV
    COND -->|no| DONE

    style SPEC fill:#85c1e9,color:#1a252f,stroke:#2471a3
    style IMPL fill:#52be80,color:#145a32,stroke:#196f3d
    style REV fill:#c39bd3,color:#4a235a,stroke:#7d3c98
    style COND fill:#f0b27a,color:#784212,stroke:#e67e22
    style FIX fill:#f0b27a,color:#784212,stroke:#e67e22
    style DONE fill:#52be80,color:#145a32,stroke:#196f3d
```

| | |
|---|---|
| **Cost** | API tokens + your dev time to build the graph |
| **Maturity** | LangGraph: mature, production-ready. AutoGen: solid but Microsoft-opinionated |
| **Limit** | Significant upfront build cost; you're writing the orchestration from scratch |

---

## Comparison

| Option | Effort to set up | Loop control | Cost | Best for |
|--------|-----------------|--------------|------|----------|
| **A — Claude self-drives** | None (works today) | Claude decides | API tokens | One-shot tasks, experimenting |
| **B — Shell script** | Low (bash) | Explicit, cheap | API tokens | Repeatable pipelines you control |
| **C — GitHub Actions** | Low (`claude-code-action`) | PR-event-driven | GHA + tokens | Team workflows, PR review |
| **D — Aider** | Low (install + config) | CLI flags | API tokens | Unattended implementation runs |
| **E — OpenHands** | High (Docker, infra) | Full | Cloud/self-host | Complex multi-step tasks with isolation |
| **F — LangGraph/AutoGen** | High (framework code) | Full | API tokens | Custom multi-agent products |

---

## Recommendation

**Start with A** — Claude already does this when asked correctly in YOLO mode. Zero setup cost, uses the review-code and review-docs skills already built.

**Graduate to B or C** once the loop needs to run without a human present (overnight jobs, CI gates). The `claude-code-action` makes C near-zero-effort for PR workflows.

**Only reach for E or F** if you need isolation, parallelism across many repos, or are building a product on top of it.

!!! warning "Does NOT cover"
    Model fine-tuning, RAG pipelines, or evaluation frameworks — those are separate concerns.
