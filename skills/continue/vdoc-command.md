---
name: vdoc
description: "Generate and maintain feature-centric product documentation"
invokable: true
---

# /vdoc — Documentation Generator

Run documentation workflows for this project. Full instructions are in `.continue/rules/vdoc.md`.

**Arguments:** $ARGUMENTS

## If `init` or no `vdocs/` folder exists:

1. **Explore** — Read the codebase: tech stack, features, architecture, integrations, entry points. Read actual files.
2. **Plan** — Create `vdocs/_DOCUMENTATION_PLAN.md` listing proposed docs. Present to user. Wait for approval.
3. **Generate** — For each doc, read ALL relevant source files. Write `vdocs/FEATURE_NAME_DOC.md` following the template in `.continue/rules/vdoc.md`.
4. **Manifest** — Create `vdocs/_manifest.json` with rich semantic descriptions.
5. **Verify** — Every doc has mermaid diagrams, real paths, 2+ constraints, cross-references.

## If `audit` or `vdocs/` already exists:

1. Read `vdocs/_manifest.json`
2. **Stale** — git diff since `last_updated`, cross-ref with each doc's "Key Files" section
3. **Gaps** — undocumented features (new routes, services, models)
4. **Dead** — docs referencing deleted files
5. **Cross-refs** — verify Related Features links
6. **Report** — present findings, wait for user direction
7. **Patch** — update stale, generate gaps, fix cross-refs, update manifest
