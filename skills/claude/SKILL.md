---
name: vdoc
description: "Use when user says /vdoc, 'document this project', 'audit docs', or asks questions about codebase documentation. Generates feature-centric docs in vdocs/ with semantic manifest for AI routing."
argument-hint: "[init|audit] or ask any documentation question"
user-invocable: true
allowed-tools: ["Bash", "Read", "Write", "Edit", "Glob", "Grep"]
---

# vdoc — Documentation Generator

Three modes: **init**, **audit**, **query**. All docs live in `vdocs/`. Manifest at `vdocs/_manifest.json` is the semantic index.

## Init (`/vdoc init`)

Generate feature-centric documentation from source code.

**Workflow:** Explore → Plan → Generate → Manifest → Self-review

For detailed steps, read [references/init-workflow.md](references/init-workflow.md).

**Key rules:**
- Follow the template in [references/doc-template.md](references/doc-template.md) exactly
- Manifest schema in [references/manifest-schema.json](references/manifest-schema.json)
- Never generate without user-approved plan
- Mermaid diagrams mandatory (max 7-9 nodes)
- Only document what exists in code

## Audit (`/vdoc audit`)

Detect stale, missing, and dead documentation. Report and patch.

**Workflow:** Read manifest → Detect stale → Detect gaps → Detect dead → Check cross-refs → Report → Patch

For detailed steps, read [references/audit-workflow.md](references/audit-workflow.md).

## Query (any documentation question)

1. Read `vdocs/_manifest.json`
2. Match question against `description` and `tags` fields
3. Read matching doc(s)
4. Answer from documented knowledge
5. If no match, suggest running `/vdoc audit`

## Naming Convention

Files: `FEATURE_NAME_DOC.md` — uppercase, feature-named, `_DOC` suffix.

## Rules

1. **Feature-centric, not file-centric.** One doc per logical feature, not per source file.
2. **Mermaid over prose.** Diagram flows. Max 7-9 nodes per diagram.
3. **Constraints are gold.** Always fill "Constraints & Decisions" — prevents breaking changes.
4. **Rich manifest descriptions.** Pack with specific terms for semantic routing.
5. **No hallucination.** Only document what exists in code.
6. **Plan first, always.** Never generate without user-approved plan. Report before patching.
