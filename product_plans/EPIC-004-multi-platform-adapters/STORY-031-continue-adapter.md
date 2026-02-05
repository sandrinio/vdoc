# STORY-031: Create Continue Adapter

## Metadata
| Field | Value |
|-------|-------|
| **Status** | ✅ Complete |
| **Story Points** | 3 |
| **Priority** | P1 - High |
| **Parent Epic** | EPIC-004 |

---

## User Story
**As a** developer using Continue (VS Code extension)
**I want** vdoc instructions integrated into my Continue config
**So that** I can generate documentation using Continue's AI

---

## Acceptance Criteria

### AC1: Adapter generates valid Continue config
- [ ] Creates/updates `.continue/config.json` or equivalent
- [ ] Custom slash command or context provider for vdoc
- [ ] Instructions available to Continue's AI

### AC2: Handle tool approval model
- [ ] Include context for Continue's approval flow
- [ ] Note that scan.sh is safe to approve

### AC3: Slash command integration
- [ ] `/vdoc` command triggers documentation workflow
- [ ] Or use Continue's custom prompts feature

---

## Technical Notes

**Continue Config Structure:**
```
.continue/
├── config.json          # Main configuration
├── prompts/             # Custom prompts
│   └── vdoc.md         # vdoc-specific prompt
└── context-providers/   # Custom context
```

**Config.json Addition:**
```json
{
  "customCommands": [
    {
      "name": "vdoc",
      "description": "Generate documentation for this project",
      "prompt": "Generate documentation following the vdoc instructions..."
    }
  ],
  "contextProviders": [
    {
      "name": "vdoc-instructions",
      "params": {
        "file": "vdocs/.vdoc/instructions.md"
      }
    }
  ]
}
```

**Output Paths:**
- `.continue/config.json` (merge with existing)
- `.continue/prompts/vdoc.md`

---

## Definition of Done
- [ ] `adapters/continue/generate.sh` generates valid config
- [ ] Continue loads vdoc customizations
- [ ] `/vdoc` or equivalent command works
- [ ] Tested manually in VS Code with Continue
