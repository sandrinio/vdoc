# vdoc

**Documentation skills for AI coding agents.**

One install command. Your AI handles the rest.

---

## What is vdoc?

vdoc teaches your AI coding agent how to create and maintain feature-centric documentation for your codebase. It's not a CLI you run — it's a skill file that gets installed into your AI platform. After install, you just talk to your AI.

```
/vdoc-init              →  AI explores codebase → proposes plan → you approve → generates docs
/vdoc-update            →  AI detects stale, missing, dead docs → reports → patches
/vdoc-create <feature>  →  AI documents one specific feature on demand
```

---

## Quick Start

```bash
npx @sandrinio/vdoc install cursor
```

Then open Cursor and type: **`/vdoc init`**

---

## Supported Platforms

| Platform | Install Command | `/vdoc` Command | Invocation |
|----------|----------------|----------------|------------|
| **Claude Code** | `npx @sandrinio/vdoc install claude` | `/vdoc-init` `/vdoc-update` `/vdoc-create` | Skills |
| **Cursor** | `npx @sandrinio/vdoc install cursor` | `/vdoc init` `/vdoc audit` | Command + Rule |
| **Windsurf** | `npx @sandrinio/vdoc install windsurf` | `/vdoc` | Workflow + Skill |
| **VS Code (Copilot)** | `npx @sandrinio/vdoc install vscode` | `/vdoc` | Prompt + Instructions |
| **Continue** | `npx @sandrinio/vdoc install continue` | `/vdoc init` `/vdoc audit` | Invokable Prompt + Rule |
| **Cline** | `npx @sandrinio/vdoc install cline` | `/vdoc` | Workflow + Rule |
| **Gemini CLI** | `npx @sandrinio/vdoc install gemini` | `/vdoc init` `/vdoc audit` | TOML Command + GEMINI.md |
| **JetBrains AI** | `npx @sandrinio/vdoc install jetbrains` | Natural language | Rule only |
| **JetBrains Junie** | `npx @sandrinio/vdoc install junie` | Natural language | Guidelines only |
| **Universal** | `npx @sandrinio/vdoc install agents` | Natural language | AGENTS.md |

---

## How It Works

vdoc is **plan-first**. The AI proposes — you decide. Nothing gets generated until you approve.

### 1. Install (~5 seconds)

```bash
npx @sandrinio/vdoc install claude
```

Copies skill files to your AI platform's config. No dependencies, no build step.

### 2. Init — `/vdoc-init`

This is the main workflow. Type `/vdoc-init` (or say "document this project") and the AI runs through four phases:

**Phase 1: Explore** — The AI reads your project's config files and directory structure to identify the language, framework, and architecture. It uses archetype-based strategies (Web API, SPA, Full-Stack, CLI, Library, etc.) to know exactly which files to scan. The result is an exploration log documenting every file read and every feature signal detected.

**Phase 2: Plan** — Based on what it found, the AI creates a documentation plan — a list of proposed docs, each covering one logical feature (not one file). The plan is saved as a file you can review.

**Phase 3: You review** — The AI presents the plan and asks for your input:
- *"Should I merge API routes and middleware into one doc?"*
- *"I found a websocket system — want that documented separately?"*
- *"Any legacy systems I should skip?"*

You can add, remove, rename, or restructure docs before approving. **Nothing is generated until you say go.**

**Phase 4: Generate** — For each approved doc, the AI reads all relevant source files, follows a consistent template, and writes feature-centric documentation with mermaid diagrams, real code references, and a semantic manifest for future AI queries.

### 3. Update — `/vdoc-update`

Type `/vdoc-update` (or `/vdoc-audit`) when your code has changed. The AI:

1. Checks git history to find which source files changed since docs were last updated
2. Cross-references changes against each doc's "Key Files" to identify stale docs
3. Scans for new features not covered by any doc
4. Flags dead docs whose source files were deleted
5. Verifies cross-references between docs

It presents a report and waits for your direction before patching anything.

### 4. Create — `/vdoc-create <feature>`

Type `/vdoc-create authentication system` to document a single feature on demand. The AI locates the relevant source files, generates one doc following the same template, and updates the manifest. Useful for adding docs incrementally without re-running the full init.

---

## What Gets Created

```
your-project/
├── vdocs/
│   ├── _manifest.json                ← Semantic index (AI reads first)
│   ├── PROJECT_OVERVIEW_DOC.md
│   ├── AUTHENTICATION_DOC.md
│   ├── API_REFERENCE_DOC.md
│   ├── DATABASE_SCHEMA_DOC.md
│   └── ...
└── .claude/skills/vdoc-config/       ← Planning artifacts (Claude example)
    ├── _exploration_log.md           ← What was scanned and why
    ├── _DOCUMENTATION_PLAN.md        ← Approved plan
    └── references/
        ├── doc-template.md           ← Shared doc template
        └── manifest-schema.json      ← Shared manifest schema
```

Docs are **feature-centric** — organized by what your system does, not by file paths.

---

## The Workflow

```
┌─────────────────────────────────────────────────────────┐
│                      /vdoc-init                         │
│                                                         │
│   Explore ──→ Plan ──→ You Review ──→ Generate          │
│   (auto)      (auto)   (you decide)   (auto)            │
│                             │                           │
│                    add / remove / rename                 │
│                    merge / split docs                    │
│                    skip features                        │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│               /vdoc-update  or  /vdoc-audit             │
│                                                         │
│   Git Diff ──→ Detect Stale ──→ Report ──→ You Approve  │
│                Detect Gaps       (auto)    ──→ Patch     │
│                Detect Dead                              │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│              /vdoc-create <feature>                      │
│                                                         │
│   Locate Source ──→ Generate Doc ──→ Update Manifest    │
│   (auto)            (auto)           (auto)             │
└─────────────────────────────────────────────────────────┘
```

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
npx @sandrinio/vdoc uninstall
```

Removes all vdoc skill and rule files from **every** supported platform in one command. No platform argument needed — it scans for and deletes everything vdoc may have created:

| Platform | Files Removed |
|----------|--------------|
| Claude Code | `.claude/skills/vdoc-init/`, `vdoc-update/`, `vdoc-create/`, `vdoc-config/` |
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

*vdoc v3.5.2 — Documentation skills for AI coding agents*
