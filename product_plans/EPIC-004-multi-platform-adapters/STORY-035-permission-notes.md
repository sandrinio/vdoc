# STORY-035: Add Platform Permission Notes to Instructions

## Metadata
| Field | Value |
|-------|-------|
| **Status** | ✅ Complete |
| **Story Points** | 1 |
| **Priority** | P2 - Medium |
| **Parent Epic** | EPIC-004 |

---

## User Story
**As an** AI coding tool
**I want** platform-specific guidance for running commands
**So that** I can help users approve necessary operations

---

## Acceptance Criteria

### AC1: Universal instructions remain platform-agnostic
- [ ] Core `instructions.md` works for all platforms
- [ ] Platform-specific notes added by adapters (not hardcoded)

### AC2: Each adapter adds permission context
- [ ] Claude: No special handling needed (native bash)
- [ ] Cursor: Note to explain command before running
- [ ] Windsurf: Note about approval dialog
- [ ] Aider: Guide to use `/run` command
- [ ] Continue: Note about tool approval flow

### AC3: Safety reassurance
- [ ] State that scan.sh is read-only
- [ ] Explain it only outputs file metadata
- [ ] Note it doesn't modify any files

---

## Technical Notes

**Adapter-Injected Section:**
Each adapter appends a platform-specific section:

**Cursor:**
```markdown
## Platform Notes (Cursor)
When running shell commands:
1. Explain what the command does before executing
2. scan.sh is a read-only script that lists files and their metadata
3. It does not modify any files in your project
```

**Windsurf:**
```markdown
## Platform Notes (Windsurf)
Shell commands require approval:
- scan.sh: Safe to approve - only reads file metadata
- When Cascade asks to run a command, you'll see a confirmation dialog
```

**Aider:**
```markdown
## Platform Notes (Aider)
To run shell commands, use the /run command:
- `/run bash vdocs/.vdoc/scan.sh`
- scan.sh only reads files, it's safe to execute
```

**Continue:**
```markdown
## Platform Notes (Continue)
Tool execution requires approval:
- scan.sh is read-only and safe to approve
- You'll see an approval dialog before any command runs
```

**Implementation in Adapter:**
```bash
# In generate.sh for each platform
append_platform_notes() {
    cat >> "$OUTPUT_FILE" << 'EOF'

---

## Platform Notes (Cursor)
...
EOF
}
```

---

## Definition of Done
- [ ] Each adapter appends relevant permission notes
- [ ] Notes explain scan.sh safety
- [ ] User understands what to approve
- [ ] Instructions remain readable and helpful
