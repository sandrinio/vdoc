---
name: vdoc-config
description: "Query existing project documentation. Use when user asks questions about the codebase and vdocs/ exists. For generating docs use /vdoc-init, for auditing use /vdoc-audit."
---

# vdoc — Documentation Query

Answer questions about the codebase using existing documentation in `vdocs/`.

## Other Commands

- **`/vdoc-init`** — Generate documentation from source code (explore → plan → generate)
- **`/vdoc-audit`** — Audit docs for stale, missing, or dead entries

## How to Answer Questions

1. Read `vdocs/_manifest.json`
2. Match the question against `description` and `tags` fields
3. Read matching doc(s) from `vdocs/`
4. Answer from documented knowledge
5. If no match or no `vdocs/` folder, suggest running `/vdoc-init`
6. If docs seem outdated, suggest running `/vdoc-audit`

## Rules

- Only answer from what's documented — do not hallucinate
- Reference specific doc filenames in your answers
- If the question spans multiple docs, read all relevant ones
