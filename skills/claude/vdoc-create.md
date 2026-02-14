---
name: vdoc-create
description: "Create a single feature doc on demand. Use when user says 'document the auth system', 'create a doc for payments', or wants to add one specific doc to vdocs/."
argument-hint: "<feature description>"
---

# vdoc create — Single Doc Generator

Create one feature doc based on the user's description. Do NOT create scripts, shell files, scanners, or any tooling — use your built-in tools (Read, Glob, Grep) for everything.

---

## Step 1 — Locate

Use the user's description to find the relevant source files:

1. If `.claude/skills/vdoc-config/_exploration_log.md` exists, read it first — it maps the codebase and may already have the feature signal you need
2. Otherwise, search the codebase with Glob and Grep to find files matching the user's description
3. Read ALL relevant source files — not just the main file, but helpers, types, middleware, tests, API routes, components

Do not skim. Understand how the feature actually works before writing.

## Step 2 — Generate

1. Read the template from `.claude/skills/vdoc-config/references/doc-template.md` and follow it exactly
2. Write to `vdocs/FEATURE_NAME_DOC.md`

### Writing Rules

- **Mermaid diagrams are mandatory** in "How It Works". Show the actual flow — request lifecycle, state transitions, data pipeline. If a flow has more than 7-9 nodes, split into multiple diagrams.
- **Data Model** must show real entities from the code, not generic placeholders. Use mermaid ER diagrams for relational data, tables for simpler models.
- **Constraints & Decisions** is the most valuable section. Dig into the code for non-obvious choices. If you can't find the reason, state the constraint and mark it: `Reason: unknown — verify with team`.
- **Related Features** must reference other docs by filename and explain the coupling.
- **Configuration** must list actual env vars/secrets from the code, not hypothetical ones.
- **Error Handling** — trace what happens when things fail. What does the user see? What gets logged? Is there retry logic?

## Step 3 — Update Manifest

Read `vdocs/_manifest.json` and add the new doc entry using the schema in `.claude/skills/vdoc-config/references/manifest-schema.json`.

If `vdocs/_manifest.json` doesn't exist, create it with the project name, version, and this doc as the first entry.

## Step 4 — Self-Review

Before finishing, verify:

- [ ] Doc has at least one mermaid diagram in "How It Works"
- [ ] Doc has at least 2 entries in "Constraints & Decisions"
- [ ] "Key Files" lists real paths that exist in the codebase
- [ ] "Configuration" lists actual env vars from the code
- [ ] "Related Features" references other doc filenames (if other docs exist)
- [ ] Manifest `description` is detailed enough for semantic routing
- [ ] Doc explains WHY and HOW, not just WHAT

## Rules

1. **Feature-centric, not file-centric.** The doc covers one logical feature, not one source file.
2. **No hallucination.** Only document what exists in code.
3. **No scripts.** Do NOT create shell scripts, scanners, or build tools. Use Read/Glob/Grep.
