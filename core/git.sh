#!/usr/bin/env bash
# =============================================================================
# vdoc Git Integration - Git-aware Scanning Support
# STORY-050: Track last scan commit in manifest
# STORY-051: Git diff file detection (future)
# =============================================================================

# =============================================================================
# Git Detection
# =============================================================================

# Check if current directory is a git repository
is_git_repo() {
    git rev-parse --is-inside-work-tree &>/dev/null
}

# Get the git repository root directory
get_git_root() {
    git rev-parse --show-toplevel 2>/dev/null
}

# =============================================================================
# STORY-050: Commit Tracking
# =============================================================================

# Get current HEAD commit hash (full 40-char SHA)
# Returns empty string if not a git repo
get_current_commit() {
    if is_git_repo; then
        git rev-parse HEAD 2>/dev/null
    else
        echo ""
    fi
}

# Get short commit hash (7 chars) for display
get_current_commit_short() {
    if is_git_repo; then
        git rev-parse --short HEAD 2>/dev/null
    else
        echo ""
    fi
}

# Get commit timestamp
get_commit_timestamp() {
    local commit="${1:-HEAD}"
    if is_git_repo; then
        git show -s --format=%cI "$commit" 2>/dev/null
    else
        echo ""
    fi
}

# =============================================================================
# STORY-051: Git Diff Detection (Placeholder for future implementation)
# =============================================================================

# Get list of files changed since a specific commit
# Usage: get_changed_files <since_commit>
# Returns: newline-separated list of changed file paths
get_changed_files() {
    local since_commit="$1"

    if [[ -z "$since_commit" ]]; then
        echo "ERROR: No commit specified for diff" >&2
        return 1
    fi

    if ! is_git_repo; then
        echo "ERROR: Not a git repository" >&2
        return 1
    fi

    # Get files that were added, modified, or renamed
    # --diff-filter=AMRC: Added, Modified, Renamed, Copied
    git diff --name-only --diff-filter=AMRC "$since_commit" HEAD 2>/dev/null
}

# Get list of files deleted since a specific commit
get_deleted_files() {
    local since_commit="$1"

    if [[ -z "$since_commit" ]]; then
        echo "ERROR: No commit specified for diff" >&2
        return 1
    fi

    if ! is_git_repo; then
        echo "ERROR: Not a git repository" >&2
        return 1
    fi

    # --diff-filter=D: Deleted only
    git diff --name-only --diff-filter=D "$since_commit" HEAD 2>/dev/null
}

# Check if a specific commit exists in the repo
commit_exists() {
    local commit="$1"
    git cat-file -t "$commit" &>/dev/null
}

# Get files with their change status (for incremental scanning)
# Returns: "status:path" lines where status is 'changed' or 'deleted'
get_files_with_status() {
    local since_commit="$1"

    if [[ -z "$since_commit" ]]; then
        echo "ERROR: No commit specified for diff" >&2
        return 1
    fi

    if ! is_git_repo; then
        echo "ERROR: Not a git repository" >&2
        return 1
    fi

    # Verify the commit exists
    if ! commit_exists "$since_commit"; then
        echo "ERROR: Commit $since_commit not found in history" >&2
        return 1
    fi

    # Get all changes with status
    # --name-status returns: STATUS\tFILENAME (or STATUS\tOLDNAME\tNEWNAME for renames)
    git diff --name-status "$since_commit" HEAD 2>/dev/null | while read -r status file newfile; do
        case "$status" in
            M|A|C) echo "changed:$file" ;;          # Modified, Added, Copied
            D)     echo "deleted:$file" ;;          # Deleted
            R*)    echo "deleted:$file"             # Renamed: old file deleted
                   echo "changed:$newfile" ;;       # Renamed: new file added
        esac
    done
}

# Determine scan mode based on conditions
# Returns: "full" or "incremental"
determine_scan_mode() {
    local last_commit="$1"
    local force_full="${2:-false}"

    # Force full scan if requested
    if [[ "$force_full" == "true" ]]; then
        echo "full"
        return
    fi

    # Not a git repo = full scan
    if ! is_git_repo; then
        echo "full"
        return
    fi

    # No last commit = full scan
    if [[ -z "$last_commit" ]] || [[ "$last_commit" == "null" ]]; then
        echo "full"
        return
    fi

    # Last commit doesn't exist = full scan
    if ! commit_exists "$last_commit"; then
        echo "full"
        return
    fi

    echo "incremental"
}

# Read last_commit_hash from manifest file
read_manifest_commit() {
    local manifest_path="$1"

    if [[ ! -f "$manifest_path" ]]; then
        echo ""
        return
    fi

    # Use jq if available, otherwise grep/sed fallback
    if command -v jq &>/dev/null; then
        jq -r '.last_commit_hash // empty' "$manifest_path" 2>/dev/null
    else
        grep '"last_commit_hash"' "$manifest_path" 2>/dev/null | \
            sed 's/.*:[[:space:]]*"\([^"]*\)".*/\1/' | \
            grep -v '^null$'
    fi
}

# =============================================================================
# CLI Interface (when run directly)
# =============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        commit)
            commit=$(get_current_commit)
            if [[ -n "$commit" ]]; then
                echo "$commit"
            else
                echo "Not a git repository" >&2
                exit 1
            fi
            ;;
        is-git)
            if is_git_repo; then
                echo "yes"
                exit 0
            else
                echo "no"
                exit 1
            fi
            ;;
        changed)
            if [[ -z "$2" ]]; then
                echo "Usage: $0 changed <since_commit>"
                exit 1
            fi
            get_changed_files "$2"
            ;;
        deleted)
            if [[ -z "$2" ]]; then
                echo "Usage: $0 deleted <since_commit>"
                exit 1
            fi
            get_deleted_files "$2"
            ;;
        status)
            if [[ -z "$2" ]]; then
                echo "Usage: $0 status <since_commit>"
                exit 1
            fi
            get_files_with_status "$2"
            ;;
        scan-mode)
            last_commit="${2:-}"
            force="${3:-false}"
            echo "$(determine_scan_mode "$last_commit" "$force")"
            ;;
        manifest-commit)
            if [[ -z "$2" ]]; then
                echo "Usage: $0 manifest-commit <manifest_path>"
                exit 1
            fi
            commit=$(read_manifest_commit "$2")
            if [[ -n "$commit" ]]; then
                echo "$commit"
            else
                echo "No commit found in manifest" >&2
                exit 1
            fi
            ;;
        *)
            echo "Usage: $0 {commit|is-git|changed|deleted|status|scan-mode|manifest-commit}"
            echo ""
            echo "Commands:"
            echo "  commit               - Get current HEAD commit hash"
            echo "  is-git               - Check if current directory is a git repo"
            echo "  changed <commit>     - List files changed since commit"
            echo "  deleted <commit>     - List files deleted since commit"
            echo "  status <commit>      - List files with status (changed:/deleted:)"
            echo "  scan-mode [commit] [force] - Determine scan mode (full/incremental)"
            echo "  manifest-commit <path> - Read last_commit_hash from manifest"
            exit 1
            ;;
    esac
fi
