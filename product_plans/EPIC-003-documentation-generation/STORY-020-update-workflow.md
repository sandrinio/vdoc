# STORY-020: Define Update Workflow

## Metadata
| Field | Value |
|-------|-------|
| **Status** | ✅ Complete |
| **Story Points** | 5 |
| **Priority** | P0 - Critical |
| **Parent Epic** | EPIC-003 |

---

## User Story
**As a** developer with existing vdoc documentation
**I want** to update docs when my code changes
**So that** documentation stays current without full regeneration

---

## Acceptance Criteria

### AC1: Detect update condition
- [ ] Check if `vdocs/_manifest.json` exists
- [ ] If present, trigger Update workflow (not Init)
- [ ] Load manifest into memory

### AC2: Handle lock file
- [ ] Check for `.vdoc.lock` file
- [ ] If exists and < 10 minutes old: abort with message
- [ ] If exists and > 10 minutes old: delete stale lock, proceed
- [ ] Create lock file before starting update
- [ ] Delete lock file when complete (even on error)

### AC3: Run scanner and compare hashes
- [ ] Execute `bash ./vdocs/.vdoc/scan.sh`
- [ ] For each file in scan output:
  - Look up in manifest's source_index
  - Compare current hash to stored hash
- [ ] Sort into buckets (STORY-021)

### AC4: Report changes to user
- [ ] Show counts: N modified, N new, N deleted
- [ ] List affected documentation pages
- [ ] Ask for confirmation before patching

### AC5: Patch affected sections
- [ ] For changed files: rewrite only their sections
- [ ] Preserve user edits in other sections (STORY-026)
- [ ] For new files: add to appropriate doc page
- [ ] For deleted files: flag for user review

### AC6: Update manifest
- [ ] Update hashes for changed files
- [ ] Add new files to source_index
- [ ] Remove deleted files from source_index
- [ ] Update `last_updated` timestamp
- [ ] Update `documented_in` links

---

## Technical Notes

**Lock File Format:**
```json
{
  "started_at": "2026-02-05T14:30:00Z",
  "user": "developer",
  "platform": "claude-code"
}
```

**Lock File Logic:**
```bash
# Check lock
if [ -f ".vdoc.lock" ]; then
    lock_time=$(jq -r '.started_at' .vdoc.lock)
    age_minutes=$(( ($(date +%s) - $(date -d "$lock_time" +%s)) / 60 ))
    if [ $age_minutes -lt 10 ]; then
        echo "Another update in progress. Try again later."
        exit 1
    else
        rm .vdoc.lock  # Stale lock
    fi
fi
```

**Change Report Format:**
```
Found changes since last update:
- 3 files modified
- 2 new files
- 1 file deleted

Affected documentation:
- vdocs/api-reference.md
  └─ src/api/users.ts (modified)
  └─ src/api/products.ts (modified)
- vdocs/overview.md
  └─ src/index.ts (new feature added)

Deleted file requiring review:
- src/api/deprecated.ts → mentioned in vdocs/api-reference.md

Proceed with update? [Y/n]
```

**Update vs Regenerate:**
- Update: Only modify sections for changed files
- Regenerate: Delete manifest and run Init (user must request)

---

## Definition of Done
- [ ] Update workflow documented in instructions.md
- [ ] Lock file logic prevents concurrent updates
- [ ] Hash comparison correctly identifies changes
- [ ] Only affected sections are modified
- [ ] User edits preserved (see STORY-026)
- [ ] Manifest updated correctly
- [ ] Tested with simulated file changes
