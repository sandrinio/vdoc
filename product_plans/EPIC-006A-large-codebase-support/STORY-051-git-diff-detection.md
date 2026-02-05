# STORY-051: Implement Git Diff File Detection

## Metadata
| Field | Value |
|-------|-------|
| **Parent Epic** | [EPIC-006A](EPIC.md) |
| **Status** | Complete |
| **Ambiguity Score** | 🟢 Low |
| **Actor** | Developer / AI Tool |
| **Complexity** | Medium (git integration + edge cases) |

---

## 1. The Spec (The Contract)

### 1.1 User Story
> As a **Developer with a large codebase**,
> I want vdoc to **detect only files changed since last scan**,
> So that **updates are fast and don't re-process unchanged files**.

### 1.2 Detailed Requirements
- [ ] Read `last_commit_hash` from existing `_manifest.json`
- [ ] Run `git diff --name-only <last_commit> HEAD` to get changed files
- [ ] Include newly added files (untracked → tracked)
- [ ] Include deleted files (for removal from source_index)
- [ ] Handle renamed files (detect as delete + add)
- [ ] Fall back to full scan if last_commit_hash is null or invalid
- [ ] Fall back to full scan if git is not available
- [ ] Add `--full` flag to force full scan

---

## 2. The Truth (Executable Tests)

### 2.1 Acceptance Criteria (Gherkin)
```gherkin
Feature: Git Diff File Detection

  Scenario: Detect modified files since last scan
    Given manifest has last_commit_hash "abc123"
    And file src/api.ts was modified after "abc123"
    And file src/utils.ts was NOT modified
    When vdoc update runs
    Then only src/api.ts is scanned
    And src/utils.ts is skipped

  Scenario: Detect new files
    Given manifest has last_commit_hash "abc123"
    And file src/new-feature.ts was added after "abc123"
    When vdoc update runs
    Then src/new-feature.ts is scanned
    And it is added to source_index

  Scenario: Detect deleted files
    Given manifest has last_commit_hash "abc123"
    And file src/old-code.ts existed at "abc123"
    And src/old-code.ts was deleted
    When vdoc update runs
    Then src/old-code.ts is removed from source_index

  Scenario: Fall back on missing last_commit
    Given manifest has last_commit_hash null
    When vdoc update runs
    Then a full scan is performed
    And output contains "No previous commit found, running full scan"

  Scenario: Force full scan with flag
    Given manifest has last_commit_hash "abc123"
    When vdoc update --full runs
    Then a full scan is performed
    And all files are re-scanned

  Scenario: Handle non-git directory
    Given directory is not a git repository
    When vdoc update runs
    Then a full scan is performed
    And no error is thrown
```

---

## 3. Technical Context (For Coder Agent)

### 3.1 Affected Files
- `core/scan.sh` - Add incremental mode logic
- `core/git-utils.sh` (new) - Git helper functions

### 3.2 Implementation
```bash
#!/usr/bin/env bash
# core/git-utils.sh

# Check if we're in a git repo
is_git_repo() {
    git rev-parse --git-dir >/dev/null 2>&1
}

# Get changed files since a commit
get_changed_files() {
    local since_commit="$1"

    if [[ -z "$since_commit" ]]; then
        return 1
    fi

    # Verify the commit exists
    if ! git cat-file -t "$since_commit" >/dev/null 2>&1; then
        echo "WARNING: Commit $since_commit not found" >&2
        return 1
    fi

    # Get all changes: modified, added, deleted, renamed
    git diff --name-status "$since_commit" HEAD | while read -r status file newfile; do
        case "$status" in
            M|A) echo "changed:$file" ;;
            D)   echo "deleted:$file" ;;
            R*)  echo "deleted:$file"; echo "changed:$newfile" ;;
        esac
    done
}

# Determine scan mode
determine_scan_mode() {
    local last_commit="$1"
    local force_full="$2"

    if [[ "$force_full" == "true" ]]; then
        echo "full"
        return
    fi

    if ! is_git_repo; then
        echo "full"
        return
    fi

    if [[ -z "$last_commit" ]]; then
        echo "full"
        return
    fi

    echo "incremental"
}
```

### 3.3 Integration with scan.sh
```bash
# In main scan function
LAST_COMMIT=$(jq -r '.last_commit_hash // empty' "$MANIFEST_PATH" 2>/dev/null)
SCAN_MODE=$(determine_scan_mode "$LAST_COMMIT" "$FORCE_FULL")

if [[ "$SCAN_MODE" == "incremental" ]]; then
    echo "# mode: incremental (since $LAST_COMMIT)"
    CHANGED_FILES=$(get_changed_files "$LAST_COMMIT")
else
    echo "# mode: full"
    CHANGED_FILES=""  # Empty means scan all
fi
```

---

## 4. Notes
- Requires STORY-050 (last commit tracking) to be completed first
- Uses `git diff --name-status` to distinguish modified/added/deleted
- Renamed files are treated as delete + add for simplicity
- The actual merging of results happens in STORY-052
