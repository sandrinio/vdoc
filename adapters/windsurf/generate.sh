#!/usr/bin/env bash
# Windsurf Adapter
# Transforms instructions.md into .windsurfrules format
#
# Output: .windsurfrules (appends vdoc section)

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
    return 1
}

# =============================================================================
# Generate Windsurf Rules
# =============================================================================

generate_windsurf_rules() {
    local instructions_path
    instructions_path=$(find_instructions)

    local output_file=".windsurfrules"
    local temp_file=".windsurfrules.tmp"
    local vdoc_marker="# vdoc Documentation Generator"
    local vdoc_end_marker="# END vdoc"

    # If file exists, remove existing vdoc section
    if [[ -f "$output_file" ]]; then
        # Remove lines between vdoc markers (inclusive)
        sed "/${vdoc_marker}/,/${vdoc_end_marker}/d" "$output_file" > "$temp_file"
        mv "$temp_file" "$output_file"
    fi

    # Append vdoc section
    cat >> "$output_file" << 'EOF'

# vdoc Documentation Generator
# Trigger: /vdoc or "generate documentation"
# This section enables AI-powered documentation generation

EOF

    # Append instructions content
    cat "$instructions_path" >> "$output_file"

    # Append Windsurf-specific platform notes
    cat >> "$output_file" << 'EOF'

---

## Platform Notes (Windsurf)

When Cascade needs to run shell commands:

1. **Approval dialog**: You'll see a confirmation before any command runs
2. **scan.sh is safe**: The scanner (`vdocs/.vdoc/scan.sh`) only reads files
3. **Read-only operation**: It outputs metadata (paths, categories, hashes) without modifying anything
4. **Approve with confidence**: When asked to run `bash vdocs/.vdoc/scan.sh`, it's safe to approve

The scanner helps Cascade understand your project structure for documentation.

# END vdoc
EOF

    echo "Generated: $output_file"
}

# =============================================================================
# Main
# =============================================================================

generate_windsurf_rules
