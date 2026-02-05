# STORY-055: Implement .vdoc.lock Creation and Checking

## Metadata
| Field | Value |
|-------|-------|
| **Parent Epic** | [EPIC-006A](EPIC.md) |
| **Status** | Complete |
| **Ambiguity Score** | 🟢 Low |
| **Actor** | Developer |
| **Complexity** | Low (file operations + checks) |

---

## 1. The Spec (The Contract)

### 1.1 User Story
> As a **Team Developer**,
> I want vdoc to **prevent concurrent updates**,
> So that **manifest corruption from simultaneous runs is avoided**.

### 1.2 Detailed Requirements
- [ ] Create `.vdoc.lock` file at start of update operation
- [ ] Lock file contains: timestamp, PID, user, platform
- [ ] Check for existing lock before starting
- [ ] If lock exists and is fresh: abort with clear message
- [ ] If lock exists and is stale: handled by STORY-056
- [ ] Remove lock file on successful completion
- [ ] Remove lock file on error/interrupt (trap signals)
- [ ] Add `--force` flag to override lock (with warning)

---

## 2. The Truth (Executable Tests)

### 2.1 Acceptance Criteria (Gherkin)
```gherkin
Feature: vdoc Lock File

  Scenario: Create lock on update start
    Given no .vdoc.lock exists
    When vdoc update starts
    Then .vdoc.lock is created
    And lock contains current timestamp
    And lock contains current PID
    And lock contains current user

  Scenario: Abort when lock exists
    Given .vdoc.lock exists
    And lock was created 2 minutes ago
    When vdoc update is attempted
    Then operation aborts
    And error message shows "Update already in progress"
    And error message shows lock owner and timestamp

  Scenario: Remove lock on success
    Given vdoc update is running
    And .vdoc.lock exists
    When update completes successfully
    Then .vdoc.lock is deleted

  Scenario: Remove lock on error
    Given vdoc update is running
    And .vdoc.lock exists
    When update fails with an error
    Then .vdoc.lock is deleted

  Scenario: Remove lock on interrupt (Ctrl+C)
    Given vdoc update is running
    And .vdoc.lock exists
    When user presses Ctrl+C
    Then SIGINT is caught
    And .vdoc.lock is deleted

  Scenario: Force override with flag
    Given .vdoc.lock exists
    When vdoc update --force is run
    Then warning shows "Overriding existing lock"
    And existing lock is replaced
    And update proceeds
```

---

## 3. Technical Context (For Coder Agent)

### 3.1 Affected Files
- `core/lock.sh` (new) - Lock management functions
- `core/scan.sh` - Integrate lock acquire/release
- `app/vdoc.sh` - Add --force flag handling

### 3.2 Implementation
```bash
#!/usr/bin/env bash
# core/lock.sh

LOCK_FILE=".vdoc.lock"
LOCK_STALE_MINUTES=10

# Create lock file with metadata
acquire_lock() {
    local force="${1:-false}"

    if [[ -f "$LOCK_FILE" ]]; then
        if [[ "$force" == "true" ]]; then
            echo "WARNING: Overriding existing lock" >&2
        else
            show_lock_error
            return 1
        fi
    fi

    # Create lock with metadata
    cat > "$LOCK_FILE" << EOF
{
  "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "pid": $$,
  "user": "${USER:-unknown}",
  "platform": "${VDOC_PLATFORM:-cli}",
  "hostname": "$(hostname)"
}
EOF

    # Set up cleanup trap
    trap cleanup_lock EXIT INT TERM

    return 0
}

# Release lock file
release_lock() {
    if [[ -f "$LOCK_FILE" ]]; then
        rm -f "$LOCK_FILE"
    fi
}

# Cleanup handler for signals
cleanup_lock() {
    release_lock
    # Re-raise signal if it was INT or TERM
    if [[ "${1:-}" == "INT" ]] || [[ "${1:-}" == "TERM" ]]; then
        trap - "$1"
        kill -"$1" $$
    fi
}

# Show error with lock details
show_lock_error() {
    local lock_data=$(cat "$LOCK_FILE")
    local started=$(echo "$lock_data" | jq -r '.started_at')
    local user=$(echo "$lock_data" | jq -r '.user')
    local pid=$(echo "$lock_data" | jq -r '.pid')

    echo "ERROR: Update already in progress" >&2
    echo "  Started: $started" >&2
    echo "  User: $user" >&2
    echo "  PID: $pid" >&2
    echo "" >&2
    echo "Use --force to override (not recommended)" >&2
}

# Check if lock is stale (for STORY-056)
is_lock_stale() {
    if [[ ! -f "$LOCK_FILE" ]]; then
        return 1
    fi

    local started=$(jq -r '.started_at' "$LOCK_FILE")
    local started_epoch=$(date -d "$started" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%SZ" "$started" +%s)
    local now_epoch=$(date +%s)
    local age_minutes=$(( (now_epoch - started_epoch) / 60 ))

    [[ $age_minutes -ge $LOCK_STALE_MINUTES ]]
}
```

### 3.3 Integration with scan.sh
```bash
# At start of update command
main() {
    if ! acquire_lock "$FORCE_FLAG"; then
        exit 1
    fi

    # ... do scan work ...

    release_lock
}
```

### 3.4 Lock File Format
```json
{
  "started_at": "2026-02-05T14:30:00Z",
  "pid": 12345,
  "user": "developer",
  "platform": "cursor",
  "hostname": "dev-macbook"
}
```

---

## 4. Notes
- Lock is advisory (can be bypassed with --force)
- PID can be used to check if process is still running
- Stale lock handling is in STORY-056
- Lock file is in project root alongside _manifest.json
