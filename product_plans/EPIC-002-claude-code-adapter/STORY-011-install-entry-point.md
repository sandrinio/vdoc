# STORY-011: Create install.sh Entry Point

## Metadata
| Field | Value |
|-------|-------|
| **Parent Epic** | [EPIC-002](EPIC.md) |
| **Status** | ✅ Complete |
| **Ambiguity Score** | 🟢 Low |
| **Actor** | Developer |
| **Complexity** | Small (1 file) |

---

## 1. The Spec (The Contract)

### 1.1 User Story
> As a **Developer**,  
> I want to **run a single curl command to install vdoc**,  
> So that **I can start generating documentation without manual setup**.

### 1.2 Detailed Requirements
- [ ] Accept platform argument (claude, cursor, windsurf, aider, continue)
- [ ] Show usage help when no arguments provided
- [ ] Show usage help with `--help` flag
- [ ] Show version with `--version` flag
- [ ] Exit with error code 1 on invalid platform
- [ ] Exit with error code 0 on success
- [ ] Use colored output for status messages (green ✓, red ✗, yellow !)

---

## 2. The Truth (Executable Tests)

### 2.1 Acceptance Criteria (Gherkin)
```gherkin
Feature: install.sh entry point

  Scenario: No arguments shows usage
    Given install.sh exists
    When I run "bash install.sh"
    Then exit code is 1
    And output contains "Usage"

  Scenario: Help flag shows usage
    Given install.sh exists
    When I run "bash install.sh --help"
    Then exit code is 0
    And output contains "Usage"
    And output contains "Platforms:"

  Scenario: Version flag shows version
    Given install.sh exists
    When I run "bash install.sh --version"
    Then exit code is 0
    And output contains "2.0.0"

  Scenario: Invalid platform shows error
    Given install.sh exists
    When I run "bash install.sh invalid"
    Then exit code is 1
    And output contains "Unknown platform"

  Scenario: Valid platform proceeds
    Given install.sh exists
    And I am in a project directory
    When I run "bash install.sh claude"
    Then exit code is 0
    And output contains "✓"
```

---

## 3. Technical Context (For Coder Agent)

### 3.1 Affected Files
- `install.sh` - Main installer script

### 3.2 Implementation
```bash
#!/usr/bin/env bash
set -euo pipefail

VDOC_VERSION="2.0.0"
VALID_PLATFORMS="claude cursor windsurf aider continue"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

usage() {
    echo "vdoc installer v${VDOC_VERSION}"
    echo ""
    echo "Usage: $0 <platform> [options]"
    echo ""
    echo "Platforms:"
    echo "  claude    - Claude Code"
    echo "  cursor    - Cursor"
    echo "  windsurf  - Windsurf"
    echo "  aider     - Aider"
    echo "  continue  - Continue (VS Code)"
    echo ""
    echo "Options:"
    echo "  --help     Show this help"
    echo "  --version  Show version"
}

validate_platform() {
    local platform="$1"
    for valid in $VALID_PLATFORMS; do
        [[ "$platform" == "$valid" ]] && return 0
    done
    return 1
}

main() {
    # Handle flags
    case "${1:-}" in
        --help|-h) usage; exit 0 ;;
        --version|-v) echo "vdoc v${VDOC_VERSION}"; exit 0 ;;
        "") usage; exit 1 ;;
    esac
    
    local platform="$1"
    
    if ! validate_platform "$platform"; then
        echo -e "${RED}✗${NC} Unknown platform: $platform"
        echo "Valid platforms: $VALID_PLATFORMS"
        exit 1
    fi
    
    # Continue to language detection, directory setup, etc.
    # (implemented in other stories)
}

main "$@"
```

---

## 4. Notes
- Placeholder already exists at `install.sh` - needs to be completed
- Color output should degrade gracefully if terminal doesn't support colors
- Script must be POSIX-compatible where possible for curl piping
