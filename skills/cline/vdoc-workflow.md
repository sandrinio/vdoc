# /vdoc — Documentation Generator

Run documentation workflows for this project. Full instructions are in `.clinerules/vdoc.md`.

## Determine Mode

Check if `vdocs/_manifest.json` exists:
- **No manifest** → run Init mode
- **Manifest exists** → run Audit mode

## Init Mode

1. **Explore** — Read the codebase: tech stack, features, architecture, integrations, entry points. Use `read_file` and `list_files` to explore thoroughly.
2. **Plan** — Create `vdocs/_DOCUMENTATION_PLAN.md` listing proposed docs. Present to user via `ask_followup_question`. Wait for approval.
3. **Generate** — For each doc, read ALL relevant source files. Write `vdocs/FEATURE_NAME_DOC.md` using `write_to_file`, following the template in `.clinerules/vdoc.md`.
4. **Manifest** — Create `vdocs/_manifest.json` with rich semantic descriptions.
5. **Verify** — Every doc has mermaid diagrams, real paths, 2+ constraints, cross-references.

## Audit Mode

1. Read `vdocs/_manifest.json`
2. **Stale** — Run `execute_command` with `git log --name-only --since="<last_updated>"`. Cross-ref with each doc's "Key Files" section.
3. **Gaps** — Find undocumented features (new routes, services, models)
4. **Dead** — Docs referencing deleted files
5. **Cross-refs** — Verify Related Features links still valid
6. **Report** — Present findings via `ask_followup_question`, wait for user direction
7. **Patch** — Update stale docs, generate gaps, fix cross-refs, update manifest
