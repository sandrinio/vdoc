# STORY-034: Create setup.sh for Teammate Onboarding

## Metadata
| Field | Value |
|-------|-------|
| **Status** | ✅ Complete |
| **Story Points** | 2 |
| **Priority** | P1 - High |
| **Parent Epic** | EPIC-004 |

---

## User Story
**As a** new teammate joining a project with vdoc
**I want** to generate my platform's instruction file locally
**So that** I can use vdoc without downloading anything from the internet

---

## Acceptance Criteria

### AC1: Works offline from cloned repo
- [ ] Uses existing `vdocs/.vdoc/instructions.md`
- [ ] No network requests required
- [ ] Works immediately after `git clone`

### AC2: Generate adapter for specified platform
- [ ] `setup.sh claude` generates SKILL.md
- [ ] `setup.sh cursor` generates .cursor/rules/vdoc.md
- [ ] Same for windsurf, aider, continue

### AC3: Clear onboarding message
- [ ] Show what was generated
- [ ] Show next steps for the platform
- [ ] Note that vdoc tools are already present

---

## Technical Notes

**Script Location:** `vdocs/.vdoc/setup.sh`

**Implementation:**
```bash
#!/usr/bin/env bash
# Teammate Setup Script
# Run from project root after git clone

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ ! -f "${SCRIPT_DIR}/instructions.md" ]]; then
    echo "Error: vdocs/.vdoc/instructions.md not found"
    echo "This script should be run from a project with vdoc installed"
    exit 1
fi

# Run the appropriate adapter
case "${1:-}" in
    claude)
        bash "${SCRIPT_DIR}/../../adapters/claude/generate.sh" 2>/dev/null || \
        bash "${SCRIPT_DIR}/adapters/claude.sh"
        ;;
    cursor|windsurf|aider|continue)
        # Similar logic
        ;;
    *)
        echo "Usage: ./vdocs/.vdoc/setup.sh <platform>"
        echo "Platforms: claude, cursor, windsurf, aider, continue"
        exit 1
        ;;
esac
```

**Alternative: Embedded Adapters**
Instead of referencing adapters/, bundle minimal adapter logic in setup.sh:
```bash
generate_claude() {
    local output_dir="${HOME}/.claude/skills/vdoc"
    mkdir -p "$output_dir"
    cat > "${output_dir}/SKILL.md" << 'HEADER'
---
name: vdoc
description: Generate and maintain product documentation
trigger: /vdoc
---
HEADER
    cat "${SCRIPT_DIR}/instructions.md" >> "${output_dir}/SKILL.md"
}
```

**User Flow:**
```
$ git clone git@github.com:team/project.git
$ cd project
$ ./vdocs/.vdoc/setup.sh cursor

✓ Generated .cursor/rules/vdoc.md

You're ready to use vdoc! Open Cursor and ask:
  "generate documentation for this project"
```

---

## Definition of Done
- [ ] `vdocs/.vdoc/setup.sh` created during install
- [ ] Works offline with only local files
- [ ] Supports all 5 platforms
- [ ] Clear onboarding instructions shown
- [ ] Tested by cloning and running setup
