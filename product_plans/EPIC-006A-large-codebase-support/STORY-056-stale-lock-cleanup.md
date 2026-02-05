# STORY-056: Add Stale Lock Cleanup (10 min timeout)

## Metadata
| Field | Value |
|-------|-------|
| **Parent Epic** | [EPIC-006A](EPIC.md) |
| **Status** | Complete |
| **Ambiguity Score** | 🟢 Low |
| **Actor** | Developer |
| **Complexity** | Low (time check + cleanup logic) |

---

## 1. The Spec (The Contract)

### 1.1 User Story
> As a **Developer**,
> I want stale locks to be **automatically cleaned up**,
> So that **crashed or interrupted updates don't permanently block me**.

### 1.2 Detailed Requirements
- [ ] Check lock age before blocking
- [ ] If lock is older than 10 minutes, consider it stale
- [ ] If lock PID is not running, consider it stale (bonus check)
- [ ] Automatically remove stale locks with warning message
- [ ] Log who created the stale lock for debugging
- [ ] Make timeout configurable via environment variable
- [ ] Proceed with new lock after stale cleanup

---

## 2. The Truth (Executable Tests)

### 2.1 Acceptance Criteria (Gherkin)
```gherkin
Feature: Stale Lock Cleanup

  Scenario: Lock older than 10 minutes is stale
    Given .vdoc.lock exists
    And lock was created 15 minutes ago
    When vdoc update is attempted
    Then warning shows "Removing stale lock (15 minutes old)"
    And old lock is deleted
    And new lock is created
    And update proceeds

  Scenario: Lock younger than 10 minutes blocks
    Given .vdoc.lock exists
    And lock was created 5 minutes ago
    When vdoc update is attempted
    Then operation aborts
    And error shows "Update already in progress"

  Scenario: Lock with dead PID is stale
    Given .vdoc.lock exists
    And lock was created 3 minutes ago
    And lock PID 99999 is not running
    When vdoc update is attempted
    Then warning shows "Removing stale lock (process not running)"
    And update proceeds

  Scenario: Custom timeout via environment
    Given VDOC_LOCK_TIMEOUT_MINUTES=5
    And .vdoc.lock exists
    And lock was created 6 minutes ago
    When vdoc update is attempted
    Then lock is considered stale
    And warning shows "Removing stale lock (6 minutes old)"

  Scenario: Lock exactly at threshold
    Given .vdoc.lock exists
    And lock was created exactly 10 minutes ago
    When vdoc update is attempted
    Then lock is considered stale
    And update proceeds
```

---

## 3. Technical Context (For Coder Agent)

### 3.1 Affected Files
- `core/lock.sh` - Add stale detection and cleanup

### 3.2 Implementation
```bash
#!/usr/bin/env bash
# Addition to core/lock.sh

LOCK_STALE_MINUTES="${VDOC_LOCK_TIMEOUT_MINUTES:-10}"

# Check if a process is running
is_process_running() {
    local pid="$1"
    kill -0 "$pid" 2>/dev/null
}

# Check if lock is stale (by time or dead process)
is_lock_stale() {
    if [[ ! -f "$LOCK_FILE" ]]; then
        return 1
    fi

    local lock_data=$(cat "$LOCK_FILE")
    local started=$(echo "$lock_data" | jq -r '.started_at')
    local pid=$(echo "$lock_data" | jq -r '.pid')

    # Check if process is dead
    if [[ -n "$pid" ]] && [[ "$pid" != "null" ]]; then
        if ! is_process_running "$pid"; then
            echo "process_dead"
            return 0
        fi
    fi

    # Check if lock is too old
    local started_epoch
    # macOS date
    if date --version 2>&1 | grep -q GNU; then
        started_epoch=$(date -d "$started" +%s)
    else
        # BSD date (macOS)
        started_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$started" +%s 2>/dev/null || echo 0)
    fi

    local now_epoch=$(date +%s)
    local age_minutes=$(( (now_epoch - started_epoch) / 60 ))

    if [[ $age_minutes -ge $LOCK_STALE_MINUTES ]]; then
        echo "$age_minutes"
        return 0
    fi

    return 1
}

# Clean up stale lock with logging
cleanup_stale_lock() {
    local stale_reason=$(is_lock_stale)

    if [[ $? -eq 0 ]]; then
        local lock_data=$(cat "$LOCK_FILE")
        local user=$(echo "$lock_data" | jq -r '.user')
        local started=$(echo "$lock_data" | jq -r '.started_at')

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

# Updated acquire_lock with stale handling
acquire_lock() {
    local force="${1:-false}"

    if [[ -f "$LOCK_FILE" ]]; then
        # Try stale cleanup first
        if cleanup_stale_lock; then
            # Stale lock was removed, proceed
            :
        elif [[ "$force" == "true" ]]; then
            echo "WARNING: Overriding existing lock" >&2
            rm -f "$LOCK_FILE"
        else
            show_lock_error
            return 1
        fi
    fi

    # Create new lock
    create_lock_file

    # Set up cleanup trap
    trap 'cleanup_lock' EXIT
    trap 'cleanup_lock INT; exit 130' INT
    trap 'cleanup_lock TERM; exit 143' TERM

    return 0
}

create_lock_file() {
    cat > "$LOCK_FILE" << EOF
{
  "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "pid": $$,
  "user": "${USER:-unknown}",
  "platform": "${VDOC_PLATFORM:-cli}",
  "hostname": "$(hostname)"
}
EOF
}
```

### 3.3 Environment Variables
| Variable | Default | Description |
|----------|---------|-------------|
| `VDOC_LOCK_TIMEOUT_MINUTES` | 10 | Minutes before lock is considered stale |

---

## 4. Notes
- Two stale conditions: time exceeded OR process dead
- Dead process check only works on same machine
- Cross-platform date parsing handles both GNU and BSD date
- Stale cleanup logs original lock owner for debugging
- Default 10 minutes should cover most long scans
