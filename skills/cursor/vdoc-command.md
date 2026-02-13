# /vdoc — Documentation Generator

Run documentation workflows for this project.

## Usage

- `/vdoc init` — Explore codebase, create documentation plan, generate docs
- `/vdoc audit` — Detect stale, missing, and dead docs, then patch
- `/vdoc` (no args) — Show available commands

## Execution

$ARGUMENTS

**If the argument is `init` or empty with no existing `vdocs/` folder:**

Read and follow the workflow at `.cursor/rules/vdoc/references/init-workflow.md`. Use `.cursor/rules/vdoc/references/doc-template.md` as the doc template and `.cursor/rules/vdoc/references/manifest-schema.json` for the manifest format.

**If the argument is `audit` or empty with existing `vdocs/` folder:**

Read and follow the workflow at `.cursor/rules/vdoc/references/audit-workflow.md`.

**If no arguments and `vdocs/` exists, treat as audit.**
