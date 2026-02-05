# EPIC-007: Developer Experience & Distribution

## Metadata
| Field | Value |
|-------|-------|
| **Status** | Complete |
| **Ambiguity Score** | 🟢 Low |
| **Context Source** | User feedback - simplified from original scope |
| **Owner** | TBD |
| **Priority** | P1 - High |
| **Tags** | #cli, #installation, #dx, #distribution |
| **Target Date** | TBD |

---

## 1. The Executive Pitch
> Target Audience: Stakeholders, Business Sponsors, Non-Technical Leads

### 1.1 The Problem
vdoc is powerful but hard to install and use. Developers must:
1. Clone the entire repo
2. Navigate to their project
3. Run `./install.sh` from the vdoc source directory
4. Use `bash path/to/scan.sh` for manual operations

There's no unified `vdoc` command. Compare to spec-kit which offers `uv tool install` and a clean `specify init` command.

### 1.2 The Solution
Create a unified `vdoc` CLI that:
1. Installs globally via `curl -fsSL https://vdoc.dev/install | bash`
2. Provides clean subcommands: `vdoc init`, `vdoc scan`, `vdoc quality`
3. Works from any directory (auto-finds/creates vdocs/)

### 1.3 The Value (North Star)
- **5-second install**: One curl command
- **Intuitive CLI**: `vdoc init --ai claude` just works
- **Zero friction**: No need to clone repos or remember paths

---

## 2. The Scope Boundaries (AI Guardrails)
> Target Audience: Planner Agent (Critical for preventing hallucinations)

### 2.1 IN-SCOPE (Build This)
- [x] Create `vdoc` unified CLI wrapper script
- [x] Subcommands: `init`, `scan`, `quality`, `install`, `uninstall`, `help`, `version`
- [x] Global installation via curl one-liner
- [x] Self-contained distribution (single script downloads assets)
- [x] Works from any directory in a project

### 2.2 OUT-OF-SCOPE (Do NOT Build This)
- No Notion/Confluence/GitBook export (future enhancement)
- No npm/Homebrew packages (future enhancement)
- No GitHub Action (future enhancement)
- No community preset repository (future enhancement)
- No Python rewrite (keep bash for portability)

---

## 3. Context

### 3.1 User Personas
| Persona | Need | Current Pain |
|---------|------|--------------|
| **New User** | Quick start | Must clone repo, confusing paths |
| **Daily User** | Run scans easily | No global command |
| **CI Engineer** | Automated checks | Must reference full paths |

### 3.2 Competitive Analysis: spec-kit
```bash
# spec-kit installation
uv tool install specify-cli

# spec-kit usage
specify init my-project --ai claude
```

vdoc should match this simplicity:
```bash
# vdoc installation (target)
curl -fsSL https://vdoc.dev/install | bash

# vdoc usage (target)
vdoc init --ai claude
vdoc scan
vdoc quality
```

### 3.3 User Journey
```mermaid
flowchart LR
    A[curl install] --> B[vdoc init --ai claude]
    B --> C[AI generates docs]
    C --> D[vdoc quality]
    D --> E[vdoc scan]
```

### 3.4 CLI Design
```
vdoc - AI-Powered Documentation Generator

USAGE
    vdoc <command> [options]

COMMANDS
    init [--ai PLATFORM]    Initialize vdoc in current project
    scan [--full]           Scan codebase and update manifest
    quality [--json|--md]   Show documentation quality report
    install <platform>      Install AI platform integration
    uninstall <platform>    Remove AI platform integration
    help                    Show this help
    version                 Show version

PLATFORMS
    claude, cursor, windsurf, aider, continue

EXAMPLES
    vdoc init --ai claude       # Initialize + install Claude integration
    vdoc scan                   # Update manifest with code changes
    vdoc quality --threshold 70 # Quality gate for CI
    vdoc install cursor         # Add Cursor integration
```

---

## 4. Technical Requirements

### 4.1 Installation Flow
```bash
# User runs:
curl -fsSL https://vdoc.dev/install | bash

# Script does:
# 1. Downloads vdoc CLI to ~/.local/bin/vdoc (or /usr/local/bin)
# 2. Downloads core files to ~/.vdoc/
# 3. Adds to PATH if needed
# 4. Prints success message
```

### 4.2 Directory Structure (Global Install)
```
~/.vdoc/                    # Global vdoc installation
├── vdoc                   # Main CLI script (symlinked to PATH)
├── core/
│   ├── scan.sh
│   ├── quality.sh
│   ├── git.sh
│   ├── manifest.sh
│   ├── lock.sh
│   └── config.sh
├── presets/
│   └── *.conf
├── adapters/
│   └── {platform}/generate.sh
└── templates/
    └── *.md
```

### 4.3 Project Structure (Per-Project)
```
my-project/
└── vdocs/
    ├── _manifest.json     # Generated manifest
    ├── .vdoc/
    │   └── presets/       # Custom presets (optional)
    └── *.md               # Documentation pages
```

---

## 5. Dependencies

### 5.1 Technical Dependencies
- Bash 3.2+ (macOS default)
- jq (for JSON processing)
- Git (optional, for incremental scanning)
- curl (for installation)

### 5.2 Epic Dependencies
- Depends on: EPIC-001 through EPIC-006B (all complete)
- Blocks: Nothing (final epic)

---

## 6. Linked Stories
| Story ID | Name | Status |
|----------|------|--------|
| STORY-070 | Create vdoc unified CLI wrapper | Complete |
| STORY-071 | Create global installer script | Complete |
| STORY-072 | Update README with new installation | Complete |

