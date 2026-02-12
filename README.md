# vdoc

**Documentation skills for AI coding agents.**

One install command. Your AI handles the rest.

---

## What is vdoc?

vdoc teaches your AI coding agent how to create and maintain feature-centric documentation for your codebase. It's not a CLI you run — it's a skill file that gets installed into your AI platform. After install, you just talk to your AI.

```
/vdoc init     →  AI explores codebase → proposes plan → you approve → generates docs
/vdoc audit    →  AI detects stale, missing, dead docs → reports → patches
"how does auth work?"  →  AI reads manifest → routes to right doc → answers
```

---

## Quick Start

```bash
npx vdoc install cursor
```

Then open Cursor and type: **`/vdoc init`**

---

## Supported Platforms

| Platform | Install Command | `/vdoc` Command | Invocation |
|----------|----------------|----------------|------------|
| **Claude Code** | `npx vdoc install claude` | `/vdoc init` `/vdoc audit` | Skill (SKILL.md) |
| **Cursor** | `npx vdoc install cursor` | `/vdoc init` `/vdoc audit` | Command + Rule |
| **Windsurf** | `npx vdoc install windsurf` | `/vdoc` | Workflow + Rule |
| **VS Code (Copilot)** | `npx vdoc install vscode` | `/vdoc` | Prompt + Instructions |
| **Continue** | `npx vdoc install continue` | `/vdoc init` `/vdoc audit` | Invokable Prompt + Rule |
| **Cline** | `npx vdoc install cline` | `/vdoc` | Workflow + Rule |
| **Gemini CLI** | `npx vdoc install gemini` | `/vdoc init` `/vdoc audit` | TOML Command + GEMINI.md |
| **JetBrains AI** | `npx vdoc install jetbrains` | Natural language | Rule only |
| **JetBrains Junie** | `npx vdoc install junie` | Natural language | Guidelines only |
| **Universal** | `npx vdoc install agents` | Natural language | AGENTS.md |

---

## How It Works

### 1. Install (~5 seconds)

```bash
npx vdoc install claude
```

Copies skill files to your AI platform's rules and commands locations. That's it.

### 2. Init

Type **`/vdoc init`** in your AI tool (or say "document this project"). The skill tells the AI to:

1. **Explore** — identify features, tech stack, architecture
2. **Plan** — propose a documentation plan for your approval
3. **Generate** — create feature-centric docs using a consistent template
4. **Index** — build a semantic manifest for future queries

### 3. Audit

Type **`/vdoc audit`** (or say "audit docs"). The AI detects what changed via git, finds coverage gaps, flags dead docs, checks cross-references, reports everything, and patches only what you approve.

### 4. Query

Ask any question. The AI reads the manifest, routes to the right doc, and answers from documented knowledge.

---

## What Gets Created

```
your-project/
└── vdocs/
    ├── _manifest.json                ← Semantic index (AI reads first)
    ├── _DOCUMENTATION_PLAN.md        ← Approved plan (kept for reference)
    ├── PROJECT_OVERVIEW_DOC.md
    ├── AUTHENTICATION_DOC.md
    ├── API_REFERENCE_DOC.md
    ├── DATABASE_SCHEMA_DOC.md
    └── ...
```

Docs are **feature-centric** — organized by what your system does, not by file paths.

---

## Documentation Template

Every generated doc follows a consistent structure:

- **Overview** — what it does, why it exists
- **How It Works** — core logic with mermaid diagrams (max 7-9 nodes per diagram)
- **Data Model** — entities and relationships
- **Key Files** — source files that implement this feature
- **Dependencies & Integrations** — external services, internal features
- **Configuration** — env vars, feature flags, secrets
- **Error Handling** — failure modes and user-facing behavior
- **Constraints & Decisions** — why it's built this way, what you can't change
- **Related Features** — cross-references and blast radius

---

## Manifest

The `_manifest.json` acts as a semantic index. Each entry has a rich `description` field that AI uses to route queries to the right doc:

```json
{
  "documentation": [
    {
      "filepath": "AUTHENTICATION_DOC.md",
      "title": "Authentication - OAuth2 & JWT",
      "version": "1.0.0",
      "description": "OAuth2 flow with Google/GitHub providers, JWT lifecycle, session management via NextAuth.js, route protection middleware, and role-based access control.",
      "tags": ["oauth2", "jwt", "session-management", "rbac"]
    }
  ]
}
```

---

## Uninstall

```bash
npx vdoc uninstall
```

Removes all vdoc skill and rule files from **every** supported platform in one command. No platform argument needed — it scans for and deletes everything vdoc may have created:

| Platform | Files Removed |
|----------|--------------|
| Claude Code | `.claude/skills/vdoc/` |
| Cursor | `.cursor/rules/vdoc.mdc`, `.cursor/commands/vdoc.md` |
| Windsurf | `.windsurf/rules/vdoc.md`, `.windsurf/workflows/vdoc.md` |
| VS Code (Copilot) | `.github/instructions/vdoc.instructions.md`, `.github/prompts/vdoc.prompt.md` |
| Continue | `.continue/rules/vdoc.md`, `.continue/prompts/vdoc-command.md` |
| Cline | `.clinerules/vdoc.md`, `.clinerules/workflows/vdoc.md` |
| Gemini CLI | `.gemini/commands/vdoc.toml` |
| JetBrains AI | `.aiassistant/rules/vdoc.md` |
| Universal | `AGENTS.md` (vdoc section only) |

For files shared with other tools (`GEMINI.md`, `.junie/guidelines.md`, `.github/copilot-instructions.md`), only the vdoc-injected section is removed.

Your `vdocs/` documentation folder is **always kept intact**.

---

## Requirements

None. Your AI coding agent is the runtime.

---

## License

[MIT](LICENSE)

---

*vdoc v3.0.0 — Documentation skills for AI coding agents*
