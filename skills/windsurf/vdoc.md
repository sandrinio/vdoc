---
trigger: model_decision
description: "Generate and maintain feature-centric product documentation. Modes: init (explore, plan, generate docs), audit (detect stale/missing/dead docs, patch), query (route questions via manifest). Activates on 'document this project', 'audit docs', or documentation questions."
---

# vdoc — Documentation Generator

Three modes: **init**, **audit**, **query**. All docs live in `vdocs/`. Manifest at `vdocs/_manifest.json` is the semantic index.

## Init ("document this project")

1. **Explore** — Read codebase: tech stack, features, architecture, integrations, entry points. Read actual files, don't skim.
2. **Plan** — Create `vdocs/_DOCUMENTATION_PLAN.md` listing proposed docs. Present to user, suggest changes. Wait for approval.
3. **Generate** — For each doc, read ALL relevant source files. Write `vdocs/FEATURE_NAME_DOC.md` using template below.
4. **Manifest** — Create `vdocs/_manifest.json` (schema below).
5. **Self-review** — Verify: mermaid diagrams present, real file paths, actual env vars, 2+ constraints per doc, cross-references exist.

## Audit ("audit docs")

1. Read `vdocs/_manifest.json`
2. **Stale**: git diff since `last_updated`, cross-ref with each doc's "Key Files" section
3. **Gaps**: find significant undocumented source files (routes, services, models)
4. **Dead**: docs referencing deleted source files
5. **Cross-refs**: verify Related Features links still valid
6. **Report** to user, wait for direction, then patch/create/remove as approved
7. Update manifest versions and timestamps

## Query (any documentation question)

Read manifest → match `description`/`tags` → read matching doc → answer. If no match, suggest audit.

## Doc Template

```markdown
# {Feature Title}
> {One-line description}

## Overview
{What it does, why it exists, system fit.}

## How It Works
{Core flow. Mermaid diagram(s) — max 7-9 nodes, split if larger.}

## Data Model
{Entities and relationships. Mermaid ER or table.}

## Key Files
| File | Purpose |
|------|---------|

## Dependencies & Integrations
{External services, internal features, packages.}

## Configuration
| Variable | Purpose | Required |
|----------|---------|----------|

## Error Handling
{Failure modes, user impact, retry logic. Mermaid if non-trivial.}

## Constraints & Decisions
{Why built this way. What CANNOT change without breaking things.}

## Related Features
{Cross-refs to other doc filenames. Blast radius.}
```

## Manifest Schema

```json
{
  "project": "<name>",
  "vdoc_version": "3.0.0",
  "created_at": "<ISO-8601>",
  "last_updated": "<ISO-8601>",
  "last_commit": "<sha>",
  "documentation": [{
    "filepath": "FEATURE_NAME_DOC.md",
    "title": "Title",
    "version": "1.0.0",
    "description": "Rich semantic description for AI routing.",
    "tags": ["keyword-tag"]
  }]
}
```

## Rules

- **Feature-centric**: one doc per feature, not per file
- **Mermaid mandatory**: diagram flows, max 7-9 nodes
- **Constraints are gold**: always fill, prevents breaking changes
- **Rich descriptions**: manifest descriptions are semantic search indexes
- **No hallucination**: only document what exists in code
- **Plan first**: never generate without user approval
