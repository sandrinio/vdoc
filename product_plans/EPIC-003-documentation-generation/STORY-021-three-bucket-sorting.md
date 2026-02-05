# STORY-021: Implement Three-Bucket File Sorting

## Metadata
| Field | Value |
|-------|-------|
| **Status** | ✅ Complete |
| **Story Points** | 2 |
| **Priority** | P1 - High |
| **Parent Epic** | EPIC-003 |

---

## User Story
**As an** AI documentation tool
**I want** to categorize files by their change status
**So that** I can efficiently update only what's needed

---

## Acceptance Criteria

### AC1: Identify NEW files
- [ ] File exists in scan output
- [ ] File does NOT exist in manifest source_index
- [ ] Action: Add to appropriate doc page

### AC2: Identify CHANGED files
- [ ] File exists in both scan output and manifest
- [ ] Hash in scan differs from hash in manifest
- [ ] Action: Update sections that reference this file

### AC3: Identify DELETED files
- [ ] File exists in manifest source_index
- [ ] File does NOT exist in scan output
- [ ] Action: Flag for user review, don't auto-delete prose

### AC4: Identify UNCHANGED files
- [ ] File exists in both scan output and manifest
- [ ] Hash matches exactly
- [ ] Action: Skip (no update needed)

---

## Technical Notes

**Sorting Algorithm (Pseudocode):**
```python
def sort_files(scan_output, manifest):
    scan_files = {f.path: f for f in scan_output}
    manifest_files = manifest.source_index

    new_files = []
    changed_files = []
    deleted_files = []
    unchanged_files = []

    # Check scan files against manifest
    for path, scan_file in scan_files.items():
        if path not in manifest_files:
            new_files.append(scan_file)
        elif scan_file.hash != manifest_files[path].hash:
            changed_files.append(scan_file)
        else:
            unchanged_files.append(scan_file)

    # Check manifest files not in scan (deleted)
    for path in manifest_files:
        if path not in scan_files:
            deleted_files.append(manifest_files[path])

    return {
        'new': new_files,
        'changed': changed_files,
        'deleted': deleted_files,
        'unchanged': unchanged_files
    }
```

**Priority Order for Processing:**
1. **Changed** - Most important, update existing docs
2. **Deleted** - Flag for review, may need prose cleanup
3. **New** - Add to docs, may need new sections
4. **Unchanged** - Skip entirely

**Example Output:**
```
Bucket Summary:
- New: 2 files
  • src/api/orders.ts (api_routes)
  • src/utils/currency.ts (utils)

- Changed: 3 files
  • src/api/users.ts (hash: a3f2→b7c1)
  • src/models/User.ts (hash: d4e5→f8g9)
  • src/index.ts (hash: h0i1→j2k3)

- Deleted: 1 file
  • src/api/legacy.ts (was documented in api-reference.md)

- Unchanged: 41 files (skipped)
```

---

## Definition of Done
- [ ] Sorting logic documented in instructions.md
- [ ] All four buckets correctly identified
- [ ] Edge cases handled (empty manifest, empty scan)
- [ ] Clear reporting of bucket contents
- [ ] Tested with various change scenarios
