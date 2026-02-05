# STORY-028: Create Cursor Adapter

## Metadata
| Field | Value |
|-------|-------|
| **Status** | ✅ Complete |
| **Story Points** | 3 |
| **Priority** | P1 - High |
| **Parent Epic** | EPIC-004 |

---

## User Story
**As a** developer using Cursor
**I want** vdoc instructions integrated into my Cursor rules
**So that** I can generate documentation using Cursor's AI assistant

---

## Acceptance Criteria

### AC1: Adapter generates valid Cursor rules file
- [ ] Creates `.cursor/rules/vdoc.md` in project root
- [ ] Cursor rules format with clear section headers
- [ ] Instructions content included verbatim

### AC2: Handle permission model
- [ ] Include note about scan.sh being read-only before shell commands
- [ ] Explain what the scanner does to help user approve

### AC3: Reuse instructions.md source
- [ ] Find instructions from `./vdocs/.vdoc/instructions.md` or source repo
- [ ] Add Cursor-specific header/wrapper if needed

---

## Technical Notes

**Cursor Rules Format:**
```markdown
# vdoc Documentation Generator

> Trigger: /vdoc or "generate documentation"

[instructions.md content here]

## Cursor-Specific Notes
- When running bash commands, explain what they do first
- The scan.sh script is read-only and safe to execute
```

**Output Path:** `.cursor/rules/vdoc.md`

**Implementation Pattern:** Follow Claude adapter structure in `adapters/claude/generate.sh`

---

## Definition of Done
- [ ] `adapters/cursor/generate.sh` generates valid rules file
- [ ] Cursor recognizes and loads the rules
- [ ] scan.sh can be invoked from Cursor chat
- [ ] Tested manually in Cursor IDE
