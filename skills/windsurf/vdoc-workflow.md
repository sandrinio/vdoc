# /vdoc — Documentation Generator

Run documentation workflows for this project.

## Steps

### Step 1: Determine Mode

Check if `vdocs/_manifest.json` exists:
- **No manifest** → run Init mode
- **Manifest exists** → run Audit mode

The user may also specify: `/vdoc init` or `/vdoc audit`.

### Step 2a: Init Mode

Read and follow the workflow at `.windsurf/skills/vdoc/resources/init-workflow.md`. Use `.windsurf/skills/vdoc/resources/doc-template.md` as the doc template and `.windsurf/skills/vdoc/resources/manifest-schema.json` for the manifest format.

### Step 2b: Audit Mode

Read and follow the workflow at `.windsurf/skills/vdoc/resources/audit-workflow.md`.
