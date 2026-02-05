# EPIC-006: Advanced Features (SPLIT)

## Status: Superseded

> **This epic has been split into two focused epics for better clarity and reduced ambiguity.**

---

## Successor Epics

| Epic | Name | Focus | Stories |
|------|------|-------|---------|
| [EPIC-006A](../EPIC-006A-large-codebase-support/EPIC.md) | Large Codebase Support | Performance, monorepo, concurrency | STORY-050 to STORY-056 |
| [EPIC-006B](../EPIC-006B-quality-metrics/EPIC.md) | Documentation Quality Metrics | Scoring, reporting, observability | STORY-060 to STORY-062 |

---

## Why Split?

The original EPIC-006 bundled **two distinct themes** with different:
- User personas (Developer vs Engineering Manager)
- Technical domains (scanning vs reporting)
- Release independence (can ship separately)

Splitting reduced ambiguity from 🔴 High to 🟢 Low for all stories.

---

## Story Migration

| Original | New Location | New ID |
|----------|--------------|--------|
| STORY-050 (git diff scanning) | EPIC-006A | STORY-051 |
| STORY-051 (last_commit tracking) | EPIC-006A | STORY-050 |
| STORY-052 (vdoc.config.json) | EPIC-006A | STORY-053 |
| STORY-053 (multi-language presets) | EPIC-006A | STORY-054 |
| STORY-054 (.vdoc.lock) | EPIC-006A | STORY-055 |
| STORY-055 (stale lock cleanup) | EPIC-006A | STORY-056 |
| STORY-056 (dependency tracking) | Deferred | — |
| STORY-057 (quality scoring) | EPIC-006B | STORY-060 |
| STORY-058 (quality command) | EPIC-006B | STORY-061 |

**Note:** Dependency tracking (STORY-056) was deferred as it requires further scoping.

---

## Archive Note

This file is kept for historical reference. All active work should use EPIC-006A or EPIC-006B.
