# STORY-070: Create vdoc Unified CLI Wrapper

## Metadata
| Field | Value |
|-------|-------|
| **Parent Epic** | [EPIC-007](EPIC.md) |
| **Status** | Complete |
| **Ambiguity Score** | 🟢 Low |
| **Actor** | Developer |
| **Complexity** | Medium (CLI routing + existing module integration) |

---

## 1. The Spec (The Contract)

### 1.1 User Story
> As a **Developer**,
> I want a single `vdoc` command **with intuitive subcommands**,
> So that **I can easily scan, check quality, and manage my docs**.

### 1.2 Detailed Requirements
- [ ] Create `app/vdoc.sh` as the unified CLI entry point
- [ ] Route subcommands to existing modules (scan.sh, quality.sh, etc.)
- [ ] Implement: `init`, `scan`, `quality`, `install`, `uninstall`, `help`, `version`
- [ ] Support `--ai PLATFORM` flag on `init` command
- [ ] Auto-detect project root (find nearest vdocs/ or git root)
- [ ] Colored output with consistent formatting
- [ ] Exit codes: 0=success, 1=error, 2=quality threshold failed

---

## 2. The Truth (Executable Tests)

### 2.1 Acceptance Criteria (Gherkin)
```gherkin
Feature: vdoc Unified CLI

  Scenario: Show help
    When vdoc --help is run
    Then output shows available commands
    And output shows usage examples

  Scenario: Show version
    When vdoc --version is run
    Then output shows "vdoc v2.x.x"

  Scenario: Initialize project
    Given current directory is a git repo
    When vdoc init is run
    Then vdocs/ directory is created
    And _manifest.json is generated

  Scenario: Initialize with AI platform
    Given current directory is a git repo
    When vdoc init --ai claude is run
    Then vdocs/ directory is created
    And Claude integration is installed

  Scenario: Run scan
    Given vdocs/ exists
    When vdoc scan is run
    Then _manifest.json is updated
    And scan output shows file count

  Scenario: Check quality
    Given vdocs/_manifest.json exists
    When vdoc quality is run
    Then quality report is displayed
    And exit code is 0 if score >= 50

  Scenario: Quality threshold
    Given quality score is 40
    When vdoc quality --threshold 50 is run
    Then exit code is 1 (fail)

  Scenario: Install platform
    Given vdocs/ exists
    When vdoc install cursor is run
    Then Cursor integration is added

  Scenario: Unknown command
    When vdoc foobar is run
    Then error shows "Unknown command: foobar"
    And help is displayed
```

---

## 3. Technical Context (For Coder Agent)

### 3.1 Affected Files
- `app/vdoc.sh` (new) - Main CLI wrapper
- `app/commands/quality.sh` (existing) - Quality command

### 3.2 Implementation
```bash
#!/usr/bin/env bash
# app/vdoc.sh - vdoc Unified CLI

set -euo pipefail

VDOC_VERSION="2.0.0"

# Resolve vdoc installation directory
if [[ -n "${VDOC_HOME:-}" ]]; then
    VDOC_DIR="$VDOC_HOME"
elif [[ -d "${HOME}/.vdoc" ]]; then
    VDOC_DIR="${HOME}/.vdoc"
else
    VDOC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

[[ ! -t 1 ]] && RED='' GREEN='' YELLOW='' BLUE='' BOLD='' NC=''

# Usage
usage() {
    cat << EOF
${BOLD}vdoc${NC} - AI-Powered Documentation Generator

${BOLD}USAGE${NC}
    vdoc <command> [options]

${BOLD}COMMANDS${NC}
    init [--ai PLATFORM]    Initialize vdoc in current project
    scan [--full]           Scan codebase and update manifest
    quality [--json|--md]   Show documentation quality report
    install <platform>      Install AI platform integration
    uninstall <platform>    Remove AI platform integration
    help                    Show this help
    version                 Show version

${BOLD}PLATFORMS${NC}
    claude, cursor, windsurf, aider, continue

${BOLD}EXAMPLES${NC}
    vdoc init --ai claude       # Initialize + install Claude
    vdoc scan                   # Update manifest
    vdoc quality --threshold 70 # Quality gate for CI
    vdoc install cursor         # Add Cursor integration

EOF
}

# Commands
cmd_init() {
    local platform=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --ai|--ai=*)
                [[ "$1" == --ai=* ]] && platform="${1#--ai=}" || { platform="$2"; shift; }
                shift ;;
            *) shift ;;
        esac
    done

    # Create vdocs directory
    mkdir -p vdocs/.vdoc/presets

    # Run initial scan
    bash "${VDOC_DIR}/core/scan.sh" -m

    # Install platform if specified
    if [[ -n "$platform" ]]; then
        cmd_install "$platform"
    fi

    echo -e "${GREEN}✓${NC} vdoc initialized in ./vdocs/"
}

cmd_scan() {
    bash "${VDOC_DIR}/core/scan.sh" -m "$@"
}

cmd_quality() {
    bash "${VDOC_DIR}/app/commands/quality.sh" "$@"
}

cmd_install() {
    local platform="$1"
    bash "${VDOC_DIR}/install.sh" "$platform"
}

cmd_uninstall() {
    local platform="$1"
    bash "${VDOC_DIR}/install.sh" uninstall "$platform"
}

# Main
main() {
    case "${1:-help}" in
        -h|--help|help)
            usage
            ;;
        -v|--version|version)
            echo "vdoc v${VDOC_VERSION}"
            ;;
        init)
            shift
            cmd_init "$@"
            ;;
        scan)
            shift
            cmd_scan "$@"
            ;;
        quality)
            shift
            cmd_quality "$@"
            ;;
        install)
            shift
            cmd_install "$@"
            ;;
        uninstall)
            shift
            cmd_uninstall "$@"
            ;;
        *)
            echo -e "${RED}Unknown command:${NC} $1" >&2
            echo ""
            usage >&2
            exit 1
            ;;
    esac
}

main "$@"
```

### 3.3 CLI Usage Examples
```bash
# Initialize new project
vdoc init
vdoc init --ai claude

# Scan codebase
vdoc scan
vdoc scan --full

# Quality report
vdoc quality
vdoc quality --json
vdoc quality --threshold 70

# Platform management
vdoc install cursor
vdoc uninstall cursor
```

---

## 4. Notes
- CLI should work from any subdirectory of a project
- Auto-detect project root by finding vdocs/ or .git/
- All output goes to stdout, errors to stderr
- Exit codes enable CI integration

