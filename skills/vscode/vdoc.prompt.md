---
agent: 'agent'
description: 'Use when user says /vdoc, document this project, audit docs, or asks about existing project documentation'
name: 'vdoc'
argument-hint: '[init|audit]'
tools: ['search/changes', 'search/codebase', 'web/githubRepo', 'read/problems']
---

# vdoc — Documentation Generator

Run documentation workflows for this project.

**Mode: ${input:mode:init}**

## If mode is `init` (or no `vdocs/` folder exists):

Read and follow the workflow at `.github/skills/vdoc/references/init-workflow.md`. Use `.github/skills/vdoc/references/doc-template.md` as the doc template and `.github/skills/vdoc/references/manifest-schema.json` for the manifest format.

## If mode is `audit` (or `vdocs/` already exists):

Read and follow the workflow at `.github/skills/vdoc/references/audit-workflow.md`.
