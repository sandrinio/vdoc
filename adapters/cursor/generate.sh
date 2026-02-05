#!/usr/bin/env bash
# Cursor Adapter
# Transforms instructions.md into .cursor/rules/ format
#
# Output: .cursor/rules/vdoc.md

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
# Generate Cursor Rules
# =============================================================================

generate_cursor_rules() {
    local instructions_path
    instructions_path=$(find_instructions)

    local output_dir=".cursor/rules"
    local output_file="${output_dir}/vdoc.md"

    # Create directory
    mkdir -p "$output_dir"

    # Generate rules file with Cursor-specific header
    cat > "$output_file" << 'EOF'
# vdoc Documentation Generator

> **Trigger:** `/vdoc` or "generate documentation"

This rule enables AI-powered documentation generation for this project.

---

EOF

    # Append instructions content
    cat "$instructions_path" >> "$output_file"

    # Append Cursor-specific platform notes
    cat >> "$output_file" << 'EOF'

---

## Platform Notes (Cursor)

When running shell commands in this project:

1. **Explain before executing**: Always describe what a command does before running it
2. **scan.sh is safe**: The scanner (`vdocs/.vdoc/scan.sh`) is read-only - it only lists files and extracts metadata
3. **No modifications**: The scanner never modifies, deletes, or writes to any project files
4. **Typical command**: `bash vdocs/.vdoc/scan.sh` outputs file paths, categories, and docstrings

If Cursor prompts for shell command approval, scan.sh is safe to approve.
EOF

    echo "Generated: $output_file"
}

# =============================================================================
# Main
# =============================================================================

generate_cursor_rules
