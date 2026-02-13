# EPIC: Platform Skill Optimization

> Research each supported AI platform's skill/rule system, then restructure vdoc's skill files to follow that platform's best practices — just like we did for Claude Code.

## Context

We optimized the Claude Code skill by:
- Splitting a 213-line monolith SKILL.md into a 55-line lean router + 4 reference files
- Adding proper YAML frontmatter (`name`, `description`, `argument-hint`, `allowed-tools`)
- Using progressive disclosure — Claude only loads detailed workflow when a mode is invoked

Every other platform currently has monolith skill files that may not follow platform-specific best practices. Each platform has different discovery mechanisms, frontmatter formats, file organization conventions, and token/context constraints.

## Per-Platform Work

For each platform:
1. **Research** — How does the platform discover, load, and invoke rules/commands/skills? Frontmatter? Size limits? Progressive disclosure support? Official docs and community examples.
2. **Implement** — Restructure our skill files to match that platform's best practices. Update CLI mappings if file structure changes.
3. **Test** — Verify install/uninstall still works with new file structure.

---

### 1. Claude Code
- **Status:** DONE
- **Files:** `skills/claude/SKILL.md` + 4 reference files
- **What we did:** YAML frontmatter, lean router, progressive disclosure via reference files
- **Install target:** `.claude/skills/vdoc/`

---

### 2. Cursor
- **Status:** DONE
- **Files:** `skills/cursor/RULE.md` + 4 reference files + `skills/cursor/vdoc-command.md`
- **What we did:** Migrated from flat `.mdc` to modern folder format (`.cursor/rules/vdoc/RULE.md`). Agent-requested mode with clear description. Lean rule (~35 lines) routing to reference files. Command updated to reference new paths. Legacy `.mdc` cleanup in uninstall.
- **Install target:** `.cursor/rules/vdoc/`, `.cursor/commands/vdoc.md`

---

### 3. Windsurf
- **Status:** DONE
- **Files:** `skills/windsurf/SKILL.md` + 4 resource files + `skills/windsurf/vdoc-workflow.md`
- **What we did:** Migrated from rule+workflow to Windsurf Skills format (`.windsurf/skills/vdoc/SKILL.md`). Skills support progressive disclosure with bundled resources. Lean SKILL.md (~35 lines) routing to resource files. Workflow kept as thin `/vdoc` entry point. Legacy rule cleanup in uninstall.
- **Install target:** `.windsurf/skills/vdoc/`, `.windsurf/workflows/vdoc.md`

---

### 4. VS Code (Copilot)
- **Status:** DONE
- **Files:** `skills/vscode/SKILL.md` + 4 reference files + `skills/vscode/vdoc.instructions.md` + `skills/vscode/vdoc.prompt.md` + `skills/vscode/copilot-instructions.md`
- **What we did:** Added Agent Skills format (`.github/skills/vdoc/SKILL.md`) with 3-level progressive disclosure. Lean instructions file pointing to skill. Prompt file with proper tool references. Reference files for workflows/template/schema.
- **Install target:** `.github/skills/vdoc/`, `.github/instructions/`, `.github/prompts/`, `.github/copilot-instructions.md`

---

### 5. Continue
- **Status:** DONE
- **Files:** `skills/continue/vdoc.md` + `skills/continue/vdoc-command.md` + 4 reference files
- **What we did:** Lean rule (~35 lines) with `alwaysApply: false` frontmatter. Invokable prompt as thin entry point. Reference files at `.continue/references/vdoc/` for progressive disclosure.
- **Install target:** `.continue/rules/vdoc.md`, `.continue/prompts/vdoc-command.md`, `.continue/references/vdoc/`

---

### 6. Cline
- **Status:** DONE
- **Files:** `skills/cline/vdoc.md` + `skills/cline/vdoc-workflow.md` + 4 reference files
- **What we did:** Lean rule (~35 lines) with `globs: ["vdocs/**"]` frontmatter. Thin workflow referencing reference files. Reference files at `.clinerules/vdoc/` for progressive disclosure.
- **Install target:** `.clinerules/vdoc.md`, `.clinerules/workflows/vdoc.md`, `.clinerules/vdoc/`

---

### 7. Gemini CLI
- **Status:** DONE
- **Files:** `skills/gemini/GEMINI.md` + `skills/gemini/vdoc.toml` + 4 reference files
- **What we did:** Lean GEMINI.md (~48 lines) using Gemini's native `@file.md` import syntax for progressive disclosure. TOML command updated with `@` references. Reference files installed to `.gemini/vdoc/`.
- **Install target:** `GEMINI.md` (inject), `.gemini/commands/vdoc.toml`, `.gemini/vdoc/`

---

### 8. JetBrains AI
- **Status:** DONE
- **Files:** `skills/jetbrains-ai/vdoc.md` + 4 reference files
- **What we did:** Lean rule (~45 lines) instructing AI to read reference files at `.aiassistant/vdoc/`. No frontmatter (JetBrains uses UI-managed metadata). Reference files installed alongside rules.
- **Install target:** `.aiassistant/rules/vdoc.md`, `.aiassistant/vdoc/`

---

### 9. Junie
- **Status:** DONE
- **Files:** `skills/junie/guidelines.md` + 4 reference files
- **What we did:** Lean injected content (~48 lines) with instructions to read reference files at `.junie/vdoc/`. Junie has no native multi-file or import support, but the AI can read files when instructed.
- **Install target:** `.junie/guidelines.md` (inject), `.junie/vdoc/`

---

### 10. Universal (AGENTS.md)
- **Status:** DONE
- **Files:** `skills/agents/AGENTS.md` + 4 reference files
- **What we did:** Lean injected content (~45 lines) with instructions to read reference files at `.agents/vdoc/`. AGENTS.md standard supports hierarchical directory nesting for progressive disclosure.
- **Install target:** `AGENTS.md` (inject), `.agents/vdoc/`

---

## Tracking

| # | Platform | Research | Implement | Test |
|---|----------|----------|-----------|------|
| 1 | Claude Code | DONE | DONE | DONE |
| 2 | Cursor | DONE | DONE | DONE |
| 3 | Windsurf | DONE | DONE | DONE |
| 4 | VS Code (Copilot) | DONE | DONE | DONE |
| 5 | Continue | DONE | DONE | DONE |
| 6 | Cline | DONE | DONE | DONE |
| 7 | Gemini CLI | DONE | DONE | DONE |
| 8 | JetBrains AI | DONE | DONE | DONE |
| 9 | Junie | DONE | DONE | DONE |
| 10 | Universal (AGENTS.md) | DONE | DONE | DONE |
