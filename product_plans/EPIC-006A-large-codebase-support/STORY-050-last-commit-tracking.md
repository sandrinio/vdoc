# STORY-050: Track Last Scan Commit in Manifest

## Metadata
| Field | Value |
|-------|-------|
| **Parent Epic** | [EPIC-006A](EPIC.md) |
| **Status** | Complete |
| **Ambiguity Score** | 🟢 Low |
| **Actor** | Developer / AI Tool |
| **Complexity** | Low (schema extension + 1 function) |

---

## 1. The Spec (The Contract)

### 1.1 User Story
> As a **Developer**,
> I want the manifest to **track which git commit was last scanned**,
> So that **incremental scans know where to diff from**.

### 1.2 Detailed Requirements
- [ ] Add `last_commit_hash` field to `_manifest.json` schema
- [ ] Add `last_scan_mode` field ("full" | "incremental")
- [ ] Add `scanned_files_count` and `changed_files_count` fields
- [ ] Capture current HEAD commit hash after successful scan
- [ ] Handle non-git directories gracefully (set to null)
- [ ] Update manifest write function to include new fields

---

## 2. The Truth (Executable Tests)

### 2.1 Acceptance Criteria (Gherkin)
```gherkin
Feature: Last Commit Tracking

  Scenario: Record commit hash after full scan in git repo
    Given a git repository with commits
    And HEAD is at commit "abc123"
    When vdoc scan completes successfully
    Then _manifest.json contains "last_commit_hash": "abc123"
    And _manifest.json contains "last_scan_mode": "full"

  Scenario: Handle non-git directory
    Given a directory that is not a git repo
    When vdoc scan completes successfully
    Then _manifest.json contains "last_commit_hash": null
    And _manifest.json contains "last_scan_mode": "full"

  Scenario: Track file counts
    Given a project with 100 source files
    When vdoc scan completes
    Then _manifest.json contains "scanned_files_count": 100
```

---

## 3. Technical Context (For Coder Agent)

### 3.1 Affected Files
- `core/scan.sh` - Add git commit capture
- `core/manifest.sh` - Update schema and write function

### 3.2 Implementation
```bash
# Get current git HEAD (returns empty if not a git repo)
get_current_commit() {
    git rev-parse HEAD 2>/dev/null || echo ""
}

# After scan completes, before writing manifest:
LAST_COMMIT=$(get_current_commit)
SCAN_MODE="full"  # Will be "incremental" in STORY-052

# Add to manifest JSON output
"last_commit_hash": ${LAST_COMMIT:-null},
"last_scan_mode": "$SCAN_MODE",
"scanned_files_count": $FILE_COUNT,
"changed_files_count": $CHANGED_COUNT
```

### 3.3 Schema Extension
```json
{
  "last_commit_hash": "string | null",
  "last_scan_mode": "full | incremental",
  "scanned_files_count": "number",
  "changed_files_count": "number"
}
```

---

## 4. Notes
- This story is a prerequisite for STORY-051 (git diff detection)
- Commit hash should be full 40-char SHA, not abbreviated
- Non-git directories should work without errors
