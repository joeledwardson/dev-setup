# ADR-001 — Reducing user prompts: autonomous spec-to-PR loop

**Status**: Proposed  
**Date**: 2026-05-31  
**Context**: The current workflow requires a human to prompt each step: implement, then manually invoke `/review-code`, read the output, prompt Claude to fix, re-review. The goal is to reduce that to one trigger — "implement spec.md" — and have Claude handle the rest without further prompting.  
**Decision**: Not yet made — this document captures the options.

---

## The problem

Today's flow requires a human at each arrow:

```mermaid
flowchart LR
    H1["👤 'implement this'"] --> I["⚙️ implement"]
    I --> H2["👤 '/review-code'"]
    H2 --> R["🔍 review"]
    R --> H3["👤 'fix these flags'"]
    H3 --> F["🔧 fix"]
    F --> H4["👤 '/review-code'"]
    H4 --> R

    style H1 fill:#85c1e9,color:#1a252f,stroke:#2471a3
    style H2 fill:#85c1e9,color:#1a252f,stroke:#2471a3
    style H3 fill:#85c1e9,color:#1a252f,stroke:#2471a3
    style H4 fill:#85c1e9,color:#1a252f,stroke:#2471a3
    style I fill:#52be80,color:#145a32,stroke:#196f3d
    style R fill:#c39bd3,color:#4a235a,stroke:#7d3c98
    style F fill:#f0b27a,color:#784212,stroke:#e67e22
```

The goal: one prompt from the user, Claude drives all the arrows.

---

## Options

### Option A — Claude self-drives (zero tooling)

Tell YOLO-mode Claude to run the full loop in a single prompt. Claude uses the built-in `Agent` tool to spawn reviewer subagents and acts on their output.

```mermaid
flowchart TD
    H["👤 one prompt:\n'implement spec.md,\nthen /review-code and fix\nuntil clean'"]
    C["Claude (YOLO)"]
    SUB["Agent tool →\nchild reviewer"]
    
    H --> C
    C -->|spawns| SUB
    SUB -->|flags| C
    C -->|fixes| C
    C -->|re-spawns| SUB
    SUB -->|clean| DONE["✅ done"]

    style H fill:#85c1e9,color:#1a252f,stroke:#2471a3
    style C fill:#52be80,color:#145a32,stroke:#196f3d
    style SUB fill:#c39bd3,color:#4a235a,stroke:#7d3c98
    style DONE fill:#52be80,color:#145a32,stroke:#196f3d
```

**In practice:** Just tell it.

```
implement everything in spec.md, then run /review-code,
fix all flags, and repeat until /review-code comes back clean
```

| | |
|---|---|
| **Effort** | None — works today |
| **Loop control** | Claude decides when "clean" — usually correct |
| **Weak point** | Context window is the loop budget; Claude may drift or hallucinate "clean" after many turns |

---

### Option B — A `/run-spec` skill

A dedicated skill that encodes the loop explicitly: read spec → implement → review → fix → review. User types one slash command.

```mermaid
flowchart LR
    H["👤 /run-spec spec.md"]
    SK["run-spec skill\n(reads loop from SKILL.md)"]
    I["implement\n(Agent child)"]
    R["review\n(Agent child)"]
    FX["fix\n(Agent child)"]

    H --> SK --> I --> R
    R -->|flags| FX --> R
    R -->|clean| DONE["✅ PR"]

    style H fill:#85c1e9,color:#1a252f,stroke:#2471a3
    style SK fill:#52be80,color:#145a32,stroke:#196f3d
    style I fill:#52be80,color:#145a32,stroke:#196f3d
    style R fill:#c39bd3,color:#4a235a,stroke:#7d3c98
    style FX fill:#f0b27a,color:#784212,stroke:#e67e22
    style DONE fill:#52be80,color:#145a32,stroke:#196f3d
```

**In practice:** Write `configs/claude/skills/run-spec/SKILL.md` with explicit step-by-step instructions. The skill controls the loop — no ambiguity about when to stop.

| | |
|---|---|
| **Effort** | Write one SKILL.md (~1 hour) |
| **Loop control** | Explicit — skill defines the exit condition |
| **Weak point** | Still one Claude process; context window still the limit |

---

### Option C — Aider (`--yes-always`)

Aider is a CLI AI pair-programmer. With `--yes-always` it runs completely unattended. User fires one command and walks away.

```mermaid
flowchart LR
    H["👤 one shell command"]
    A["aider\n--yes-always\n--model claude-sonnet"]
    COMMITS["auto git commits\nafter each change"]
    H --> A --> COMMITS

    style H fill:#85c1e9,color:#1a252f,stroke:#2471a3
    style A fill:#52be80,color:#145a32,stroke:#196f3d
    style COMMITS fill:#717d7e,color:#fff,stroke:#5d6d7e
```

**In practice:**
```bash
aider --model claude-sonnet-4-6 --yes-always \
  --message "implement spec.md, then review and fix until clean" \
  src/
```

| | |
|---|---|
| **Effort** | `pip install aider-chat` + config |
| **Loop control** | Single-shot — Aider doesn't natively loop review→fix; needs prompting in the message |
| **Weak point** | Less capable than Claude Code for complex tool use; no awareness of existing skills |

---

### Option D — `claude --print` pipeline (headless chaining)

Claude Code's `-p` / `--print` flag runs non-interactively. Pipe the output of one call into the next — review output becomes fix input.

```mermaid
flowchart LR
    H["👤 runs script once"]
    S["shell script"]
    C1["claude -p\n'implement spec.md'"]
    C2["claude -p\n'review changes'"]
    C3["claude -p\n'fix: {review}'"]

    H --> S --> C1 --> C2
    C2 -->|flags| C3 --> C2
    C2 -->|clean| DONE["✅"]

    style H fill:#85c1e9,color:#1a252f,stroke:#2471a3
    style S fill:#717d7e,color:#fff,stroke:#5d6d7e
    style C1 fill:#52be80,color:#145a32,stroke:#196f3d
    style C2 fill:#c39bd3,color:#4a235a,stroke:#7d3c98
    style C3 fill:#f0b27a,color:#784212,stroke:#e67e22
    style DONE fill:#52be80,color:#145a32,stroke:#196f3d
```

**In practice:**
```bash
claude -p "implement spec.md" --allowedTools Edit,Write,Bash
REVIEW=$(claude -p "review git diff, output JSON flags" --print)
until [ "$(echo $REVIEW | jq '.flags | length')" = "0" ]; do
  claude -p "fix: $REVIEW" --allowedTools Edit
  REVIEW=$(claude -p "re-review" --print)
done
```

| | |
|---|---|
| **Effort** | Write one bash script |
| **Loop control** | Fully explicit — you control the exit condition |
| **Weak point** | Each invocation starts cold (no memory); diff context grows with each loop |

---

## Comparison

| Option | User effort per run | Loop intelligence | Setup cost | Context-aware |
|--------|---------------------|-------------------|------------|---------------|
| **A — Self-drive** | One prose prompt | Claude judges | None | Yes (single session) |
| **B — /run-spec skill** | `/run-spec spec.md` | Skill-defined rules | ~1 hour | Yes (single session) |
| **C — Aider** | One shell command | Single-pass only | 30 min | Partial |
| **D — Headless pipeline** | One shell command | Script-defined | 1–2 hours | No (cold starts) |

---

## Recommendation

**B is the right answer** — a `/run-spec` skill gives you Option A's convenience with explicit loop control, uses the review skills already built, and stays within Claude Code's context so it has full awareness of the codebase. One SKILL.md file, no new dependencies.

**A works right now** for one-offs and exploration. The prompt above is all you need.

**D is useful** if you want the loop to run unattended overnight (outside a terminal session), since each `claude -p` call is independent and the process survives.

!!! warning "Does NOT cover"
    CI automation (GitHub Actions, webhooks), multi-repo orchestration, or evaluation pipelines — those are a separate concern.
