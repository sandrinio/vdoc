---
name: vdoc
description: "Use when user says /vdoc, 'document this project', 'audit docs', or asks questions about existing project documentation, stale docs, undocumented features, or documentation coverage gaps"
---

# vdoc — Documentation Generator

## Overview

Documentation must be feature-centric, plan-approved, and grounded in source code. Never generate docs from assumptions.

## When to Use
- User says `/vdoc`, "document this project", "audit docs", or asks about documentation
- Docs are stale, missing, or out of sync with code (documentation drift, undocumented features, coverage gaps)
- After significant feature work that changed codebase behavior

## When NOT to Use
- API reference docs (use JSDoc/TSDoc)
- README files or contribution guides
- Inline code comments

---

Three modes: **init**, **audit**, **query**. All docs live in `vdocs/`. Manifest at `vdocs/_manifest.json` is the semantic index.

## Init (`/vdoc init`)

Read the detailed workflow at `resources/init-workflow.md`.

Summary: Explore codebase → Plan docs → User approves → Generate using template → Build manifest → Self-review.

## Audit (`/vdoc audit`)

Read the detailed workflow at `resources/audit-workflow.md`.

Summary: Read manifest → Detect stale/gaps/dead docs → Check cross-refs → Report → Patch with approval.

## Query (any documentation question)

1. Read `vdocs/_manifest.json`
2. Match question against `description` and `tags` fields
3. Read matching doc(s)
4. Answer from documented knowledge
5. If no match, suggest running an audit

## Rules

1. **Feature-centric, not file-centric.** One doc per logical feature, not per source file.
2. **Mermaid over prose.** Diagram flows. Max 7-9 nodes per diagram.
3. **Constraints are gold.** Always fill "Constraints & Decisions".
4. **Rich manifest descriptions.** Pack with specific terms for semantic routing.
5. **No hallucination.** Only document what exists in code.
6. **Plan first, always.** Never generate without user-approved plan.

## Common Mistakes
- **File-centric instead of feature-centric** — Don't create one doc per source file. Group by logical feature.
- **Documenting aspirations** — Only document what the code actually does today, not planned work.
- **Skipping the plan** — Generating without user approval leads to rework and coverage gaps.
- **Oversized diagrams** — Keep Mermaid to 7-9 nodes; split if larger.
- **Shallow constraints** — "Constraints & Decisions" is the most valuable section. Dig for non-obvious choices.

## Red Flags — STOP
- Generating docs without an approved plan
- Documenting something you haven't verified in source code
- Creating one doc per file instead of per feature
- Skipping Mermaid diagrams in "How It Works"
- Writing manifest descriptions too vague for semantic routing
