#!/usr/bin/env bash
# Claude Code Adapter
# Transforms instructions.md into SKILL.md format for Claude Code
#
# Output: ~/.claude/skills/vdoc/SKILL.md

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# Find Instructions
# =============================================================================

find_instructions() {
    local locations=(
        "./vdocs/.vdoc/instructions.md"              # Installed in project
        "${SCRIPT_DIR}/../../core/instructions.md"   # Source repo
    )
    
    for loc in "${locations[@]}"; do
        if [[ -f "$loc" ]]; then
            echo "$loc"
            return 0
        fi
    done
    
    echo "Error: instructions.md not found" >&2
    echo "Searched:" >&2
    for loc in "${locations[@]}"; do
        echo "  - $loc" >&2
    done
    return 1
}

# =============================================================================
# Generate SKILL.md
# =============================================================================

generate_skill() {
    local instructions_path
    instructions_path=$(find_instructions)
    
    local output_dir="${HOME}/.claude/skills/vdoc"
    local output_file="${output_dir}/SKILL.md"
    
    # Create directory
    mkdir -p "$output_dir"
    
    # Generate SKILL.md with YAML frontmatter
    cat > "$output_file" << 'EOF'
---
name: vdoc
description: Generate and maintain product documentation from source code
trigger: /vdoc
---

EOF
    
    # Append instructions content
    cat "$instructions_path" >> "$output_file"
    
    echo "Generated: $output_file"
}

# =============================================================================
# Main
# =============================================================================

generate_skill
