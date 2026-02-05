#!/usr/bin/env bash
# =============================================================================
# vdoc Manifest Management - Incremental Update Support
# STORY-052: Merge incremental scan results with cache
# =============================================================================

# Known scan-generated fields (will be updated from new scan data)
SCAN_FIELDS=("hash" "category" "description" "description_source" "documented_in")

# =============================================================================
# Manifest Reading
# =============================================================================

# Read existing manifest file
# Returns: manifest JSON or empty string if not found
read_manifest() {
    local manifest_path="$1"

    if [[ ! -f "$manifest_path" ]]; then
        echo ""
        return
    fi

    if ! command -v jq &>/dev/null; then
        cat "$manifest_path"
        return
    fi

    # Validate JSON before returning
    if jq empty "$manifest_path" 2>/dev/null; then
        cat "$manifest_path"
    else
        echo "ERROR: Invalid JSON in manifest: $manifest_path" >&2
        echo ""
    fi
}

# Get source_index entries as key-value pairs
get_source_index() {
    local manifest_path="$1"

    if [[ ! -f "$manifest_path" ]]; then
        echo "{}"
        return
    fi

    jq -r '.source_index // {}' "$manifest_path" 2>/dev/null || echo "{}"
}

# =============================================================================
# Incremental Merge Logic
# =============================================================================

# Merge scan output with existing manifest
# Usage: merge_manifest <manifest_path> <scan_output_file> <deleted_files_list>
# scan_output_file: file containing pipe-delimited scan output
# deleted_files_list: newline-separated list of deleted file paths
merge_manifest() {
    local manifest_path="$1"
    local scan_output_file="$2"
    local deleted_files="$3"
    local verbose="${4:-false}"

    if ! command -v jq &>/dev/null; then
        echo "ERROR: jq is required for incremental merge" >&2
        return 1
    fi

    # Read existing manifest
    local existing_manifest
    existing_manifest=$(read_manifest "$manifest_path")

    if [[ -z "$existing_manifest" ]]; then
        echo "ERROR: No existing manifest to merge with" >&2
        return 1
    fi

    # Convert scan output to JSON entries
    local new_entries
    new_entries=$(scan_output_to_json "$scan_output_file")

    if [[ -z "$new_entries" ]]; then
        new_entries="{}"
    fi

    # Build jq filter for merge
    local jq_filter='
    # Convert deleted files string to array
    ($deleted | split("\n") | map(select(. != ""))) as $to_delete |

    # Merge source_index
    .source_index = (
        # Start with existing entries
        (.source_index // {}) |
        # Remove deleted files
        with_entries(select(.key | IN($to_delete[]) | not)) |
        # Deep merge with new entries (new values override, but preserve unknown keys)
        . as $existing |
        ($new_entries | to_entries | reduce .[] as $item ($existing;
            if .[$item.key] then
                # File exists - merge preserving custom fields
                .[$item.key] = (.[$item.key] * $item.value)
            else
                # New file - add it
                .[$item.key] = $item.value
            end
        ))
    ) |

    # Update documentation covers arrays
    .documentation = [
        (.documentation // [])[] |
        .covers = [(.covers // [])[] | select(IN($to_delete[]) | not)]
    ]
    '

    # Perform the merge
    local merged
    merged=$(echo "$existing_manifest" | jq \
        --argjson new_entries "$new_entries" \
        --arg deleted "$deleted_files" \
        "$jq_filter" 2>/dev/null)

    if [[ $? -ne 0 ]] || [[ -z "$merged" ]]; then
        echo "ERROR: Merge failed" >&2
        return 1
    fi

    # Check for orphaned documentation
    check_orphaned_docs "$merged" "$verbose"

    # Output merged result
    echo "$merged"
}

# Convert pipe-delimited scan output to JSON object
# Input format: path | category | hash | docstring
scan_output_to_json() {
    local scan_file="$1"

    if [[ ! -f "$scan_file" ]]; then
        echo "{}"
        return
    fi

    # Build JSON from scan output
    local json="{"
    local first=true

    while IFS='|' read -r path category hash docstring; do
        # Skip empty lines and comments
        [[ -z "$path" ]] && continue
        [[ "$path" == \#* ]] && continue

        # Trim whitespace
        path=$(echo "$path" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        category=$(echo "$category" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        hash=$(echo "$hash" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        docstring=$(echo "$docstring" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

        # Escape for JSON
        docstring=$(echo "$docstring" | sed 's/"/\\"/g' | sed 's/\\/\\\\/g')

        # Determine description source
        local desc_source="inferred"
        [[ -n "$docstring" ]] && desc_source="docstring"

        # Add comma separator
        if ! $first; then
            json+=","
        fi
        first=false

        # Add entry
        json+="\"$path\":{\"hash\":\"$hash\",\"category\":\"$category\",\"description\":\"$docstring\",\"description_source\":\"$desc_source\",\"documented_in\":[]}"

    done < "$scan_file"

    json+="}"
    echo "$json"
}

# Check for documentation entries with empty covers arrays
check_orphaned_docs() {
    local manifest_json="$1"
    local verbose="${2:-false}"

    local orphaned
    orphaned=$(echo "$manifest_json" | jq -r '
        .documentation // [] |
        map(select((.covers | length) == 0)) |
        .[].path // empty
    ' 2>/dev/null)

    if [[ -n "$orphaned" ]]; then
        while read -r doc_path; do
            [[ -z "$doc_path" ]] && continue
            echo "WARNING: Documentation '$doc_path' now covers 0 files (orphaned)" >&2
        done <<< "$orphaned"
    fi
}

# =============================================================================
# Merge Statistics
# =============================================================================

# Calculate merge statistics
get_merge_stats() {
    local old_manifest="$1"
    local new_manifest="$2"
    local deleted_files="$3"

    local old_count new_count deleted_count added_count updated_count preserved_count

    old_count=$(echo "$old_manifest" | jq '.source_index | length' 2>/dev/null || echo 0)
    new_count=$(echo "$new_manifest" | jq '.source_index | length' 2>/dev/null || echo 0)

    # Count deleted
    deleted_count=$(echo "$deleted_files" | grep -c . 2>/dev/null || echo 0)

    # Calculate other stats
    # (This is simplified - full implementation would compare hashes)
    added_count=$((new_count - old_count + deleted_count))
    if [[ $added_count -lt 0 ]]; then
        added_count=0
    fi

    echo "updated=$added_count deleted=$deleted_count preserved=$((new_count - added_count))"
}

# =============================================================================
# High-Level Operations
# =============================================================================

# Perform incremental update
# Usage: incremental_update <manifest_path> <scan_output_file> <deleted_files>
incremental_update() {
    local manifest_path="$1"
    local scan_output_file="$2"
    local deleted_files="$3"
    local verbose="${4:-false}"

    # Backup original
    local backup_path="${manifest_path}.backup"
    cp "$manifest_path" "$backup_path" 2>/dev/null

    # Read original for stats
    local original_manifest
    original_manifest=$(read_manifest "$manifest_path")

    # Perform merge
    local merged_manifest
    merged_manifest=$(merge_manifest "$manifest_path" "$scan_output_file" "$deleted_files" "$verbose")

    if [[ $? -ne 0 ]] || [[ -z "$merged_manifest" ]]; then
        echo "ERROR: Merge failed, restoring backup" >&2
        mv "$backup_path" "$manifest_path" 2>/dev/null
        return 1
    fi

    # Write merged result
    echo "$merged_manifest" | jq '.' > "$manifest_path"

    # Get and log stats
    local stats
    stats=$(get_merge_stats "$original_manifest" "$merged_manifest" "$deleted_files")
    [[ "$verbose" == "true" ]] && echo "# [merge] $stats" >&2

    # Clean up backup
    rm -f "$backup_path"

    return 0
}

# =============================================================================
# CLI Interface (when run directly)
# =============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        read)
            if [[ -z "$2" ]]; then
                echo "Usage: $0 read <manifest_path>"
                exit 1
            fi
            read_manifest "$2"
            ;;
        source-index)
            if [[ -z "$2" ]]; then
                echo "Usage: $0 source-index <manifest_path>"
                exit 1
            fi
            get_source_index "$2"
            ;;
        merge)
            if [[ -z "$4" ]]; then
                echo "Usage: $0 merge <manifest_path> <scan_file> <deleted_files>"
                exit 1
            fi
            merge_manifest "$2" "$3" "$4"
            ;;
        update)
            if [[ -z "$4" ]]; then
                echo "Usage: $0 update <manifest_path> <scan_file> <deleted_files>"
                exit 1
            fi
            incremental_update "$2" "$3" "$4" true
            ;;
        *)
            echo "Usage: $0 {read|source-index|merge|update}"
            echo ""
            echo "Commands:"
            echo "  read <path>                         - Read manifest"
            echo "  source-index <path>                 - Get source_index as JSON"
            echo "  merge <manifest> <scan> <deleted>   - Merge scan with manifest"
            echo "  update <manifest> <scan> <deleted>  - Incremental update in place"
            exit 1
            ;;
    esac
fi
