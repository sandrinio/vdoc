# STORY-072: Update README with New Installation

## Metadata
| Field | Value |
|-------|-------|
| **Parent Epic** | [EPIC-007](EPIC.md) |
| **Status** | Complete |
| **Ambiguity Score** | 🟢 Low |
| **Actor** | Developer |
| **Complexity** | Low (documentation only) |

---

## 1. The Spec (The Contract)

### 1.1 User Story
> As a **New User**,
> I want clear README instructions **showing the simple installation**,
> So that **I can get started in under 30 seconds**.

### 1.2 Detailed Requirements
- [ ] Update README.md with new curl install command
- [ ] Add quick-start section at top
- [ ] Show 3-command workflow: install, init, use
- [ ] Include animated GIF/screenshot of CLI
- [ ] Add troubleshooting section
- [ ] Document all CLI commands

---

## 2. The Truth (Executable Tests)

### 2.1 Acceptance Criteria (Gherkin)
```gherkin
Feature: README Documentation

  Scenario: Quick start visibility
    Given user opens README.md
    Then first code block shows curl install command
    And second code block shows vdoc init --ai claude

  Scenario: All commands documented
    Given README.md exists
    Then init command is documented
    And scan command is documented
    And quality command is documented
    And install/uninstall commands are documented

  Scenario: Troubleshooting section
    Given user has installation issues
    Then README has troubleshooting section
    And common issues are addressed
```

---

## 3. Technical Context (For Coder Agent)

### 3.1 Affected Files
- `README.md` - Main documentation

### 3.2 README Structure
```markdown
# vdoc

AI-Powered Documentation Generator

## Quick Start

```bash
# Install
curl -fsSL https://vdoc.dev/install | bash

# Initialize in your project
cd your-project
vdoc init --ai claude

# That's it! Open Claude Code and say:
# "generate documentation for this project"
```

## What is vdoc?

vdoc generates living documentation for your codebase using AI...

## Installation

### One-liner (Recommended)
```bash
curl -fsSL https://vdoc.dev/install | bash
```

### Manual Installation
```bash
git clone https://github.com/sandrinio/vdoc.git
cd vdoc && ./install.sh claude
```

## Usage

### Initialize Project
```bash
vdoc init                    # Basic initialization
vdoc init --ai claude        # Init + Claude integration
vdoc init --ai cursor        # Init + Cursor integration
```

### Scan Codebase
```bash
vdoc scan                    # Incremental scan
vdoc scan --full             # Full rescan
```

### Check Quality
```bash
vdoc quality                 # Terminal report
vdoc quality --json          # JSON output (for CI)
vdoc quality --threshold 70  # Fail if score < 70
```

### Manage Platforms
```bash
vdoc install cursor          # Add Cursor integration
vdoc uninstall windsurf      # Remove Windsurf
```

## Supported Platforms

| Platform | Command | Integration |
|----------|---------|-------------|
| Claude Code | `vdoc init --ai claude` | ~/.claude/skills/vdoc/ |
| Cursor | `vdoc init --ai cursor` | .cursor/rules/vdoc.md |
| Windsurf | `vdoc init --ai windsurf` | .windsurfrules |
| Aider | `vdoc init --ai aider` | .aider/conventions/ |
| Continue | `vdoc init --ai continue` | .continue/prompts/ |

## Project Structure

After initialization:
```
your-project/
└── vdocs/
    ├── _manifest.json     # Codebase index
    └── *.md               # Generated documentation
```

## Troubleshooting

### vdoc command not found
Add to your shell profile:
```bash
export PATH="$HOME/.local/bin:$PATH"
```

### jq not found
Install jq for full functionality:
```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt install jq
```

### Permission denied
```bash
chmod +x ~/.vdoc/vdoc
```

## Requirements

- Bash 3.2+ (macOS default)
- jq (recommended)
- Git (for incremental scanning)

## License

MIT
```

---

## 4. Notes
- Keep README under 300 lines
- First impression matters - quick start must be prominent
- Include badges: version, license, platform support
- Consider adding a demo GIF

