# /vdoc — Documentation Generator

Run documentation workflows for this project.

## Determine Mode

Check if `vdocs/_manifest.json` exists:
- **No manifest** → run Init mode
- **Manifest exists** → run Audit mode

## Init Mode

Read and follow the workflow at `.clinerules/vdoc/init-workflow.md`. Use `.clinerules/vdoc/doc-template.md` as the doc template and `.clinerules/vdoc/manifest-schema.json` for the manifest format.

## Audit Mode

Read and follow the workflow at `.clinerules/vdoc/audit-workflow.md`.
