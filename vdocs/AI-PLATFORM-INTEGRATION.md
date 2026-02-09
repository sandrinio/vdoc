# AI Platform Integration Guide

How vdoc integrates with popular AI coding assistants.

---

## Overview

| Platform | Rules File | Skills/Commands | Location |
|----------|-----------|-----------------|----------|
| Claude Code | `CLAUDE.md` | `.claude/commands/*.md` | Project root + `.claude/` |
| Cursor | `.cursorrules` | - | Project root |
| Windsurf | `.windsurfrules` | - | Project root |
| VS Code + Copilot | `.github/copilot-instructions.md` | - | `.github/` |
| VS Code + Continue | `.continuerules` | `.continue/prompts/*.md` | `.continue/` |
| VS Code + Cline | `.clinerules` | - | Project root |
| Aider | `.aider/conventions.md` | - | `.aider/` |
| Gemini (Antigravity) | `GEMINI.md` | Custom actions | Project root |
| JetBrains AI | `.idea/ai-instructions.md` | - | `.idea/` |

---

## Claude Code

### Rules: `CLAUDE.md`

Located at project root. Contains project-specific instructions that Claude reads automatically.

```markdown
# Project Instructions

## Architecture
- This is a Next.js 14 app with App Router
- Uses Supabase for database
- TypeScript strict mode

## Conventions
- Use server components by default
- All API routes in src/app/api/
- Use zod for validation
```

### Skills: `.claude/commands/*.md`

Custom slash commands that users invoke with `/command-name`.

**Location:** `.claude/commands/`

**Structure:**
```
.claude/
├── commands/
│   ├── vdoc.md           # /vdoc command
│   ├── test.md           # /test command
│   └── deploy.md         # /deploy command
└── settings.json
```

**Skill File Format:**
```markdown
---
name: vdoc
description: Generate documentation for this project
---

# vdoc Skill

## Instructions
1. Analyze the codebase to identify documentable features
2. Create documentation in vdocs/ directory
3. Register each doc using the register script

## Steps
...
```

### Integration Points
- **Rules:** Always-on context about project
- **Skills:** User-triggered workflows

---

## Cursor

### Rules: `.cursorrules`

Single file at project root. Cursor reads this automatically for every interaction.

```markdown
You are an expert in TypeScript, Next.js, and Supabase.

Key Principles:
- Write concise, type-safe code
- Use functional patterns
- Prefer server components

Project Structure:
- src/app/ - Next.js app router pages
- src/components/ - React components
- src/lib/ - Utility functions
```

### Skills
Cursor does not have a native skills/commands system. Workflows are embedded in `.cursorrules` or invoked via natural language.

**Workaround:** Include workflow instructions in `.cursorrules`:
```markdown
## Available Workflows

When user says "generate docs":
1. Analyze codebase structure
2. Create documentation files
3. Update manifest
```

---

## Windsurf

### Rules: `.windsurfrules`

Similar to Cursor. Single file at project root.

```markdown
# Windsurf Rules

## Project Context
- Framework: Next.js 14
- Language: TypeScript
- Database: PostgreSQL via Supabase

## Coding Standards
- Use async/await, not callbacks
- Validate all inputs with zod
- Write tests for business logic
```

### Skills
Windsurf does not have a separate skills system. All instructions go in `.windsurfrules`.

---

## Aider

### Rules: `.aider/conventions.md`

Aider reads conventions from `.aider/` directory.

```markdown
# Coding Conventions

## Style
- 2 space indentation
- Single quotes for strings
- Trailing commas

## Architecture
- Keep components under 200 lines
- Extract hooks for reusable logic
- Use barrel exports (index.ts)
```

### Configuration: `.aider.conf.yml`

```yaml
model: claude-3-opus
auto-commits: true
conventions: .aider/conventions.md
```

### Skills
Aider uses natural language commands. No formal skill system.

**Workaround:** Create instruction files that user can reference:
```bash
aider --read .aider/workflows/generate-docs.md
```

---

## Continue (VS Code)

### Rules: `.continuerules`

Project-level instructions.

```markdown
# Continue Rules

Always use TypeScript strict mode.
Prefer functional components over class components.
Use server actions for form submissions.
```

### Skills: `.continue/prompts/*.md`

Custom prompts that appear in Continue's command palette.

**Location:** `.continue/prompts/`

**Structure:**
```
.continue/
├── config.json
└── prompts/
    ├── vdoc.md
    ├── refactor.md
    └── test.md
```

**Prompt File Format:**
```markdown
---
name: Generate Documentation
description: Create documentation for the current project
---

Analyze this codebase and create comprehensive documentation:

1. Identify all major features
2. Document API endpoints
3. Create architecture overview

Save documentation to ./vdocs/
```

---

## Gemini / Antigravity

### Rules: `GEMINI.md`

Similar to CLAUDE.md. Project-level instructions.

```markdown
# Gemini Instructions

## Project Overview
This is a SaaS application for project management.

## Tech Stack
- Frontend: Next.js 14, React 18, Tailwind
- Backend: Supabase, PostgreSQL
- Auth: NextAuth.js

## Guidelines
- Follow existing patterns
- Add types for all functions
- Include error handling
```

### Skills: Custom Actions

Gemini supports custom actions defined in configuration:

```json
{
  "actions": [
    {
      "name": "generate-docs",
      "description": "Generate project documentation",
      "steps": [
        "Analyze codebase",
        "Create feature docs",
        "Update manifest"
      ]
    }
  ]
}
```

---

## VS Code

VS Code supports multiple AI assistants via extensions. Each has its own configuration.

### AI Extensions for VS Code

| Extension | Rules File | Skills |
|-----------|-----------|--------|
| GitHub Copilot | `.github/copilot-instructions.md` | Built-in slash commands |
| Continue | `.continuerules` + `.continue/config.json` | `.continue/prompts/*.md` |
| Cline | `.clinerules` | Custom modes |
| Cody (Sourcegraph) | `.sourcegraph/cody.json` | - |
| Tabnine | `.tabnine/config.json` | - |

### Workspace Settings: `.vscode/settings.json`

VS Code workspace settings can configure AI behavior:

```json
{
  "github.copilot.enable": {
    "*": true,
    "markdown": true
  },
  "continue.enableTabAutocomplete": true,
  "cline.customInstructions": "Follow TypeScript best practices"
}
```

### Tasks: `.vscode/tasks.json`

Define runnable tasks that AI can reference:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "vdoc: Register Documentation",
      "type": "shell",
      "command": "./vdocs/.vdoc/scripts/register.sh",
      "args": ["--file", "${input:docFile}", "--feature", "${input:featureName}"]
    }
  ]
}
```

---

## VS Code + Cline

### Rules: `.clinerules`

Cline (formerly Claude Dev) reads project rules from `.clinerules`:

```markdown
# Cline Rules

## Project Context
This is a Next.js application with TypeScript.

## Instructions
- Always use TypeScript strict mode
- Prefer server components
- Use Tailwind for styling

## File Patterns
- Components: src/components/{Name}/{Name}.tsx
- Hooks: src/hooks/use{Name}.ts
- API: src/app/api/{route}/route.ts
```

### Custom Modes

Cline supports custom modes for different workflows:

```json
{
  "modes": {
    "docs": {
      "instructions": "Focus on documentation generation",
      "allowedTools": ["read_file", "write_to_file", "execute_command"]
    }
  }
}
```

---

## GitHub Copilot

### Rules: `.github/copilot-instructions.md`

Repository-level instructions for Copilot.

```markdown
# Copilot Instructions

## Context
This is a TypeScript monorepo using pnpm workspaces.

## Preferences
- Use named exports
- Prefer composition over inheritance
- Write JSDoc comments for public APIs

## Avoid
- Any type
- Console.log in production code
- Hardcoded secrets
```

### Skills
Copilot does not have a custom skills system. Uses slash commands built into the product:
- `/explain` - Explain code
- `/fix` - Fix issues
- `/tests` - Generate tests

---

## JetBrains AI Assistant

### Rules: `.idea/ai-instructions.md`

JetBrains IDEs (IntelliJ, WebStorm, PyCharm, etc.) read AI instructions from the `.idea/` directory.

```markdown
# JetBrains AI Instructions

## Project Overview
Kotlin/Java backend with Spring Boot.

## Conventions
- Use constructor injection
- Follow SOLID principles
- Write unit tests with JUnit 5

## Patterns
- Repository pattern for data access
- Service layer for business logic
- DTOs for API responses
```

### Project-Level Settings

```xml
<!-- .idea/aiAssistant.xml -->
<project>
  <component name="AIAssistantSettings">
    <option name="customInstructions" value="path/to/instructions.md" />
    <option name="enableCodeCompletion" value="true" />
  </component>
</project>
```

---

## vdoc Integration Strategy

### What vdoc Installs

| Platform | Rules Added | Skills Added |
|----------|-------------|--------------|
| Claude Code | Append to `CLAUDE.md` | `.claude/commands/vdoc.md` |
| Cursor | Append to `.cursorrules` | (embedded in rules) |
| Windsurf | Append to `.windsurfrules` | (embedded in rules) |
| VS Code + Copilot | `.github/copilot-instructions.md` | - |
| VS Code + Continue | Append to `.continuerules` | `.continue/prompts/vdoc.md` |
| VS Code + Cline | Append to `.clinerules` | (embedded in rules) |
| Aider | `.aider/vdoc.md` | (referenced manually) |
| Gemini | Append to `GEMINI.md` | Action config |
| JetBrains | `.idea/ai-instructions.md` | - |

### Universal Skill Content

All platforms get the same core instructions, formatted for their system:

```markdown
# vdoc - Documentation Generator

## Workflow

### Step 1: Analyze
Identify documentable features in this codebase:
- Major features (Authentication, User Management, etc.)
- API endpoints
- Database models
- UI components

### Step 2: Generate
For each feature, create a documentation file:
- Location: vdocs/{feature-name}.md
- Include: Overview, usage, API reference, examples

### Step 3: Register
After creating each doc, run:
./vdocs/.vdoc/scripts/register.sh \
  --file "{filename}" \
  --feature "{feature-name}"

## Documentation Standards
- Write for: PMs, new developers, tech leads
- Focus on WHAT and WHY, not just HOW
- Include code examples
- Link to related docs
```

---

## File Locations Summary

```
project/
├── CLAUDE.md                    # Claude Code rules
├── GEMINI.md                    # Gemini/Antigravity rules
├── .cursorrules                 # Cursor rules
├── .windsurfrules               # Windsurf rules
├── .clinerules                  # Cline (VS Code) rules
├── .continuerules               # Continue rules
│
├── .github/
│   └── copilot-instructions.md  # GitHub Copilot rules
│
├── .vscode/
│   ├── settings.json            # VS Code workspace settings
│   └── tasks.json               # VS Code tasks
│
├── .claude/
│   └── commands/
│       └── vdoc.md              # Claude skill
│
├── .continue/
│   ├── config.json              # Continue config
│   └── prompts/
│       └── vdoc.md              # Continue skill
│
├── .aider/
│   └── conventions.md           # Aider conventions
│
├── .idea/
│   └── ai-instructions.md       # JetBrains AI rules
│
└── vdocs/
    ├── _manifest.json           # Documentation registry
    └── .vdoc/
        └── scripts/
            └── register.sh      # Register doc script
```

---

## Platform Detection

vdoc can auto-detect which platforms are in use:

```bash
detect_platforms() {
    [[ -f "CLAUDE.md" ]] && echo "claude"
    [[ -f ".cursorrules" ]] && echo "cursor"
    [[ -f ".windsurfrules" ]] && echo "windsurf"
    [[ -d ".aider" ]] && echo "aider"
    [[ -d ".continue" ]] && echo "continue"
    [[ -f "GEMINI.md" ]] && echo "gemini"
    [[ -f ".github/copilot-instructions.md" ]] && echo "copilot"
}
```

---

## References

- [Claude Code Documentation](https://docs.anthropic.com/claude-code)
- [Cursor Rules Guide](https://cursor.sh/docs/rules)
- [Continue Configuration](https://continue.dev/docs/customization)
- [Aider Conventions](https://aider.chat/docs/config.html)
- [GitHub Copilot Custom Instructions](https://docs.github.com/copilot/customizing-copilot)
