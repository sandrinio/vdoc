# EPIC-002: Claude Code Adapter & Installation

## Metadata
| Field | Value |
|-------|-------|
| **Status** | ✅ Complete |
| **Ambiguity Score** | 🟢 Low |
| **Context Source** | Roadmap Phase 1 |
| **Owner** | TBD |
| **Priority** | P0 - Critical |
| **Tags** | #installer, #claude-code, #adapter, #distribution |
| **Target Date** | TBD |

---

## 1. The Executive Pitch
> Target Audience: Stakeholders, Business Sponsors, Non-Technical Leads

### 1.1 The Problem
Developers need a frictionless way to install vdoc and integrate it with their AI coding tool. Manual setup is error-prone and discourages adoption.

### 1.2 The Solution
Create a universal installer (`install.sh`) that detects project language, copies core tools, and generates platform-specific instruction files. Start with Claude Code as the primary platform.

### 1.3 The Value (North Star)
- One-command installation: `curl -fsSL vdoc.dev/install | bash -s -- claude`
- Under 2 seconds to complete
- Zero configuration required for common setups

---

## 2. The Scope Boundaries (AI Guardrails)
> Target Audience: Planner Agent (Critical for preventing hallucinations)

### 2.1 IN-SCOPE (Build This)
- [x] `install.sh` - Universal installer with platform flag
- [x] Language auto-detection (package.json, requirements.txt, tsconfig.json, etc.)
- [x] Create `./vdocs/.vdoc/` directory structure
- [x] Copy core files: scan.sh, presets/, templates/, instructions.md
- [x] Claude Code adapter: `adapters/claude/generate.sh`
- [x] Generate `SKILL.md` with YAML frontmatter for Claude Code
- [x] Auto-add platform instruction file to `.gitignore`
- [x] `instructions.md` - Single source of truth for all vdoc logic
- [x] Validation: confirm running from project root
- [x] Print next-step guidance after installation

### 2.2 OUT-OF-SCOPE (Do NOT Build This)
- No Cursor/Windsurf/Aider/Continue adapters (EPIC-004)
- No `--auto` flag for multi-platform detection (EPIC-004)
- No uninstall command (EPIC-004)
- No teammate onboarding flow / setup.sh (EPIC-004)
- No documentation generation logic (EPIC-003)

---

## 3. Context

### 3.1 User Personas
- **Solo Developer**: Installs vdoc for personal project
- **Team Lead**: Sets up vdoc for team adoption

### 3.2 User Journey (Happy Path)
```mermaid
flowchart LR
    A[curl install script] --> B[Detect language]
    B --> C[Create vdocs/.vdoc/]
    C --> D[Copy core files]
    D --> E[Run Claude adapter]
    E --> F[Update .gitignore]
```

### 3.3 Technical Requirements

**Repository Structure (Post-Install):**
```
my-project/
├── .gitignore              ← Updated with SKILL.md path
├── vdocs/
│   ├── .vdoc/              ← Shared tools (committed)
│   │   ├── instructions.md
│   │   ├── scan.sh
│   │   ├── presets/
│   │   └── templates/
│   └── _manifest.json      ← Created on first run
└── ~/.claude/skills/vdoc/SKILL.md  ← Platform-specific (local)
```

**Installer Operations:**
1. Validate platform argument (claude)
2. Detect project language
3. Create ./vdocs/.vdoc/
4. Copy universal core files
5. Run adapter to generate SKILL.md
6. Add SKILL.md path to .gitignore
7. Print confirmation with next step

**Claude Code SKILL.md Format:**
```yaml
---
name: vdoc
description: Generate and maintain product documentation
trigger: /vdoc
---
[instructions.md content wrapped for Claude Code]
```

---

## 4. Dependencies

### 4.1 Technical Dependencies
- Bash 4.0+
- curl (for installation from remote)
- Git (for .gitignore updates)

### 4.2 Epic Dependencies
- Blocked by: EPIC-001 (needs scan.sh and presets)
- Blocks: EPIC-003 (documentation generation needs installer)

---

## 5. Linked Stories
| Story ID | Name | Status |
|----------|------|--------|
| STORY-011 | Create install.sh entry point | ✅ Complete |
| STORY-012 | Implement language detection | ✅ Complete |
| STORY-013 | Create directory structure setup | ✅ Complete |
| STORY-014 | Write instructions.md source of truth | ✅ Complete |
| STORY-015 | Create Claude Code adapter generate.sh | ✅ Complete |
| STORY-016 | Implement SKILL.md generation | ✅ Complete |
| STORY-017 | Add .gitignore update logic | ✅ Complete |
| STORY-018 | Add installation validation & error handling | ✅ Complete |
