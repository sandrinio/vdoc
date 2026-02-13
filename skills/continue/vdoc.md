---
name: vdoc
description: "Use when user says /vdoc, 'document this project', 'audit docs', or asks about existing project documentation, stale docs, undocumented features, or documentation coverage gaps"
alwaysApply: false
globs:
---

# vdoc — Documentation Generator

Three modes: **init**, **audit**, **query**. All docs live in `vdocs/`. Manifest at `vdocs/_manifest.json` is the semantic index.

## Init (`/vdoc init`)

Read the detailed workflow at `.continue/references/vdoc/init-workflow.md`.

Summary: Explore codebase → Plan docs → User approves → Generate using template → Build manifest → Self-review.

## Audit (`/vdoc audit`)

Read the detailed workflow at `.continue/references/vdoc/audit-workflow.md`.

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
