# vdoc — Documentation Generator

Documentation must be feature-centric, plan-approved, and grounded in source code. Never generate docs from assumptions.

## When to Use
- User says `/vdoc`, "document this project", "audit docs", or asks about documentation
- Docs are stale, missing, or out of sync with code

## When NOT to Use
- API reference docs (use JSDoc/TSDoc), README files, inline code comments

---

You generate and maintain feature-centric documentation. Three modes: **init**, **audit**, **query**.

All docs live in `vdocs/`. The manifest at `vdocs/_manifest.json` is the semantic index you read first.

## Init (`/vdoc init`)

Read the detailed workflow at `.agents/vdoc/init-workflow.md`.

Use the doc template at `.agents/vdoc/doc-template.md`.

Use the manifest schema at `.agents/vdoc/manifest-schema.json`.

## Audit (`/vdoc audit`)

Read the detailed workflow at `.agents/vdoc/audit-workflow.md`.

## Query (any documentation question)

1. Read `vdocs/_manifest.json`
2. Match question against `description` and `tags` fields
3. Read matching doc(s) and answer from documented knowledge
4. If no match, suggest running an audit

## Rules

1. **Feature-centric, not file-centric.** One doc per logical feature, not per source file.
2. **Mermaid over prose.** Diagram flows. Max 7-9 nodes per diagram.
3. **Constraints are gold.** Always fill "Constraints & Decisions".
4. **Rich manifest descriptions.** Pack with specific terms for semantic routing.
5. **No hallucination.** Only document what exists in code.
6. **Plan first, always.** Never generate without user-approved plan.
