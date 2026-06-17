# nandakke Design

> English | [日本語](./DESIGN-ja.md)

Pre-implementation (per DR-0001, §YAGNI / phased rollout). This file currently
summarizes the design starting point (DR-0001) and will grow into a description
of the actual implementation as it lands.

## Domain

**Give the AI the kind of fuzzy-but-accurate whole-picture index that humans
hold unconsciously.**

A human (kawaz) remembers roughly *where* things were discussed, decided, and
built across each project — not exactly, but well enough to know "if I look, I
will find it." AI lacks this index. To grasp the whole, AI must read every doc
and every line of code; because that is expensive, it skips reading, and ends
up writing from imagination (which produces concrete bugs).

nandakke replaces the binary of "read everything (expensive) or skip
(sloppy)" with what humans actually do: skim the whole picture, then fetch the
exact part you need.

### Scope

- **In scope**: each project's project-knowledge (DR / findings / journal /
  docs) and the sessions (conversation, instructions, ideas, work) that
  produced it
- **Out of scope**: rule sets (the `for-all/for-me` of `claude-rules-personal`).
  Rules are norms; nandakke handles records. They must not be mixed.
- The widest cross-cutting scope is "project-knowledge across multiple
  projects."

See [DR-0001 §Scope Boundary](./decisions/DR-0001-knowledge-index-sidecar-architecture.md#スコープ境界).

## Architecture

```
Main session (long-lived; early context evaporates)
  │ Delta feed (CSA messageid-after — unverified)
  ▼
Tracking session (single continuous context; preserves flow;
  judges phase + branching)
  │ Writes settled phases out and lets go of them itself
  ▼
Central record layer (persistent, cross-searchable)
  ▲
  │ Lookup (pull, any time)
Main session ← skill or browser view
```

The three roles are facets of one core, "external index for AI":

- **Write**: continuously track conversation, instructions, ideas, work, and
  tool use; persist decisions, their phase, and branches to the central index.
- **Verify**: turn unverified rows (phase still inferred) into facts via
  side-effect-free checks (repo `ls` / `grep`). Heavier checks (asking another
  session) are gated by user approval.
- **Serve**: at session start, the AI reads the index alone to grasp the
  whole, then follows pointers to read only the parts it needs precisely.
  Answers "where am I right now?" queries too.

### The core is the index, not visualization

"Organic graphs," "timeline / idea-axis views," and "browser visualization"
are **non-core**. The core is a lightweight index for the AI to take a good
guess. Visualization is "nice to have," not the first thing to build (do not
get pulled toward Understand-Anything-style rich visuals).

### Index Schema (6 columns)

| column | meaning |
|---|---|
| topic | subject of the decision or discussion |
| phase | spoken / recorded / implemented |
| confidence | fact (machine-checked) / inferred (tracking session's judgement) |
| last seen | last time it was touched (messageid / timestamp in the impl) |
| ref | pointer (session URI etc.) — never duplicate content |
| next | next phase to advance to, or how to verify (e.g. `[check] ls docs/issue/`) |

The `confidence` column is mandatory. Mixing inferred and fact-checked rows
turns the map into a lie. A phase is only flipped when a fact arrives.

## Key design decisions

- [DR-0001: Architecture of the project-knowledge index sidecar](./decisions/DR-0001-knowledge-index-sidecar-architecture.md)

## Related docs

- [STRUCTURE.md](./STRUCTURE.md) — physical layout
- [ROADMAP.md](./ROADMAP.md) — phased rollout
- [decisions/INDEX.md](./decisions/INDEX.md) — DR index
