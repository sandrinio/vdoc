#!/usr/bin/env bash
# =============================================================================
# vdoc Config System - Multi-Language Configuration
# STORY-053: vdoc.config.json schema and loading
# =============================================================================

CONFIG_FILE="vdoc.config.json"
SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

# =============================================================================
# Config Loading
# =============================================================================

# Check if config file exists
has_config() {
    [[ -f "$CONFIG_FILE" ]]
}

# Load and validate config file
# Returns: config JSON on success, empty on no config, exits on error
load_config() {
    local config_path="${1:-$CONFIG_FILE}"

    # No config file = single-language mode (auto-detection)
    if [[ ! -f "$config_path" ]]; then
        echo ""
        return 0
    fi

    # Check if jq is available
    if ! command -v jq &>/dev/null; then
        echo "ERROR: jq is required for multi-language config. Install jq or remove $config_path" >&2
        return 1
    fi

    # Validate JSON syntax
    if ! jq empty "$config_path" 2>/dev/null; then
        echo "ERROR: Invalid JSON syntax in $config_path" >&2
        return 1
    fi

    # Validate required fields
    if ! validate_config "$config_path"; then
        return 1
    fi

    # Return config content
    cat "$config_path"
}

# Validate config structure and values
validate_config() {
    local config_path="$1"
    local errors=0

    # Check version field
    local version
    version=$(jq -r '.version // empty' "$config_path")
    if [[ -z "$version" ]]; then
        echo "ERROR: Missing required field: version" >&2
        ((errors++))
    elif [[ "$version" != "1.0" ]]; then
        echo "ERROR: Unsupported config version: $version (expected: 1.0)" >&2
        ((errors++))
    fi

    # Check languages array
    local lang_count
    lang_count=$(jq -r '.languages | length' "$config_path" 2>/dev/null)
    if [[ -z "$lang_count" ]] || [[ "$lang_count" -eq 0 ]]; then
        echo "ERROR: Missing or empty 'languages' array" >&2
        ((errors++))
    fi

    # Validate each language entry
    local i=0
    while [[ $i -lt ${lang_count:-0} ]]; do
        local path preset
        path=$(jq -r ".languages[$i].path // empty" "$config_path")
        preset=$(jq -r ".languages[$i].preset // empty" "$config_path")

        if [[ -z "$path" ]]; then
            echo "ERROR: languages[$i] missing required field: path" >&2
            ((errors++))
        elif [[ ! "$path" =~ /$ ]]; then
            echo "ERROR: languages[$i].path must end with '/' (got: $path)" >&2
            ((errors++))
        fi

        if [[ -z "$preset" ]]; then
            echo "ERROR: languages[$i] missing required field: preset" >&2
            ((errors++))
        else
            # Check if preset exists
            if ! find_preset_file "$preset" &>/dev/null; then
                echo "ERROR: Unknown preset: $preset" >&2
                ((errors++))
            fi
        fi

        ((i++))
    done

    # Check for overlapping paths (warning only)
    validate_path_overlaps "$config_path"

    [[ $errors -eq 0 ]]
}

# Find preset file location
find_preset_file() {
    local preset="$1"
    local locations=(
        "./vdocs/.vdoc/presets/custom-${preset}.conf"
        "./vdocs/.vdoc/presets/${preset}.conf"
        "${SCRIPT_DIR}/presets/${preset}.conf"
    )

    for loc in "${locations[@]}"; do
        if [[ -f "$loc" ]]; then
            echo "$loc"
            return 0
        fi
    done

    return 1
}

# Validate and warn about overlapping paths
validate_path_overlaps() {
    local config_path="$1"

    # Get sorted paths
    local paths
    paths=$(jq -r '.languages[].path' "$config_path" | sort)

    local prev=""
    local overlaps=()

    while read -r path; do
        [[ -z "$path" ]] && continue

        if [[ -n "$prev" ]]; then
            # Check if current path starts with previous path
            if [[ "$path" == "$prev"* ]] && [[ "$path" != "$prev" ]]; then
                overlaps+=("$path (overrides $prev)")
            fi
        fi
        prev="$path"
    done <<< "$paths"

    if [[ ${#overlaps[@]} -gt 0 ]]; then
        echo "WARNING: Overlapping paths detected (more specific paths take precedence):" >&2
        for overlap in "${overlaps[@]}"; do
            echo "  - $overlap" >&2
        done
    fi
}

# =============================================================================
# Path Matching
# =============================================================================

# Get preset name for a file path
# Returns: preset name, or empty if no match (use auto-detection)
get_preset_for_path() {
    local file_path="$1"
    local config="$2"

    # No config = use auto-detection
    if [[ -z "$config" ]]; then
        echo ""
        return
    fi

    # Find matching path (most specific / longest match wins)
    local preset
    preset=$(echo "$config" | jq -r --arg fpath "$file_path" '
        [.languages[] | .path as $p | select($fpath | startswith($p))]
        | sort_by(.path | length)
        | reverse
        | .[0].preset // empty
    ')

    echo "$preset"
}

# Get all configured paths
get_configured_paths() {
    local config="$1"

    if [[ -z "$config" ]]; then
        return
    fi

    echo "$config" | jq -r '.languages[].path'
}

# Check if a file matches any configured path
file_matches_config() {
    local file_path="$1"
    local config="$2"

    if [[ -z "$config" ]]; then
        return 1
    fi

    local match
    match=$(echo "$config" | jq -r --arg fpath "$file_path" '
        [.languages[] | .path as $p | select($fpath | startswith($p))]
        | length
    ')

    [[ "$match" -gt 0 ]]
}

# =============================================================================
# Settings Access
# =============================================================================

# Get a setting value from config
get_config_setting() {
    local config="$1"
    local setting="$2"
    local default="$3"

    if [[ -z "$config" ]]; then
        echo "$default"
        return
    fi

    local value
    value=$(echo "$config" | jq -r ".settings.$setting // empty")

    if [[ -z "$value" ]] || [[ "$value" == "null" ]]; then
        echo "$default"
    else
        echo "$value"
    fi
}

# Get global excludes from config
get_global_excludes() {
    local config="$1"

    if [[ -z "$config" ]]; then
        return
    fi

    echo "$config" | jq -r '.exclude[]? // empty'
}

# Get path-specific excludes
get_path_excludes() {
    local config="$1"
    local file_path="$2"

    if [[ -z "$config" ]]; then
        return
    fi

    echo "$config" | jq -r --arg fpath "$file_path" '
        [.languages[] | .path as $p | select($fpath | startswith($p))]
        | sort_by(.path | length)
        | reverse
        | .[0].exclude[]? // empty
    '
}

# =============================================================================
# CLI Interface (when run directly)
# =============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        validate)
            if has_config; then
                echo "Validating $CONFIG_FILE..."
                if load_config >/dev/null; then
                    echo "Config is valid."
                    exit 0
                else
                    exit 1
                fi
            else
                echo "No $CONFIG_FILE found."
                exit 1
            fi
            ;;
        show)
            if has_config; then
                load_config | jq .
            else
                echo "No $CONFIG_FILE found."
                exit 1
            fi
            ;;
        preset)
            if [[ -z "$2" ]]; then
                echo "Usage: $0 preset <file_path>"
                exit 1
            fi
            # Load config once, suppress validation output
            config=$(load_config 2>/dev/null)
            if [[ $? -ne 0 ]]; then
                echo "ERROR: Failed to load config" >&2
                exit 1
            fi
            preset=$(get_preset_for_path "$2" "$config")
            if [[ -n "$preset" ]]; then
                echo "$preset"
            else
                echo "(auto-detect)"
            fi
            ;;
        init)
            if has_config; then
                echo "Config already exists: $CONFIG_FILE"
                exit 1
            fi
            cat > "$CONFIG_FILE" << 'EOF'
{
  "$schema": "./core/vdoc.config.schema.json",
  "version": "1.0",
  "languages": [
    { "path": "src/", "preset": "typescript" }
  ],
  "exclude": [],
  "settings": {}
}
EOF
            echo "Created $CONFIG_FILE"
            echo "Edit it to configure your multi-language project."
            ;;
        *)
            echo "Usage: $0 {validate|show|preset <path>|init}"
            echo ""
            echo "Commands:"
            echo "  validate       - Validate vdoc.config.json"
            echo "  show           - Display current config"
            echo "  preset <path>  - Show which preset applies to a file path"
            echo "  init           - Create a starter config file"
            exit 1
            ;;
    esac
fi
