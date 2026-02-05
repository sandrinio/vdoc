#!/usr/bin/env bash
# Continue (VS Code) Adapter
# Transforms instructions.md into .continue/ config format
#
# Output: .continue/config.json (merged) + .continue/prompts/vdoc.md

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
# Generate Continue Config
# =============================================================================

generate_continue_config() {
    local instructions_path
    instructions_path=$(find_instructions)

    local config_dir=".continue"
    local prompts_dir="${config_dir}/prompts"
    local config_file="${config_dir}/config.json"
    local prompt_file="${prompts_dir}/vdoc.md"

    # Create directories
    mkdir -p "$prompts_dir"

    # Generate prompt file
    cat > "$prompt_file" << 'EOF'
# vdoc Documentation Generator

Generate and maintain product documentation for this project.

## How to Use

1. First, run the scanner to understand the project:
   ```bash
   bash vdocs/.vdoc/scan.sh
   ```

2. Parse the output (pipe-delimited: path | category | hash | docstring)

3. Follow the workflow below to generate documentation

---

EOF

    # Append instructions content
    cat "$instructions_path" >> "$prompt_file"

    # Append Continue-specific platform notes
    cat >> "$prompt_file" << 'EOF'

---

## Platform Notes (Continue)

When using vdoc with Continue:

1. **Tool approval**: You'll see an approval dialog before shell commands run
2. **Scanner is safe**: `vdocs/.vdoc/scan.sh` only reads files and outputs metadata
3. **Approve scan.sh**: It's safe to approve - no files are modified
4. **Use @vdoc**: Reference this prompt with @vdoc in your conversations

### Slash Command
Use `/vdoc` to trigger documentation generation (if custom commands are configured).
EOF

    echo "Generated: $prompt_file"

    # Create or update config.json with custom command
    if [[ -f "$config_file" ]]; then
        # Check if vdoc customCommand already exists
        if ! grep -q '"vdoc"' "$config_file" 2>/dev/null; then
            echo "Note: Add vdoc to customCommands in $config_file manually"
            echo "Example customCommand:"
            cat << 'EOF'
{
  "customCommands": [
    {
      "name": "vdoc",
      "description": "Generate project documentation",
      "prompt": "Generate documentation for this project. First run: bash vdocs/.vdoc/scan.sh"
    }
  ]
}
EOF
        fi
    else
        # Create new config file
        cat > "$config_file" << 'EOF'
{
  "customCommands": [
    {
      "name": "vdoc",
      "description": "Generate project documentation",
      "prompt": "Generate documentation for this project following the vdoc instructions. First, run the scanner to understand the project structure: bash vdocs/.vdoc/scan.sh"
    }
  ],
  "docs": [
    {
      "name": "vdoc Instructions",
      "startUrl": "vdocs/.vdoc/instructions.md"
    }
  ]
}
EOF
        echo "Generated: $config_file"
    fi
}

# =============================================================================
# Main
# =============================================================================

generate_continue_config
