#!/usr/bin/env bash
# =============================================================================
# vdoc Scanner - Pure Bash Codebase Scanner
# Version: 2.0.0
#
# Outputs pipe-delimited format:
#   path | category | hash | docstring
#
# Usage:
#   ./scan.sh [options]
#
# Options:
#   -h, --help     Show help
#   -v, --verbose  Verbose output
#   -q, --quiet    Suppress header (just data lines)
# =============================================================================

set -euo pipefail

VDOC_VERSION="2.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Options
VERBOSE=false
QUIET=false
GENERATE_MANIFEST=false
VALIDATE_PRESET=false
FORCE_LOCK=false
SKIP_LOCK=false
FORCE_FULL_SCAN=false  # STORY-051: Force full scan even with valid last_commit
SKIP_QUALITY=false     # STORY-062: Skip quality metrics calculation
MANIFEST_PATH="./vdocs/_manifest.json"
PRESET_OVERRIDE=""

# Source lock module (STORY-055, STORY-056)
if [[ -f "${SCRIPT_DIR}/lock.sh" ]]; then
    source "${SCRIPT_DIR}/lock.sh"
fi

# Source config module (STORY-053, STORY-054)
if [[ -f "${SCRIPT_DIR}/config.sh" ]]; then
    source "${SCRIPT_DIR}/config.sh"
fi

# Source preset cache module (STORY-054)
if [[ -f "${SCRIPT_DIR}/preset-cache.sh" ]]; then
    source "${SCRIPT_DIR}/preset-cache.sh"
fi

# Source git module (STORY-050, STORY-051)
if [[ -f "${SCRIPT_DIR}/git.sh" ]]; then
    source "${SCRIPT_DIR}/git.sh"
fi

# Source manifest module (STORY-052)
if [[ -f "${SCRIPT_DIR}/manifest.sh" ]]; then
    source "${SCRIPT_DIR}/manifest.sh"
fi

# Source quality module (STORY-062)
if [[ -f "${SCRIPT_DIR}/quality.sh" ]]; then
    source "${SCRIPT_DIR}/quality.sh"
fi

# Scan tracking variables (STORY-050)
SCAN_MODE="full"
SCANNED_FILES_COUNT=0
CHANGED_FILES_COUNT=0
LAST_COMMIT_HASH=""

# Preset variables (set by load_preset)
PRESET_NAME=""
PRESET_VERSION=""
EXCLUDE_DIRS=""
EXCLUDE_FILES=""
ENTRY_PATTERNS=""
DOCSTRING_PATTERN=""
DOCSTRING_END=""
DOC_SIGNALS=""

# Parsed DOC_SIGNALS
declare -a SIGNAL_CATEGORIES=()
declare -a SIGNAL_PATTERNS=()

# =============================================================================
# Logging
# =============================================================================

log_verbose() {
    $VERBOSE && echo "# [verbose] $1" >&2
    return 0
}

log_error() {
    echo "# [error] $1" >&2
}

# =============================================================================
# STORY-002: Preset Loading System
# =============================================================================

# Detect project language from marker files
detect_language() {
    if [[ -f "tsconfig.json" ]]; then
        echo "typescript"
    elif [[ -f "package.json" ]]; then
        echo "javascript"
    elif [[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]]; then
        echo "python"
    elif [[ -f "go.mod" ]]; then
        echo "go"
    elif [[ -f "Cargo.toml" ]]; then
        echo "rust"
    elif [[ -f "pom.xml" ]] || [[ -f "build.gradle" ]]; then
        echo "java"
    else
        echo "default"
    fi
}

# Find preset file
# Priority: custom presets > local presets > built-in presets > default
find_preset() {
    local language="$1"

    # Check for custom preset first (custom-*.conf)
    local custom_preset="./vdocs/.vdoc/presets/custom-${language}.conf"
    if [[ -f "$custom_preset" ]]; then
        echo "$custom_preset"
        return 0
    fi

    # Standard locations
    local locations=(
        "./vdocs/.vdoc/presets/${language}.conf"
        "${SCRIPT_DIR}/presets/${language}.conf"
    )

    for loc in "${locations[@]}"; do
        if [[ -f "$loc" ]]; then
            echo "$loc"
            return 0
        fi
    done

    # Fall back to default
    for loc in "./vdocs/.vdoc/presets/default.conf" "${SCRIPT_DIR}/presets/default.conf"; do
        if [[ -f "$loc" ]]; then
            echo "$loc"
            return 0
        fi
    done

    return 1
}

# Validate preset has required variables
validate_preset() {
    local missing=()
    [[ -z "${PRESET_NAME:-}" ]] && missing+=("PRESET_NAME")
    [[ -z "${EXCLUDE_DIRS:-}" ]] && missing+=("EXCLUDE_DIRS")
    [[ -z "${DOC_SIGNALS:-}" ]] && missing+=("DOC_SIGNALS")

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Preset missing required variables: ${missing[*]}"
        return 1
    fi
    return 0
}

# Full preset validation with detailed output
validate_preset_full() {
    local preset_name="$1"
    local errors=0
    local warnings=0

    echo "Validating preset: $preset_name"
    echo ""

    # Find and load preset
    local preset_file
    if ! preset_file=$(find_preset "$preset_name"); then
        echo "✗ Error: Preset '$preset_name' not found"
        return 1
    fi

    echo "Found: $preset_file"
    echo ""

    # Load the preset
    load_preset_file "$preset_file"

    # Check required variables
    if [[ -z "${PRESET_NAME:-}" ]]; then
        echo "✗ Error: PRESET_NAME not defined"
        ((errors++))
    else
        echo "✓ PRESET_NAME: \"$PRESET_NAME\""
    fi

    if [[ -z "${PRESET_VERSION:-}" ]]; then
        echo "⚠ Warning: PRESET_VERSION not defined"
        ((warnings++))
    else
        echo "✓ PRESET_VERSION: \"$PRESET_VERSION\""
    fi

    # Check EXTENDS
    if [[ -n "${EXTENDS:-}" ]]; then
        if find_preset "$EXTENDS" &>/dev/null; then
            echo "✓ EXTENDS: \"$EXTENDS\" (found)"
        else
            echo "✗ Error: EXTENDS \"$EXTENDS\" not found"
            ((errors++))
        fi
    fi

    echo ""
    echo "Checking EXCLUDE_DIRS..."
    if [[ -z "${EXCLUDE_DIRS:-}" ]]; then
        echo "⚠ Warning: EXCLUDE_DIRS is empty"
        ((warnings++))
    else
        for dir in $EXCLUDE_DIRS; do
            if [[ -d "$dir" ]]; then
                echo "✓ $dir (exists, will be excluded)"
            else
                echo "  $dir (not present)"
            fi
        done
    fi

    echo ""
    echo "Checking DOC_SIGNALS..."
    local signal_count=0
    while IFS=: read -r category pattern; do
        category=$(echo "$category" | tr -d '[:space:]')
        pattern=$(echo "$pattern" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

        [[ -z "$category" || -z "$pattern" ]] && continue
        [[ "$category" == \#* ]] && continue

        ((signal_count++))

        # Check for valid format
        if [[ ! "$pattern" =~ [\*\?/] ]] && [[ ! -f "$pattern" ]] && [[ ! -d "$pattern" ]]; then
            echo "⚠ Warning: $category:$pattern (literal path, not found)"
            ((warnings++))
        else
            echo "✓ $category:$pattern"
        fi
    done <<< "$DOC_SIGNALS"

    if [[ $signal_count -eq 0 ]]; then
        echo "✗ Error: No valid DOC_SIGNALS defined"
        ((errors++))
    fi

    echo ""
    echo "Summary:"
    echo "  Warnings: $warnings"
    echo "  Errors: $errors"
    echo ""

    if [[ $errors -gt 0 ]]; then
        echo "Preset validation FAILED"
        return 1
    else
        echo "Preset validation PASSED"
        return 0
    fi
}

# Load a preset file, handling EXTENDS inheritance
load_preset_file() {
    local preset_file="$1"
    local is_parent="${2:-false}"

    # Check if preset has EXTENDS directive
    local extends_value=""
    if grep -q "^EXTENDS=" "$preset_file" 2>/dev/null; then
        extends_value=$(grep "^EXTENDS=" "$preset_file" | head -1 | cut -d'"' -f2)
    fi

    # If extending, load parent first
    if [[ -n "$extends_value" ]]; then
        log_verbose "Preset extends: $extends_value"
        local parent_file
        if parent_file=$(find_preset "$extends_value"); then
            load_preset_file "$parent_file" true
        else
            log_error "Parent preset not found: $extends_value"
            exit 1
        fi
    fi

    # Source this preset (child values override parent)
    # shellcheck source=/dev/null
    source "$preset_file"
}

# Load preset for detected language or CLI override
load_preset() {
    local language

    # Use CLI override if provided
    if [[ -n "$PRESET_OVERRIDE" ]]; then
        language="$PRESET_OVERRIDE"
        log_verbose "Using preset override: $language"
    else
        language=$(detect_language)
        log_verbose "Detected language: $language"
    fi

    local preset_file
    if ! preset_file=$(find_preset "$language"); then
        log_error "No preset found for language: $language"
        exit 1
    fi

    log_verbose "Loading preset: $preset_file"

    # Load preset with inheritance support
    load_preset_file "$preset_file"

    if ! validate_preset; then
        exit 1
    fi

    # Parse DOC_SIGNALS
    parse_doc_signals

    log_verbose "Preset loaded: $PRESET_NAME v$PRESET_VERSION"
}

# =============================================================================
# STORY-008: DOC_SIGNALS Category Matching
# =============================================================================

# Parse DOC_SIGNALS into arrays
parse_doc_signals() {
    SIGNAL_CATEGORIES=()
    SIGNAL_PATTERNS=()
    
    while IFS=: read -r category pattern; do
        # Skip empty lines and trim whitespace
        category=$(echo "$category" | tr -d '[:space:]')
        pattern=$(echo "$pattern" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        [[ -z "$category" || -z "$pattern" ]] && continue
        [[ "$category" == \#* ]] && continue
        
        SIGNAL_CATEGORIES+=("$category")
        SIGNAL_PATTERNS+=("$pattern")
    done <<< "$DOC_SIGNALS"
    
    log_verbose "Parsed ${#SIGNAL_CATEGORIES[@]} category patterns"
}

# Match a path against a glob pattern
match_glob() {
    local path="$1"
    local pattern="$2"
    
    # Convert glob to regex
    # Escape dots, convert ** to .*, convert * to [^/]*
    local regex="$pattern"
    regex=$(echo "$regex" | sed 's/\./\\./g')
    regex=$(echo "$regex" | sed 's/\*\*/.*/g')
    regex=$(echo "$regex" | sed 's/\*/[^\/]*/g')
    regex="^${regex}$"
    
    [[ "$path" =~ $regex ]]
}

# Categorize a file based on DOC_SIGNALS
categorize_file() {
    local file="$1"
    
    for i in "${!SIGNAL_PATTERNS[@]}"; do
        if match_glob "$file" "${SIGNAL_PATTERNS[$i]}"; then
            echo "${SIGNAL_CATEGORIES[$i]}"
            return
        fi
    done
    
    echo "other"
}

# =============================================================================
# STORY-007: Hash Computation
# =============================================================================

# Compute truncated SHA-256 hash of file
compute_hash() {
    local file="$1"
    local hash=""
    
    if command -v shasum &>/dev/null; then
        hash=$(shasum -a 256 "$file" 2>/dev/null | cut -d' ' -f1)
    elif command -v sha256sum &>/dev/null; then
        hash=$(sha256sum "$file" 2>/dev/null | cut -d' ' -f1)
    else
        # Fallback: use md5 or cksum
        if command -v md5 &>/dev/null; then
            hash=$(md5 -q "$file" 2>/dev/null)
        elif command -v md5sum &>/dev/null; then
            hash=$(md5sum "$file" 2>/dev/null | cut -d' ' -f1)
        else
            hash=$(cksum "$file" 2>/dev/null | awk '{print $1}')
        fi
    fi
    
    # Truncate to 10 characters
    echo "${hash:0:10}"
}

# =============================================================================
# STORY-006: Docstring Extraction
# =============================================================================

# Extract first docstring from file
extract_docstring() {
    local file="$1"
    local docstring=""
    
    # Read first 50 lines
    local content
    content=$(head -50 "$file" 2>/dev/null) || return
    
    # Try block comment patterns based on file extension
    local ext="${file##*.}"
    
    case "$ext" in
        ts|tsx|js|jsx|java|go|rs|c|cpp|h|hpp)
            # JSDoc / C-style: /** ... */
            docstring=$(echo "$content" | sed -n '/\/\*\*/,/\*\//p' | head -20 | \
                sed 's/^[[:space:]]*\/\*\*[[:space:]]*//g' | \
                sed 's/[[:space:]]*\*\/$//g' | \
                sed 's/^[[:space:]]*\*[[:space:]]*//g' | \
                tr '\n' ' ' | sed 's/  */ /g; s/^ *//; s/ *$//')
            ;;
        py)
            # Python: """ ... """ or ''' ... '''
            docstring=$(echo "$content" | sed -n '/^[[:space:]]*"""/,/"""/p' | head -20 | \
                sed 's/"""//g' | tr '\n' ' ' | sed 's/  */ /g; s/^ *//; s/ *$//')
            
            # Try single quotes if double quotes didn't match
            if [[ -z "$docstring" ]]; then
                docstring=$(echo "$content" | sed -n "/^[[:space:]]*'''/,/'''/p" | head -20 | \
                    sed "s/'''//g" | tr '\n' ' ' | sed 's/  */ /g; s/^ *//; s/ *$//')
            fi
            ;;
        rb)
            # Ruby: # comments at top
            docstring=$(echo "$content" | grep -m5 '^#' | sed 's/^#\s*//' | \
                tr '\n' ' ' | sed 's/  */ /g; s/^ *//; s/ *$//')
            ;;
        *)
            # Generic: try /** */ or // or #
            docstring=$(echo "$content" | sed -n '/\/\*\*/,/\*\//p' | head -20 | \
                sed 's/^\s*\/\*\*//; s/\*\///; s/^\s*\*\s*//g' | \
                tr '\n' ' ' | sed 's/  */ /g; s/^ *//; s/ *$//')
            
            # Try single-line comment
            if [[ -z "$docstring" ]]; then
                docstring=$(echo "$content" | grep -m1 '^\s*\(//\|#\)\s*[A-Z]' | \
                    sed 's/^\s*\/\/\s*//; s/^\s*#\s*//')
            fi
            ;;
    esac
    
    # Extract first sentence and truncate
    if [[ -n "$docstring" ]]; then
        # Get first sentence (ends with . ! or ?)
        local first_sentence
        first_sentence=$(echo "$docstring" | sed 's/\([.!?]\).*/\1/' | head -c 200)
        
        # Truncate if too long
        if [[ ${#first_sentence} -gt 100 ]]; then
            docstring="${first_sentence:0:97}..."
        else
            docstring="$first_sentence"
        fi
    fi
    
    # Escape pipe characters for output format
    docstring=$(echo "$docstring" | sed 's/|/\\|/g')
    
    echo "$docstring"
}

# =============================================================================
# STORY-001: Core File Walker
# =============================================================================

# Check if path should be excluded
is_excluded_dir() {
    local path="$1"
    for exclude in $EXCLUDE_DIRS; do
        if [[ "$path" == *"/$exclude/"* ]] || [[ "$path" == "./$exclude/"* ]] || [[ "$path" == "$exclude/"* ]]; then
            return 0
        fi
    done
    return 1
}

# Check if file should be excluded
is_excluded_file() {
    local filename="$1"
    for pattern in $EXCLUDE_FILES; do
        # Simple glob matching
        case "$filename" in
            $pattern) return 0 ;;
        esac
    done
    return 1
}

# Get list of source files
walk_files() {
    # Build find command exclusions
    local find_excludes=""
    for dir in $EXCLUDE_DIRS; do
        find_excludes="$find_excludes -name '$dir' -prune -o"
    done
    
    # Find all files
    eval "find . $find_excludes -type f -print" 2>/dev/null | sort | while read -r file; do
        # Strip ./ prefix
        file="${file#./}"
        
        # Skip if in excluded directory (double check)
        is_excluded_dir "./$file" && continue
        
        # Skip if matches excluded file pattern
        local filename
        filename=$(basename "$file")
        is_excluded_file "$filename" && continue
        
        # Skip hidden files/directories
        [[ "$file" == .* ]] && continue
        [[ "$filename" == .* ]] && continue
        
        # Skip binary files (check first few bytes)
        # Note: "executable" alone matches scripts, so be more specific
        local file_type
        file_type=$(file "$file" 2>/dev/null)
        if echo "$file_type" | grep -qE 'binary|ELF|Mach-O|image data|archive|compressed'; then
            continue
        fi
        
        echo "$file"
    done
}

# Process a single file
process_file() {
    local file="$1"
    
    local hash
    hash=$(compute_hash "$file")
    
    local category
    category=$(categorize_file "$file")
    
    local docstring
    docstring=$(extract_docstring "$file")
    
    echo "$file | $category | $hash | $docstring"
}

# =============================================================================
# STORY-010: Manifest Utilities
# =============================================================================

# Get project name from package.json, pyproject.toml, or directory
get_project_name() {
    if [[ -f "package.json" ]]; then
        grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' package.json 2>/dev/null | \
            head -1 | cut -d'"' -f4
    elif [[ -f "pyproject.toml" ]]; then
        grep -E '^name[[:space:]]*=' pyproject.toml 2>/dev/null | \
            head -1 | sed 's/.*=[[:space:]]*"\([^"]*\)".*/\1/'
    else
        basename "$(pwd)"
    fi
}

# Generate manifest JSON from scan output
generate_manifest() {
    local scan_output="$1"
    local project_name
    project_name=$(get_project_name)

    mkdir -p "$(dirname "$MANIFEST_PATH")"

    # STORY-050: Get current commit hash
    local commit_hash=""
    if type get_current_commit &>/dev/null; then
        commit_hash=$(get_current_commit)
    fi

    # Format commit hash for JSON (null if empty)
    local commit_json="null"
    if [[ -n "$commit_hash" ]]; then
        commit_json="\"$commit_hash\""
    fi

    # Start JSON
    cat > "$MANIFEST_PATH" << EOF
{
  "project": "$project_name",
  "language": "$PRESET_NAME",
  "last_updated": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "vdoc_version": "$VDOC_VERSION",
  "last_commit_hash": $commit_json,
  "last_scan_mode": "$SCAN_MODE",
  "scanned_files_count": $SCANNED_FILES_COUNT,
  "changed_files_count": $CHANGED_FILES_COUNT,
  "documentation": [],
  "source_index": {
EOF

    # Add source entries
    local first=true
    while IFS='|' read -r path category hash docstring; do
        # Trim whitespace
        path=$(echo "$path" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        category=$(echo "$category" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        hash=$(echo "$hash" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        docstring=$(echo "$docstring" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/"/\\"/g')

        [[ -z "$path" ]] && continue
        [[ "$path" == \#* ]] && continue

        # Add comma separator between entries
        if ! $first; then
            printf ',\n' >> "$MANIFEST_PATH"
        fi
        first=false

        local desc_source="inferred"
        [[ -n "$docstring" ]] && desc_source="docstring"

        # Use printf for cleaner JSON formatting
        printf '    "%s": {\n' "$path" >> "$MANIFEST_PATH"
        printf '      "hash": "%s",\n' "$hash" >> "$MANIFEST_PATH"
        printf '      "category": "%s",\n' "$category" >> "$MANIFEST_PATH"
        printf '      "description": "%s",\n' "$docstring" >> "$MANIFEST_PATH"
        printf '      "description_source": "%s",\n' "$desc_source" >> "$MANIFEST_PATH"
        printf '      "documented_in": []\n' >> "$MANIFEST_PATH"
        printf '    }' >> "$MANIFEST_PATH"
    done <<< "$scan_output"

    # Close JSON
    printf '\n  }\n}\n' >> "$MANIFEST_PATH"

    log_verbose "Generated manifest: $MANIFEST_PATH"
}

# =============================================================================
# Main
# =============================================================================

usage() {
    cat << EOF
vdoc scanner v${VDOC_VERSION}

Usage: $0 [options]

Options:
    -h, --help              Show this help
    -v, --verbose           Verbose output (to stderr)
    -q, --quiet             Suppress header comments
    -m, --manifest          Generate vdocs/_manifest.json
    --preset=NAME           Use specific preset (overrides auto-detection)
    --validate-preset=NAME  Validate a preset and exit
    --force                 Override existing lock (use with caution)
    --no-lock               Skip lock acquisition (for read-only scans)
    --full                  Force full scan (ignore incremental optimization)
    --skip-quality          Skip quality metrics calculation

Output format (pipe-delimited):
    path | category | hash | docstring

Concurrency:
    When generating manifests (-m), a .vdoc.lock file prevents concurrent
    updates. Stale locks (>${VDOC_LOCK_TIMEOUT_MINUTES:-10} min) are auto-cleaned.

Custom Presets:
    Place custom presets in: vdocs/.vdoc/presets/custom-NAME.conf
    Custom presets can extend built-in ones: EXTENDS="typescript"

Example:
    $0 > scan-output.txt
    $0 -v 2>scan.log
    $0 -m                        # Generate manifest file
    $0 --preset=go               # Force Go preset
    $0 --preset=custom-nextjs    # Use custom preset
    $0 --validate-preset=go      # Validate preset
    $0 -m --force                # Override existing lock
EOF
}

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -q|--quiet)
                QUIET=true
                shift
                ;;
            -m|--manifest)
                GENERATE_MANIFEST=true
                shift
                ;;
            --preset=*)
                PRESET_OVERRIDE="${1#--preset=}"
                shift
                ;;
            --validate-preset=*)
                VALIDATE_PRESET=true
                PRESET_OVERRIDE="${1#--validate-preset=}"
                shift
                ;;
            --force|-f)
                FORCE_LOCK=true
                shift
                ;;
            --no-lock)
                SKIP_LOCK=true
                shift
                ;;
            --full)
                FORCE_FULL_SCAN=true
                shift
                ;;
            --skip-quality)
                SKIP_QUALITY=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done

    # Handle validation mode
    if $VALIDATE_PRESET; then
        validate_preset_full "$PRESET_OVERRIDE"
        exit $?
    fi

    # ==========================================================================
    # STORY-055: Acquire lock for manifest generation
    # ==========================================================================
    if $GENERATE_MANIFEST && ! $SKIP_LOCK; then
        if type acquire_lock &>/dev/null; then
            log_verbose "Acquiring lock..."
            if ! acquire_lock "$FORCE_LOCK"; then
                exit 1
            fi
            log_verbose "Lock acquired"
        fi
    fi

    # ==========================================================================
    # STORY-051: Determine scan mode (full vs incremental)
    # ==========================================================================
    local LAST_MANIFEST_COMMIT=""
    local INCREMENTAL_CHANGED_FILES=""
    local INCREMENTAL_DELETED_FILES=""

    if type determine_scan_mode &>/dev/null; then
        # Read last commit from existing manifest
        if [[ -f "$MANIFEST_PATH" ]]; then
            LAST_MANIFEST_COMMIT=$(read_manifest_commit "$MANIFEST_PATH")
        fi

        # Determine scan mode
        SCAN_MODE=$(determine_scan_mode "$LAST_MANIFEST_COMMIT" "$FORCE_FULL_SCAN")

        if [[ "$SCAN_MODE" == "incremental" ]]; then
            log_verbose "Incremental mode: scanning changes since ${LAST_MANIFEST_COMMIT:0:10}..."
            INCREMENTAL_CHANGED_FILES=$(get_changed_files "$LAST_MANIFEST_COMMIT")
            INCREMENTAL_DELETED_FILES=$(get_deleted_files "$LAST_MANIFEST_COMMIT")
            CHANGED_FILES_COUNT=$(echo "$INCREMENTAL_CHANGED_FILES" | grep -c . 2>/dev/null || echo 0)
            log_verbose "Found $CHANGED_FILES_COUNT changed files"
        else
            if [[ -n "$LAST_MANIFEST_COMMIT" ]] && ! commit_exists "$LAST_MANIFEST_COMMIT"; then
                log_verbose "Previous commit ${LAST_MANIFEST_COMMIT:0:10} not found, running full scan"
            elif [[ -z "$LAST_MANIFEST_COMMIT" ]]; then
                log_verbose "No previous commit found, running full scan"
            elif $FORCE_FULL_SCAN; then
                log_verbose "Forced full scan"
            fi
        fi
    else
        SCAN_MODE="full"
    fi

    # ==========================================================================
    # STORY-054: Multi-language support via vdoc.config.json
    # ==========================================================================
    local MULTI_LANG_CONFIG=""
    if type load_config &>/dev/null && [[ -z "$PRESET_OVERRIDE" ]]; then
        MULTI_LANG_CONFIG=$(load_config 2>/dev/null)
        if [[ -n "$MULTI_LANG_CONFIG" ]]; then
            log_verbose "Multi-language mode: vdoc.config.json loaded"
        fi
    fi

    # Load default preset for initial file walking (exclusions)
    if [[ -n "$MULTI_LANG_CONFIG" ]]; then
        # In multi-lang mode, start with default preset for walking
        load_preset
        log_verbose "Using default preset for initial file scan"
    else
        # Single-language mode: load detected/specified preset
        load_preset
    fi

    # Collect files
    log_verbose "Walking directory tree..."
    local files
    files=$(walk_files)

    local total_file_count
    total_file_count=$(echo "$files" | grep -c . 2>/dev/null || echo 0)
    log_verbose "Found $total_file_count files total"

    # ==========================================================================
    # STORY-051: Filter files for incremental mode
    # ==========================================================================
    if [[ "$SCAN_MODE" == "incremental" ]] && [[ -n "$INCREMENTAL_CHANGED_FILES" ]]; then
        log_verbose "Filtering to changed files only..."

        # Create a temp file with changed files for filtering
        local changed_file_list="${TMPDIR:-/tmp}/vdoc-changed-$$"
        echo "$INCREMENTAL_CHANGED_FILES" > "$changed_file_list"

        # Filter walked files to only include changed ones
        local filtered_files=""
        while read -r file; do
            [[ -z "$file" ]] && continue
            if grep -Fxq "$file" "$changed_file_list" 2>/dev/null; then
                filtered_files="${filtered_files}${file}"$'\n'
            fi
        done <<< "$files"

        rm -f "$changed_file_list"
        files="$filtered_files"

        local file_count
        file_count=$(echo "$files" | grep -c . 2>/dev/null || echo 0)
        SCANNED_FILES_COUNT=$file_count
        CHANGED_FILES_COUNT=$file_count
        log_verbose "Scanning $file_count changed files (of $total_file_count total)"
    else
        SCANNED_FILES_COUNT=$total_file_count
        log_verbose "Scanning all $total_file_count files (full scan)"
    fi

    local file_count=$SCANNED_FILES_COUNT

    # ==========================================================================
    # Multi-language: Group files by preset
    # ==========================================================================
    local scan_output=""

    if [[ -n "$MULTI_LANG_CONFIG" ]]; then
        log_verbose "Grouping files by preset..."

        # Group files by preset (file-based for bash 3.2 compatibility)
        local grouping_dir="${TMPDIR:-/tmp}/vdoc-grouping-$$"
        mkdir -p "$grouping_dir"
        local unmapped_file="$grouping_dir/_unmapped.files"
        local unmapped_count=0

        local warn_unmapped
        warn_unmapped=$(get_config_setting "$MULTI_LANG_CONFIG" "warnUnmappedFiles" "true")

        while read -r file; do
            [[ -z "$file" ]] && continue

            local preset
            preset=$(get_preset_for_path "$file" "$MULTI_LANG_CONFIG")

            if [[ -z "$preset" ]]; then
                echo "$file" >> "$unmapped_file"
                ((unmapped_count++))
                preset="default"
            fi

            echo "$file" >> "$grouping_dir/${preset}.files"
        done <<< "$files"

        # Warn about unmapped files if enabled
        if [[ "$warn_unmapped" == "true" ]] && [[ $unmapped_count -gt 0 ]]; then
            log_verbose "$unmapped_count files have no matching path, using default preset"
            if $VERBOSE && [[ -f "$unmapped_file" ]]; then
                head -5 "$unmapped_file" | while read -r f; do
                    echo "# [warning] Unmapped: $f" >&2
                done
                if [[ $unmapped_count -gt 5 ]]; then
                    echo "# [warning] ... and $((unmapped_count - 5)) more" >&2
                fi
            fi
        fi

        # Get list of presets used
        local presets_used
        presets_used=$(ls -1 "$grouping_dir"/*.files 2>/dev/null | xargs -I{} basename {} .files | grep -v "^_" | tr '\n' ' ')

        # Output header (multi-language)
        if ! $QUIET; then
            echo "# vdoc scan output"
            echo "# generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
            echo "# mode: multi-language"
            echo "# scan_mode: $SCAN_MODE"
            echo "# presets: $presets_used"
            echo "# files: $file_count"
            if [[ "$SCAN_MODE" == "incremental" ]]; then
                echo "# since_commit: ${LAST_MANIFEST_COMMIT:0:10}"
            fi
        fi

        # Process each preset group
        for preset_file in "$grouping_dir"/*.files; do
            [[ -f "$preset_file" ]] || continue
            local preset
            preset=$(basename "$preset_file" .files)
            [[ "$preset" == "_unmapped" ]] && continue

            local preset_files
            preset_files=$(cat "$preset_file")
            local preset_count
            preset_count=$(wc -l < "$preset_file" | tr -d ' ')

            log_verbose "Processing $preset_count files with preset: $preset"

            # Load preset with fresh isolation
            if type load_preset_isolated &>/dev/null; then
                if ! load_preset_isolated "$preset" "$VERBOSE"; then
                    log_error "Failed to load preset: $preset, skipping files"
                    continue
                fi
            else
                # Fallback to standard preset loading
                PRESET_OVERRIDE="$preset"
                load_preset
            fi

            # Process files for this preset
            while read -r file; do
                [[ -z "$file" ]] && continue
                log_verbose "Processing [$preset]: $file"
                local line
                line=$(process_file "$file")
                echo "$line"
                scan_output="${scan_output}${line}"$'\n'
            done <<< "$preset_files"
        done

        # Cleanup grouping directory
        rm -rf "$grouping_dir"
    else
        # ==========================================================================
        # Single-language mode (original behavior)
        # ==========================================================================

        # Output header
        if ! $QUIET; then
            echo "# vdoc scan output"
            echo "# generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
            echo "# language: $PRESET_NAME"
            echo "# scan_mode: $SCAN_MODE"
            echo "# files: $file_count"
            if [[ "$SCAN_MODE" == "incremental" ]]; then
                echo "# since_commit: ${LAST_MANIFEST_COMMIT:0:10}"
            fi
        fi

        # Process each file and capture output
        while read -r file; do
            [[ -z "$file" ]] && continue
            log_verbose "Processing: $file"
            local line
            line=$(process_file "$file")
            echo "$line"
            scan_output="${scan_output}${line}"$'\n'
        done <<< "$files"
    fi

    # Generate manifest if requested
    if $GENERATE_MANIFEST; then
        # ==========================================================================
        # STORY-052: Incremental merge or full generation
        # ==========================================================================
        if [[ "$SCAN_MODE" == "incremental" ]] && [[ -f "$MANIFEST_PATH" ]] && type incremental_update &>/dev/null; then
            log_verbose "Performing incremental manifest update..."

            # Write scan output to temp file
            local scan_temp="${TMPDIR:-/tmp}/vdoc-scan-$$"
            echo "$scan_output" > "$scan_temp"

            # Perform incremental update
            if incremental_update "$MANIFEST_PATH" "$scan_temp" "$INCREMENTAL_DELETED_FILES" "$VERBOSE"; then
                log_verbose "Incremental manifest update complete"
            else
                log_verbose "Incremental update failed, falling back to full generation"
                generate_manifest "$scan_output"
            fi

            rm -f "$scan_temp"
        else
            generate_manifest "$scan_output"
            log_verbose "Manifest generation complete"
        fi

        # ==========================================================================
        # STORY-062: Calculate and embed quality metrics in manifest
        # ==========================================================================
        if [[ "$SKIP_QUALITY" != "true" ]] && type calculate_quality &>/dev/null; then
            log_verbose "Calculating quality metrics..."

            local vdocs_dir
            vdocs_dir="$(dirname "$MANIFEST_PATH")"

            local quality_json
            quality_json=$(calculate_quality "$MANIFEST_PATH" "$vdocs_dir" 2>/dev/null)

            if [[ -n "$quality_json" ]] && echo "$quality_json" | jq -e . &>/dev/null; then
                # Merge quality into manifest
                local temp_manifest="${MANIFEST_PATH}.tmp"

                if jq --argjson quality "$quality_json" '. + {quality: $quality}' "$MANIFEST_PATH" > "$temp_manifest" 2>/dev/null; then
                    mv "$temp_manifest" "$MANIFEST_PATH"
                    log_verbose "Quality metrics added to manifest"

                    local overall_score
                    overall_score=$(echo "$quality_json" | jq -r '.overall_score // 0')
                    log_verbose "Overall quality score: $overall_score/100"
                else
                    log_verbose "Warning: Failed to merge quality metrics into manifest"
                    rm -f "$temp_manifest"
                fi
            else
                log_verbose "Warning: Could not calculate quality metrics"
            fi
        fi
    fi
}

main "$@"
