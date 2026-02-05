# STORY-030: Create Aider Adapter

## Metadata
| Field | Value |
|-------|-------|
| **Status** | ✅ Complete |
| **Story Points** | 3 |
| **Priority** | P1 - High |
| **Parent Epic** | EPIC-004 |

---

## User Story
**As a** developer using Aider
**I want** vdoc conventions loaded into my Aider config
**So that** I can generate documentation using Aider's AI

---

## Acceptance Criteria

### AC1: Adapter generates valid Aider config
- [ ] Creates `.aider.conf.yml` with conventions
- [ ] Or uses Aider's conventions file format
- [ ] Instructions embedded or referenced

### AC2: Handle command execution model
- [ ] Guide AI to suggest `/run` command for scan.sh
- [ ] Include context for Aider's explicit execution model

### AC3: Convention integration
- [ ] Aider recognizes vdoc-related prompts
- [ ] Can reference scan output from conversations

---

## Technical Notes

**Aider Config Options:**
1. `.aider.conf.yml` - Main config file
2. Convention in chat context via `--read` flag
3. Custom prompts file

**Recommended Approach:**
```yaml
# .aider.conf.yml
read:
  - vdocs/.vdoc/instructions.md

# Or create .aider/conventions/vdoc.md
```

**Alternative: Conventions File**
```markdown
# vdocs/.vdoc/aider-conventions.md
When asked to generate documentation:
1. Run: /run bash vdocs/.vdoc/scan.sh
2. Parse the output
3. Follow the instructions in vdocs/.vdoc/instructions.md
```

**Output Path:** `.aider.conf.yml` or `.aider/conventions/vdoc.md`

---

## Definition of Done
- [ ] `adapters/aider/generate.sh` generates valid config
- [ ] Aider loads vdoc conventions on startup
- [ ] `/run` command works for scan.sh
- [ ] Tested manually with Aider CLI
