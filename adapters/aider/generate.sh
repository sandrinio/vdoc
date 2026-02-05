#!/usr/bin/env bash
# Aider Adapter
# Transforms instructions.md into Aider conventions format
#
# Output: .aider.conf.yml + .aider/conventions/vdoc.md

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
# Generate Aider Config
# =============================================================================

generate_aider_config() {
    local instructions_path
    instructions_path=$(find_instructions)

    local config_file=".aider.conf.yml"
    local conventions_dir=".aider/conventions"
    local conventions_file="${conventions_dir}/vdoc.md"

    # Create conventions directory
    mkdir -p "$conventions_dir"

    # Generate conventions file with Aider-specific guidance
    cat > "$conventions_file" << 'EOF'
# vdoc Documentation Generator

> **Trigger:** "generate documentation", "vdoc", or "document this project"

## Quick Start for Aider

To generate documentation, run the scanner first:
```
/run bash vdocs/.vdoc/scan.sh
```

Then follow the workflow in the instructions below.

---

EOF

    # Append instructions content
    cat "$instructions_path" >> "$conventions_file"

    # Append Aider-specific platform notes
    cat >> "$conventions_file" << 'EOF'

---

## Platform Notes (Aider)

Aider uses explicit commands to run shell scripts:

1. **Use /run command**: To execute the scanner, suggest `/run bash vdocs/.vdoc/scan.sh`
2. **Scanner is read-only**: It only outputs file metadata, never modifies files
3. **Output format**: Pipe-delimited lines with path, category, hash, and docstring
4. **Parse the output**: Use the scanner results to understand the project structure

### Example Workflow
```
User: Generate documentation for this project
Assistant: I'll scan your project first.

/run bash vdocs/.vdoc/scan.sh

[Parse output, then follow instructions to generate docs]
```
EOF

    echo "Generated: $conventions_file"

    # Update .aider.conf.yml to read conventions
    if [[ -f "$config_file" ]]; then
        # Check if read section already includes our conventions
        if ! grep -q "conventions/vdoc.md" "$config_file" 2>/dev/null; then
            # Append read directive
            echo "" >> "$config_file"
            echo "# vdoc conventions" >> "$config_file"
            echo "read:" >> "$config_file"
            echo "  - .aider/conventions/vdoc.md" >> "$config_file"
            echo "Updated: $config_file"
        fi
    else
        # Create new config file
        cat > "$config_file" << 'EOF'
# Aider Configuration
# https://aider.chat/docs/config.html

# vdoc conventions
read:
  - .aider/conventions/vdoc.md
EOF
        echo "Generated: $config_file"
    fi
}

# =============================================================================
# Main
# =============================================================================

generate_aider_config
