#!/usr/bin/env bash
# =============================================================================
# vdoc Preset Cache - Isolated Preset Loading with Caching
# STORY-054: Multi-language preset loading
# Compatible with bash 3.2+ (macOS default)
# =============================================================================

SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

# Track current preset for debugging
CURRENT_PRESET=""

# Cache directory (use temp if available)
PRESET_CACHE_DIR="${TMPDIR:-/tmp}/vdoc-preset-cache-$$"

# =============================================================================
# Preset Variable Management
# =============================================================================

# Reset all preset variables to empty (isolation)
reset_preset_vars() {
    PRESET_NAME=""
    PRESET_VERSION=""
    EXCLUDE_DIRS=""
    EXCLUDE_FILES=""
    ENTRY_PATTERNS=""
    DOCSTRING_PATTERN=""
    DOCSTRING_END=""
    DOC_SIGNALS=""
    SIGNAL_CATEGORIES=()
    SIGNAL_PATTERNS=()
}

# Initialize cache directory
init_preset_cache() {
    if [[ ! -d "$PRESET_CACHE_DIR" ]]; then
        mkdir -p "$PRESET_CACHE_DIR"
    fi
}

# Save current preset variables to cache (file-based for bash 3.2 compat)
cache_preset_vars() {
    local preset_name="$1"
    init_preset_cache

    local cache_file="$PRESET_CACHE_DIR/${preset_name}.cache"

    # Save variable declarations to file
    {
        declare -p PRESET_NAME 2>/dev/null
        declare -p PRESET_VERSION 2>/dev/null
        declare -p EXCLUDE_DIRS 2>/dev/null
        declare -p EXCLUDE_FILES 2>/dev/null
        declare -p ENTRY_PATTERNS 2>/dev/null
        declare -p DOCSTRING_PATTERN 2>/dev/null
        declare -p DOCSTRING_END 2>/dev/null
        declare -p DOC_SIGNALS 2>/dev/null
    } > "$cache_file"
}

# Restore preset variables from cache
restore_preset_vars() {
    local preset_name="$1"
    local cache_file="$PRESET_CACHE_DIR/${preset_name}.cache"

    if [[ -f "$cache_file" ]]; then
        # shellcheck source=/dev/null
        source "$cache_file"
        return 0
    fi
    return 1
}

# Check if preset is cached
is_preset_cached() {
    local preset_name="$1"
    [[ -f "$PRESET_CACHE_DIR/${preset_name}.cache" ]]
}

# =============================================================================
# Preset Loading
# =============================================================================

# Find preset file location
find_preset_file() {
    local preset_name="$1"

    local locations=(
        "./vdocs/.vdoc/presets/custom-${preset_name}.conf"
        "./vdocs/.vdoc/presets/${preset_name}.conf"
        "${SCRIPT_DIR}/presets/${preset_name}.conf"
    )

    for loc in "${locations[@]}"; do
        if [[ -f "$loc" ]]; then
            echo "$loc"
            return 0
        fi
    done

    return 1
}

# Load preset with fresh isolation (prevents variable leakage)
# This is the main function to use for multi-language scanning
load_preset_isolated() {
    local preset_name="$1"
    local verbose="${2:-false}"

    # ALWAYS reset first for safety (fresh isolation)
    reset_preset_vars

    # Check cache first
    if restore_preset_vars "$preset_name"; then
        CURRENT_PRESET="$preset_name"
        [[ "$verbose" == "true" ]] && echo "# [preset] Using cached: $preset_name" >&2

        # Re-parse DOC_SIGNALS for cached preset
        if type parse_doc_signals &>/dev/null; then
            parse_doc_signals
        fi
        return 0
    fi

    # Find preset file
    local preset_file
    if ! preset_file=$(find_preset_file "$preset_name"); then
        echo "ERROR: Preset not found: $preset_name" >&2
        return 1
    fi

    [[ "$verbose" == "true" ]] && echo "# [preset] Loading: $preset_file" >&2

    # Handle EXTENDS inheritance
    local extends_value=""
    if grep -q "^EXTENDS=" "$preset_file" 2>/dev/null; then
        extends_value=$(grep "^EXTENDS=" "$preset_file" | head -1 | cut -d'"' -f2)
    fi

    if [[ -n "$extends_value" ]]; then
        [[ "$verbose" == "true" ]] && echo "# [preset] Extends: $extends_value" >&2

        # Load parent preset first (recursively)
        if ! load_preset_isolated "$extends_value" "$verbose"; then
            echo "ERROR: Parent preset not found: $extends_value" >&2
            return 1
        fi
    fi

    # Source the preset file (child values override parent)
    # shellcheck source=/dev/null
    source "$preset_file"

    # Cache for future use
    cache_preset_vars "$preset_name"
    CURRENT_PRESET="$preset_name"

    # Parse DOC_SIGNALS if the function exists
    if type parse_doc_signals &>/dev/null; then
        parse_doc_signals
    fi

    return 0
}

# Get current preset name
get_current_preset() {
    echo "$CURRENT_PRESET"
}

# Clear preset cache
clear_preset_cache() {
    if [[ -d "$PRESET_CACHE_DIR" ]]; then
        rm -rf "$PRESET_CACHE_DIR"
    fi
    CURRENT_PRESET=""
}

# List cached presets
list_cached_presets() {
    if [[ -d "$PRESET_CACHE_DIR" ]]; then
        ls -1 "$PRESET_CACHE_DIR" 2>/dev/null | sed 's/\.cache$//'
    fi
}

# Cleanup on exit
cleanup_preset_cache() {
    clear_preset_cache
}

# =============================================================================
# CLI Interface (when run directly)
# =============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        load)
            if [[ -z "$2" ]]; then
                echo "Usage: $0 load <preset_name>"
                exit 1
            fi
            if load_preset_isolated "$2" true; then
                echo "Loaded preset: $PRESET_NAME (v${PRESET_VERSION:-unknown})"
                echo "  EXCLUDE_DIRS: $EXCLUDE_DIRS"
                echo "  EXCLUDE_FILES: $EXCLUDE_FILES"
            fi
            clear_preset_cache
            ;;
        find)
            if [[ -z "$2" ]]; then
                echo "Usage: $0 find <preset_name>"
                exit 1
            fi
            if preset_file=$(find_preset_file "$2"); then
                echo "$preset_file"
            else
                echo "Not found: $2" >&2
                exit 1
            fi
            ;;
        list)
            echo "Available presets:"
            shopt -s nullglob 2>/dev/null
            for f in "${SCRIPT_DIR}/presets/"*.conf ./vdocs/.vdoc/presets/*.conf; do
                [[ -f "$f" ]] || continue
                name=$(basename "$f" .conf)
                echo "  - $name"
            done
            shopt -u nullglob 2>/dev/null
            ;;
        *)
            echo "Usage: $0 {load <name>|find <name>|list}"
            exit 1
            ;;
    esac
fi
