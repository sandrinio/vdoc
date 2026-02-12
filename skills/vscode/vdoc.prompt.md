---
agent: 'agent'
description: 'Generate and maintain feature-centric product documentation'
name: 'vdoc'
argument-hint: '[init|audit]'
tools: ['changes', 'codebase', 'githubRepo', 'problems']
---

# vdoc — Documentation Generator

Run documentation workflows for this project. Full instructions are in `.github/instructions/vdoc.instructions.md`.

**Mode: ${input:mode:init}**

## If mode is `init` (or no `vdocs/` folder exists):

1. **Explore** — Read the codebase: tech stack, features, architecture, integrations, entry points. Use #tool:codebase to search broadly. Read actual files.
2. **Plan** — Create `vdocs/_DOCUMENTATION_PLAN.md` listing proposed docs. Present to user. Wait for approval.
3. **Generate** — For each doc, read ALL relevant source files. Write `vdocs/FEATURE_NAME_DOC.md` following the template in `.github/instructions/vdoc.instructions.md`.
4. **Manifest** — Create `vdocs/_manifest.json` with rich semantic descriptions.
5. **Verify** — Every doc has mermaid diagrams, real paths, 2+ constraints, cross-references.

## If mode is `audit` (or `vdocs/` already exists):

1. Read `vdocs/_manifest.json`
2. **Stale** — Use #tool:changes to find modified source files. Cross-ref with each doc's "Key Files" section.
3. **Gaps** — Find undocumented features (new routes, services, models)
4. **Dead** — Docs referencing deleted files
5. **Cross-refs** — Verify Related Features links still valid
6. **Report** — Present findings, wait for user direction
7. **Patch** — Update stale docs, generate gaps, fix cross-refs, update manifest
