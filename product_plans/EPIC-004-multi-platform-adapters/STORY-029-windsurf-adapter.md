# STORY-029: Create Windsurf Adapter

## Metadata
| Field | Value |
|-------|-------|
| **Status** | ✅ Complete |
| **Story Points** | 3 |
| **Priority** | P1 - High |
| **Parent Epic** | EPIC-004 |

---

## User Story
**As a** developer using Windsurf (Cascade)
**I want** vdoc instructions integrated into my Windsurf rules
**So that** I can generate documentation using Cascade AI

---

## Acceptance Criteria

### AC1: Adapter generates valid Windsurf rules
- [ ] Creates or appends to `.windsurfrules` in project root
- [ ] Uses Windsurf's expected format/syntax
- [ ] Does not overwrite existing rules (append vdoc section)

### AC2: Handle permission model
- [ ] Note that commands require user approval
- [ ] Include context that scan.sh is read-only and safe

### AC3: Section-based format
- [ ] Add clear `# vdoc` section marker
- [ ] Easy to identify and update on reinstall

---

## Technical Notes

**Windsurf Rules Format:**
```
# vdoc Documentation Generator
# Trigger: "generate documentation" or "vdoc"

[instructions.md content]

## Windsurf Notes
- Shell commands will prompt for approval
- scan.sh only reads files, never modifies
```

**Output Path:** `.windsurfrules`

**Append vs Overwrite:**
- Check if `.windsurfrules` exists
- If exists: replace `# vdoc` section, preserve rest
- If not exists: create new file

---

## Definition of Done
- [ ] `adapters/windsurf/generate.sh` generates valid rules
- [ ] Preserves existing rules when appending
- [ ] Cascade recognizes vdoc commands
- [ ] Tested manually in Windsurf IDE
