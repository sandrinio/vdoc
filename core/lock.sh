#!/usr/bin/env bash
# =============================================================================
# vdoc Lock System - Concurrent Update Prevention
# STORY-055: .vdoc.lock creation and checking
# STORY-056: Stale lock cleanup (10 min timeout)
# =============================================================================

# Configuration
LOCK_FILE=".vdoc.lock"
LOCK_STALE_MINUTES="${VDOC_LOCK_TIMEOUT_MINUTES:-10}"

# =============================================================================
# STORY-055: Lock Creation and Checking
# =============================================================================

# Check if a process is running (cross-platform)
is_process_running() {
    local pid="$1"
    [[ -z "$pid" ]] && return 1
    kill -0 "$pid" 2>/dev/null
}

# Get current timestamp in ISO format
get_timestamp() {
    date -u +%Y-%m-%dT%H:%M:%SZ
}

# Get timestamp as epoch seconds (cross-platform)
timestamp_to_epoch() {
    local ts="$1"

    # Strip the 'Z' suffix for parsing
    local ts_clean="${ts%Z}"

    # Try GNU date first
    if date --version 2>&1 | grep -q GNU; then
        date -u -d "$ts" +%s 2>/dev/null
    else
        # BSD date (macOS) - parse as UTC
        date -u -j -f "%Y-%m-%dT%H:%M:%S" "$ts_clean" +%s 2>/dev/null
    fi
}

# Create the lock file with metadata
create_lock_file() {
    cat > "$LOCK_FILE" << EOF
{
  "started_at": "$(get_timestamp)",
  "pid": $$,
  "user": "${USER:-unknown}",
  "platform": "${VDOC_PLATFORM:-cli}",
  "hostname": "$(hostname 2>/dev/null || echo 'unknown')"
}
EOF
}

# Read a field from lock file
read_lock_field() {
    local field="$1"

    if [[ ! -f "$LOCK_FILE" ]]; then
        return 1
    fi

    # Try jq first, fall back to grep/sed
    if command -v jq &>/dev/null; then
        jq -r ".$field // empty" "$LOCK_FILE" 2>/dev/null
    else
        grep "\"$field\"" "$LOCK_FILE" 2>/dev/null | \
            sed 's/.*:[[:space:]]*"\{0,1\}\([^",}]*\)"\{0,1\}.*/\1/'
    fi
}

# Display lock error with details
show_lock_error() {
    local started
    local user
    local pid
    local hostname

    started=$(read_lock_field "started_at")
    user=$(read_lock_field "user")
    pid=$(read_lock_field "pid")
    hostname=$(read_lock_field "hostname")

    echo "ERROR: Update already in progress" >&2
    echo "" >&2
    echo "  Lock details:" >&2
    echo "    Started:  $started" >&2
    echo "    User:     $user" >&2
    echo "    PID:      $pid" >&2
    echo "    Host:     $hostname" >&2
    echo "" >&2
    echo "  If this is stale, wait ${LOCK_STALE_MINUTES} minutes or use --force" >&2
}

# =============================================================================
# STORY-056: Stale Lock Detection and Cleanup
# =============================================================================

# Check if lock is stale (returns reason if stale, empty if fresh)
check_lock_stale() {
    if [[ ! -f "$LOCK_FILE" ]]; then
        return 1
    fi

    local pid
    local started

    pid=$(read_lock_field "pid")
    started=$(read_lock_field "started_at")

    # Check 1: Process is dead
    if [[ -n "$pid" ]] && [[ "$pid" != "null" ]]; then
        if ! is_process_running "$pid"; then
            echo "process_dead"
            return 0
        fi
    fi

    # Check 2: Lock is too old
    local started_epoch
    local now_epoch

    started_epoch=$(timestamp_to_epoch "$started")
    now_epoch=$(date +%s)

    if [[ -n "$started_epoch" ]] && [[ -n "$now_epoch" ]]; then
        local age_minutes=$(( (now_epoch - started_epoch) / 60 ))

        if [[ $age_minutes -ge $LOCK_STALE_MINUTES ]]; then
            echo "$age_minutes"
            return 0
        fi
    fi

    return 1
}

# Clean up stale lock with logging
cleanup_stale_lock() {
    local stale_reason

    if stale_reason=$(check_lock_stale); then
        local user
        local started

        user=$(read_lock_field "user")
        started=$(read_lock_field "started_at")

        if [[ "$stale_reason" == "process_dead" ]]; then
            echo "WARNING: Removing stale lock (process not running)" >&2
        else
            echo "WARNING: Removing stale lock (${stale_reason} minutes old)" >&2
        fi

        echo "  Original lock by: $user at $started" >&2
        rm -f "$LOCK_FILE"
        return 0
    fi

    return 1
}

# =============================================================================
# Public API
# =============================================================================

# Acquire lock (call at start of update)
# Usage: acquire_lock [force]
# Returns: 0 on success, 1 if locked
acquire_lock() {
    local force="${1:-false}"

    if [[ -f "$LOCK_FILE" ]]; then
        # Try stale cleanup first
        if cleanup_stale_lock; then
            # Stale lock was removed, proceed
            :
        elif [[ "$force" == "true" ]]; then
            echo "WARNING: Overriding existing lock (--force)" >&2
            rm -f "$LOCK_FILE"
        else
            show_lock_error
            return 1
        fi
    fi

    # Create new lock
    create_lock_file

    # Set up cleanup trap for signals
    trap 'release_lock; exit 130' INT
    trap 'release_lock; exit 143' TERM
    trap 'release_lock' EXIT

    return 0
}

# Release lock (call at end of update or on error)
release_lock() {
    if [[ -f "$LOCK_FILE" ]]; then
        # Only remove if we own it (check PID)
        local lock_pid
        lock_pid=$(read_lock_field "pid")

        if [[ "$lock_pid" == "$$" ]]; then
            rm -f "$LOCK_FILE"
        fi
    fi
}

# Check if locked (for status commands)
# Returns: 0 if locked, 1 if not locked
is_locked() {
    [[ -f "$LOCK_FILE" ]]
}

# Get lock info as JSON (for status display)
get_lock_info() {
    if [[ -f "$LOCK_FILE" ]]; then
        cat "$LOCK_FILE"
    else
        echo '{"locked": false}'
    fi
}

# =============================================================================
# CLI Interface (when run directly)
# =============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        acquire)
            acquire_lock "${2:-false}"
            exit $?
            ;;
        release)
            release_lock
            ;;
        status)
            if is_locked; then
                echo "Locked:"
                get_lock_info

                if stale_reason=$(check_lock_stale); then
                    echo ""
                    echo "Status: STALE ($stale_reason)"
                else
                    echo ""
                    echo "Status: ACTIVE"
                fi
                exit 0
            else
                echo "Not locked"
                exit 1
            fi
            ;;
        cleanup)
            if cleanup_stale_lock; then
                echo "Stale lock removed"
            else
                echo "No stale lock found"
            fi
            ;;
        *)
            echo "Usage: $0 {acquire|release|status|cleanup} [force]"
            echo ""
            echo "Commands:"
            echo "  acquire [force]  - Acquire lock (force=true to override)"
            echo "  release          - Release lock"
            echo "  status           - Show lock status"
            echo "  cleanup          - Remove stale locks"
            echo ""
            echo "Environment:"
            echo "  VDOC_LOCK_TIMEOUT_MINUTES  - Stale timeout (default: 10)"
            echo "  VDOC_PLATFORM              - Platform identifier for lock"
            exit 1
            ;;
    esac
fi
