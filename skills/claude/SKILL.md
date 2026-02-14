---
name: vdoc
description: "Generate and maintain feature-centric documentation from source code. Use when user says 'document this project', 'generate docs', 'create a doc for [feature]', 'update docs', 'audit docs', 'sync docs', or asks about documentation coverage and freshness."
---

# vdoc — Documentation Generator

Four modes: **init**, **create**, **update**, **audit**, plus **query** for any documentation question. All docs live in `vdocs/`. Manifest at `vdocs/_manifest.json` is the semantic index.

Do NOT create scripts, shell files, scanners, or any tooling — use your built-in tools (Read, Glob, Grep) for everything.

## Init

Read the detailed workflow at [init-workflow.md](./references/init-workflow.md).

Summary: Explore codebase → Write exploration log → Plan docs → User approves → Generate one-at-a-time using [doc template](./references/doc-template.md) → Build manifest per [schema](./references/manifest-schema.json) → Self-review.

## Create

Read the detailed workflow at [create-workflow.md](./references/create-workflow.md).

Summary: Locate feature in codebase → Generate one doc using [doc template](./references/doc-template.md) → Update manifest per [schema](./references/manifest-schema.json) → Self-review.

## Update / Audit

Read the detailed workflow at [audit-workflow.md](./references/audit-workflow.md).

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
7. **No scripts.** Do NOT create shell scripts, scanners, or build tools.
