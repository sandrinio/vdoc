# STORY-026: Add Edit Preservation During Updates

## Metadata
| Field | Value |
|-------|-------|
| **Status** | ✅ Complete |
| **Story Points** | 3 |
| **Priority** | P0 - Critical |
| **Parent Epic** | EPIC-003 |

---

## User Story
**As a** developer who customizes generated documentation
**I want** my manual edits preserved during updates
**So that** I don't lose custom explanations and examples

---

## Acceptance Criteria

### AC1: Section-level updates only
- [ ] Only modify sections for files that changed
- [ ] Leave other sections untouched
- [ ] Use section markers to identify boundaries

### AC2: Preserve user additions
- [ ] Custom examples added by user: preserved
- [ ] Additional explanations: preserved
- [ ] User-added subsections: preserved
- [ ] Only regenerate the file-specific content

### AC3: Detect user modifications
- [ ] Compare generated content to current file
- [ ] If user modified a section, flag for review
- [ ] Don't blindly overwrite user changes

### AC4: Conflict resolution
- [ ] When source AND docs both changed: present conflict
- [ ] Show diff of what would change
- [ ] Let user choose: keep theirs, take generated, or merge

---

## Technical Notes

**Section Markers Enable Precision:**
```markdown
## User API

<!-- vdoc:section src/api/users.ts -->

This section documents the user API endpoints.

### GET /users

Returns a list of all users.

<!-- vdoc:end-section -->

<!-- vdoc:user-content -->

### Custom Examples

Here are some examples our team uses frequently:

```bash
curl -X GET /api/users?limit=10
```

<!-- vdoc:end-user-content -->
```

**Update Logic:**
```python
def update_section(doc_file, source_file, new_content):
    # Read current documentation
    current_doc = read_file(doc_file)

    # Find section for this source file
    section_start = find_marker(f"vdoc:section {source_file}")
    section_end = find_marker("vdoc:end-section", after=section_start)

    # Check if user modified the section
    original_hash = manifest.get_doc_section_hash(doc_file, source_file)
    current_hash = hash(current_doc[section_start:section_end])

    if original_hash != current_hash:
        # User modified this section
        return show_conflict(current_doc, new_content)

    # Safe to replace - user didn't modify
    return replace_section(current_doc, section_start, section_end, new_content)
```

**Conflict Presentation:**
```
⚠️ Conflict detected in vdocs/api-reference.md

The section for src/api/users.ts was modified both:
- In source code (users.ts changed)
- In documentation (you edited the docs)

Current documentation:
│ ### GET /users
│ Returns active users only (filtered by status).
│ Added: Custom rate limiting note

Generated from new source:
│ ### GET /users
│ Returns all users with pagination support.
│ New: Now includes deleted_at field

Options:
1. Keep your edits (ignore source changes)
2. Take generated (lose your edits)
3. Show me both so I can merge manually
```

**Preservation Strategies:**

1. **Additive Content** - User adds content after vdoc section
   - vdoc regenerates its section
   - User content after `vdoc:end-section` untouched

2. **Modified Content** - User edits within vdoc section
   - Detect via hash comparison
   - Flag for review, don't auto-overwrite

3. **User Sections** - Marked with `vdoc:user-content`
   - Never touched by vdoc
   - User owns entirely

**Manifest Tracking:**
```json
{
  "source_index": {
    "src/api/users.ts": {
      "hash": "abc123",
      "documented_in": ["vdocs/api-reference.md"],
      "doc_section_hash": "def456"  // Hash of generated section
    }
  }
}
```

---

## Definition of Done
- [ ] Section markers documented and working
- [ ] Only changed sections are regenerated
- [ ] User additions outside sections preserved
- [ ] User modifications within sections detected
- [ ] Conflict resolution flow implemented
- [ ] `doc_section_hash` tracked in manifest
- [ ] Tested with real edit scenarios
