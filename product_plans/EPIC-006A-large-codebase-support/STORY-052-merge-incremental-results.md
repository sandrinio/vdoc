# STORY-052: Merge Incremental Scan Results with Cache

## Metadata
| Field | Value |
|-------|-------|
| **Parent Epic** | [EPIC-006A](EPIC.md) |
| **Status** | Complete |
| **Ambiguity Score** | 🟢 Low |
| **Actor** | Developer / AI Tool |
| **Complexity** | Medium (merge logic + edge cases) |

---

## 1. The Spec (The Contract)

### 1.1 User Story
> As a **Developer**,
> I want incremental scan results to **merge with my existing manifest**,
> So that **unchanged files retain their metadata while changed files are updated**.

### 1.2 Detailed Requirements
- [ ] Load existing `source_index` from `_manifest.json`
- [ ] For changed files: replace entry with new scan data
- [ ] For deleted files: remove entry from source_index
- [ ] For unchanged files: preserve existing entry exactly
- [ ] Update `documentation[].covers` arrays if source files were removed
- [ ] **Warn** if a doc page ends up with empty `covers` array (orphaned doc)
- [ ] Preserve user-added metadata (AI reasons through field changes)
- [ ] On merge conflict: **prompt human** to decide (interactive mode)
- [ ] Write merged result back to manifest
- [ ] Log summary: "Updated X files, removed Y files, preserved Z files"

### 1.3 Design Decisions (Resolved)

| Decision | Resolution | Rationale |
|----------|------------|-----------|
| **Empty doc pages** | Warn, don't delete | User may want to keep placeholder docs |
| **Partial write failure** | Accept risk | Simplicity over atomicity; manifest is recoverable |
| **Custom field detection** | AI reasons through | No fixed schema; tool analyzes context to preserve user intent |
| **Merge conflicts** | Human in the loop | Changed file + changed metadata = prompt user to decide |

---

## 2. The Truth (Executable Tests)

### 2.1 Acceptance Criteria (Gherkin)
```gherkin
Feature: Merge Incremental Results

  Scenario: Update changed file while preserving unchanged
    Given source_index has entries for file_a.ts and file_b.ts
    And file_a.ts has hash "old_hash_a"
    And file_b.ts has hash "old_hash_b"
    When incremental scan detects file_a.ts changed
    And file_a.ts new hash is "new_hash_a"
    Then source_index.file_a.ts.hash is "new_hash_a"
    And source_index.file_b.ts.hash is "old_hash_b" (unchanged)

  Scenario: Remove deleted file from source_index
    Given source_index has entry for deleted_file.ts
    When incremental scan reports deleted_file.ts as deleted
    Then source_index does NOT contain deleted_file.ts

  Scenario: Update documentation covers array on deletion
    Given documentation entry covers ["deleted.ts", "kept.ts"]
    When deleted.ts is removed from source_index
    Then documentation entry covers ["kept.ts"]

  Scenario: Preserve custom user metadata
    Given source_index.file.ts has custom field "notes": "important"
    When incremental scan updates file.ts
    Then source_index.file.ts still has "notes": "important"

  Scenario: Add new file to source_index
    Given source_index does NOT have new_file.ts
    When incremental scan includes new_file.ts
    Then source_index contains new_file.ts with full metadata

  Scenario: Warn on orphaned documentation
    Given documentation "api.md" covers only ["deleted.ts"]
    When deleted.ts is removed from source_index
    Then documentation "api.md" covers []
    And warning is logged: "api.md now covers 0 files"

  Scenario: Merge conflict prompts user
    Given source_index.file.ts has "description": "Old user note"
    And file.ts content changed (new hash)
    And new scan has "description": "Auto-generated desc"
    When merge is attempted in interactive mode
    Then user is prompted: "file.ts description changed. Keep existing or use new?"
    And user choice is applied

  Scenario: AI reasons through custom fields
    Given source_index.file.ts has unknown field "team_owner": "platform"
    And new scan data does not include "team_owner"
    When merge is performed
    Then AI preserves "team_owner" field (not a scan field)
    And merged entry contains "team_owner": "platform"
```

---

## 3. Technical Context (For Coder Agent)

### 3.1 Affected Files
- `core/manifest.sh` - Add merge function
- `core/scan.sh` - Call merge instead of overwrite

### 3.2 Implementation
```bash
# Merge incremental results with existing manifest
# Uses jq for JSON manipulation
merge_source_index() {
    local manifest_path="$1"
    local scan_output="$2"  # Temp file with new scan data
    local deleted_files="$3" # Newline-separated list

    # Create jq filter for merge
    local jq_filter='
    # Load new scan data
    ($new_data | from_entries) as $updates |
    # Load deleted files
    ($deleted | split("\n") | map(select(. != ""))) as $to_delete |

    # Merge source_index
    .source_index = (
        .source_index
        | to_entries
        | map(select(.key | IN($to_delete[]) | not))  # Remove deleted
        | from_entries
        | . * $updates  # Merge updates (preserves existing keys)
    ) |

    # Clean up documentation.covers arrays
    .documentation = [
        .documentation[] |
        .covers = [.covers[] | select(IN($to_delete[]) | not)]
    ]
    '

    jq --slurpfile new_data "$scan_output" \
       --arg deleted "$deleted_files" \
       "$jq_filter" "$manifest_path"
}
```

### 3.3 Merge Strategy
| Scenario | Action |
|----------|--------|
| File in scan, not in manifest | Add to source_index |
| File in scan and manifest | Update entry, preserve custom fields |
| File deleted, was in manifest | Remove from source_index |
| File not in scan, in manifest | Keep existing entry |

### 3.4 Custom Field Preservation
```bash
# When updating an entry, preserve unknown keys
# Existing: { "hash": "old", "notes": "user added" }
# New scan: { "hash": "new", "category": "api" }
# Result:   { "hash": "new", "category": "api", "notes": "user added" }
```

---

## 4. Notes
- Requires STORY-051 (git diff detection) to identify changed/deleted files
- Uses jq for safe JSON manipulation
- Falls back to full overwrite if merge fails
- Consider adding `--no-preserve` flag to discard custom fields

## 5. Design Decision Log

### Orphaned Docs → Warn
When all source files covered by a doc are deleted, the doc becomes "orphaned". Rather than auto-deleting (risky) or silently ignoring (confusing), we **warn** the user so they can decide to remove or repurpose the doc.

### No Atomic Writes
We accept the risk of partial writes for simplicity. The manifest can be regenerated from a full scan if corrupted. Adding temp-file + atomic-rename adds complexity without significant benefit for this use case.

### AI-Driven Field Reasoning
Rather than maintaining a hardcoded list of "system fields" vs "user fields", the AI tool should reason about field semantics:
- Fields matching scan output schema (`hash`, `category`, `description`, `documented_in`) → update
- Unknown fields (`notes`, `team_owner`, `priority`) → preserve

### Human-in-the-Loop Conflicts
When both the source file AND its metadata changed, the merge is ambiguous. In interactive mode, prompt the user. In CI/batch mode, prefer the new scan data with a warning.
