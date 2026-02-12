# /vdoc — Documentation Generator

Run documentation workflows for this project. The detailed instructions are in `.cursor/rules/vdoc.mdc`.

## Usage

- `/vdoc init` — Explore codebase, create documentation plan, generate docs
- `/vdoc audit` — Detect stale, missing, and dead docs, then patch
- `/vdoc` (no args) — Show available commands

## Execution

$ARGUMENTS

**If the argument is `init` or empty with no existing `vdocs/` folder:**

1. **Explore** — Read the codebase thoroughly: tech stack, features, architecture, integrations, entry points. Read actual files, don't skim.
2. **Plan** — Create `vdocs/_DOCUMENTATION_PLAN.md` listing each proposed doc. Present to user. Wait for approval.
3. **Generate** — For each approved doc, read ALL relevant source files. Write `vdocs/FEATURE_NAME_DOC.md` following the template and writing rules in `.cursor/rules/vdoc.mdc`.
4. **Manifest** — Create `vdocs/_manifest.json` with rich semantic descriptions per doc.
5. **Self-review** — Verify: mermaid diagrams, real file paths, 2+ constraints per doc, cross-references, no hallucinated content.

**If the argument is `audit` or empty with existing `vdocs/` folder:**

1. **Read** `vdocs/_manifest.json`
2. **Stale** — git diff since `last_updated`, cross-ref with `source_files`
3. **Gaps** — find undocumented features (new routes, services, models)
4. **Dead** — docs referencing deleted source files
5. **Cross-refs** — verify Related Features links still valid
6. **Report** — present findings, wait for user direction
7. **Patch** — update stale docs, generate new ones for gaps, fix cross-refs, update manifest

**If no arguments and `vdocs/` exists, treat as audit.**
