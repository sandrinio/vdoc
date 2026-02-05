#!/usr/bin/env bash
# =============================================================================
# vdoc Teammate Setup Script
#
# For new teammates: after cloning a project with vdoc installed, run this
# to generate your preferred platform's instruction file.
#
# Usage: ./vdocs/.vdoc/setup.sh <platform>
# Platforms: claude, cursor, windsurf, aider, continue
#
# This script works completely offline - no downloads required.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTRUCTIONS="${SCRIPT_DIR}/instructions.md"

# Colors
if [[ -t 1 ]] && [[ "${TERM:-}" != "dumb" ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED='' GREEN='' BLUE='' BOLD='' NC=''
fi

log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_error()   { echo -e "${RED}✗${NC} $1"; }
log_info()    { echo -e "${BLUE}→${NC} $1"; }

# =============================================================================
# Validate
# =============================================================================

if [[ ! -f "$INSTRUCTIONS" ]]; then
    log_error "instructions.md not found at: $INSTRUCTIONS"
    echo "  This script should be run from a project with vdoc installed."
    echo "  Expected location: vdocs/.vdoc/instructions.md"
    exit 1
fi

VALID_PLATFORMS="claude cursor windsurf aider continue"

validate_platform() {
    local platform="$1"
    for valid in $VALID_PLATFORMS; do
        [[ "$platform" == "$valid" ]] && return 0
    done
    return 1
}

# =============================================================================
# Adapter Generators (embedded for offline use)
# =============================================================================

generate_claude() {
    local output_dir="${HOME}/.claude/skills/vdoc"
    local output_file="${output_dir}/SKILL.md"

    mkdir -p "$output_dir"

    cat > "$output_file" << 'EOF'
---
name: vdoc
description: Generate and maintain product documentation from source code
trigger: /vdoc
---

EOF

    cat "$INSTRUCTIONS" >> "$output_file"
    log_success "Generated: $output_file"
}

generate_cursor() {
    local output_dir=".cursor/rules"
    local output_file="${output_dir}/vdoc.md"

    mkdir -p "$output_dir"

    cat > "$output_file" << 'EOF'
# vdoc Documentation Generator

> **Trigger:** `/vdoc` or "generate documentation"

---

EOF

    cat "$INSTRUCTIONS" >> "$output_file"

    cat >> "$output_file" << 'EOF'

---

## Platform Notes (Cursor)

1. **scan.sh is safe**: Read-only, only lists files and metadata
2. **No modifications**: Never modifies any project files
3. **Approve with confidence**: Safe to approve shell command execution
EOF

    log_success "Generated: $output_file"
}

generate_windsurf() {
    local output_file=".windsurfrules"
    local vdoc_marker="# vdoc Documentation Generator"
    local vdoc_end_marker="# END vdoc"

    # Remove existing vdoc section if present
    if [[ -f "$output_file" ]]; then
        sed -i.bak "/${vdoc_marker}/,/${vdoc_end_marker}/d" "$output_file" 2>/dev/null || \
        sed "/${vdoc_marker}/,/${vdoc_end_marker}/d" "$output_file" > "${output_file}.tmp" && mv "${output_file}.tmp" "$output_file"
        rm -f "${output_file}.bak"
    fi

    cat >> "$output_file" << 'EOF'

# vdoc Documentation Generator
# Trigger: /vdoc or "generate documentation"

EOF

    cat "$INSTRUCTIONS" >> "$output_file"

    cat >> "$output_file" << 'EOF'

---

## Platform Notes (Windsurf)

1. **scan.sh is safe**: Read-only script, only outputs file metadata
2. **Approve with confidence**: Safe to approve when prompted

# END vdoc
EOF

    log_success "Generated: $output_file"
}

generate_aider() {
    local config_file=".aider.conf.yml"
    local conventions_dir=".aider/conventions"
    local conventions_file="${conventions_dir}/vdoc.md"

    mkdir -p "$conventions_dir"

    cat > "$conventions_file" << 'EOF'
# vdoc Documentation Generator

To generate documentation:
```
/run bash vdocs/.vdoc/scan.sh
```

---

EOF

    cat "$INSTRUCTIONS" >> "$conventions_file"

    cat >> "$conventions_file" << 'EOF'

---

## Platform Notes (Aider)

Use `/run bash vdocs/.vdoc/scan.sh` to execute the scanner.
The scanner is read-only and safe to run.
EOF

    log_success "Generated: $conventions_file"

    # Update or create config
    if [[ ! -f "$config_file" ]] || ! grep -q "conventions/vdoc.md" "$config_file" 2>/dev/null; then
        if [[ ! -f "$config_file" ]]; then
            cat > "$config_file" << 'EOF'
# Aider Configuration
read:
  - .aider/conventions/vdoc.md
EOF
            log_success "Generated: $config_file"
        else
            echo "" >> "$config_file"
            echo "# vdoc" >> "$config_file"
            echo "read:" >> "$config_file"
            echo "  - .aider/conventions/vdoc.md" >> "$config_file"
            log_success "Updated: $config_file"
        fi
    fi
}

generate_continue() {
    local config_dir=".continue"
    local prompts_dir="${config_dir}/prompts"
    local config_file="${config_dir}/config.json"
    local prompt_file="${prompts_dir}/vdoc.md"

    mkdir -p "$prompts_dir"

    cat > "$prompt_file" << 'EOF'
# vdoc Documentation Generator

First, run: `bash vdocs/.vdoc/scan.sh`

---

EOF

    cat "$INSTRUCTIONS" >> "$prompt_file"

    cat >> "$prompt_file" << 'EOF'

---

## Platform Notes (Continue)

The scanner is read-only and safe to approve.
EOF

    log_success "Generated: $prompt_file"

    if [[ ! -f "$config_file" ]]; then
        cat > "$config_file" << 'EOF'
{
  "customCommands": [
    {
      "name": "vdoc",
      "description": "Generate project documentation",
      "prompt": "Generate documentation. First run: bash vdocs/.vdoc/scan.sh"
    }
  ]
}
EOF
        log_success "Generated: $config_file"
    fi
}

# =============================================================================
# Usage
# =============================================================================

usage() {
    cat << EOF
${BOLD}vdoc teammate setup${NC}

Generate platform instruction file for this project (works offline).

${BOLD}USAGE${NC}
    ./vdocs/.vdoc/setup.sh <platform>

${BOLD}PLATFORMS${NC}
    claude      Claude Code (~/.claude/skills/vdoc/SKILL.md)
    cursor      Cursor (.cursor/rules/vdoc.md)
    windsurf    Windsurf (.windsurfrules)
    aider       Aider (.aider/conventions/vdoc.md)
    continue    Continue (.continue/prompts/vdoc.md)

${BOLD}EXAMPLE${NC}
    git clone <project>
    cd <project>
    ./vdocs/.vdoc/setup.sh cursor

EOF
}

# =============================================================================
# Main
# =============================================================================

main() {
    local platform="${1:-}"

    if [[ -z "$platform" ]] || [[ "$platform" == "-h" ]] || [[ "$platform" == "--help" ]]; then
        usage
        exit 0
    fi

    if ! validate_platform "$platform"; then
        log_error "Unknown platform: $platform"
        echo "  Valid platforms: $VALID_PLATFORMS"
        exit 1
    fi

    echo ""
    echo -e "${BOLD}vdoc teammate setup${NC}"
    echo ""

    case "$platform" in
        claude)   generate_claude ;;
        cursor)   generate_cursor ;;
        windsurf) generate_windsurf ;;
        aider)    generate_aider ;;
        continue) generate_continue ;;
    esac

    echo ""
    echo -e "You're ready to use vdoc! Open ${BOLD}${platform}${NC} and ask:"
    echo "  \"generate documentation for this project\""
    echo ""
}

main "$@"
