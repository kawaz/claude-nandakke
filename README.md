# nandakke

> English | [日本語](./README-ja.md)

A Claude Code plugin that gives AI a "fuzzy-but-accurate whole-picture index"
of a project. Humans hold this kind of overview unconsciously — *not exact, but
enough to know where to look*. nandakke externalizes that index so the AI can
use it.

It replaces the all-or-nothing choice of "read everything (expensive) or skip
(sloppy)" with what humans actually do: skim the whole picture, then fetch the
exact part you need.

(The name *nandakke* is Japanese for "What was it again?" — the moment when
you know something exists but can't quite recall the details.)

## Status

Pre-implementation (per DR-0001, §YAGNI / phased rollout). This repository is
where the design is being worked out and built in stages.

- Design starting point: [docs/decisions/DR-0001-knowledge-index-sidecar-architecture.md](./docs/decisions/DR-0001-knowledge-index-sidecar-architecture.md)
- Phased rollout plan: [docs/ROADMAP.md](./docs/ROADMAP.md)

## Documents

- [DESIGN.md](./docs/DESIGN.md) — Domain + architecture
- [STRUCTURE.md](./docs/STRUCTURE.md) — Repository layout
- [ROADMAP.md](./docs/ROADMAP.md) — Phased rollout progress
- [decisions/INDEX.md](./docs/decisions/INDEX.md) — Design decisions (DR) index

## License

MIT License, Yoshiaki Kawazu (@kawaz)
