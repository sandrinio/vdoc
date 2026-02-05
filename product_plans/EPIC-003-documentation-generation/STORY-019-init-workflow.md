# STORY-019: Define Init Workflow

## Metadata
| Field | Value |
|-------|-------|
| **Status** | ✅ Complete |
| **Story Points** | 3 |
| **Priority** | P0 - Critical |
| **Parent Epic** | EPIC-003 |

---

## User Story
**As a** developer using vdoc for the first time
**I want** a clear, interactive onboarding workflow
**So that** I get well-structured documentation tailored to my project

---

## Acceptance Criteria

### AC1: Detect first-run condition
- [ ] Check if `vdocs/_manifest.json` exists
- [ ] If missing, trigger Init workflow (not Update)
- [ ] Clear messaging: "No existing documentation found. Starting fresh."

### AC2: Run scanner and parse output
- [ ] Execute `bash ./vdocs/.vdoc/scan.sh`
- [ ] Parse pipe-delimited output into structured data
- [ ] Extract: path, category, hash, docstring for each file
- [ ] Count files per category

### AC3: Propose documentation structure
- [ ] Map categories to doc pages (see mapping table)
- [ ] Always include "Project Overview"
- [ ] Present numbered proposal to user
- [ ] Show file counts per section

### AC4: Wait for user confirmation
- [ ] Do NOT proceed without explicit approval
- [ ] Allow user to:
  - Add custom sections
  - Remove proposed sections
  - Adjust scope/audience
- [ ] Support "proceed" or "adjust" responses

### AC5: Generate documentation
- [ ] Create doc pages in `vdocs/` directory
- [ ] Apply tiered description strategy (STORY-022)
- [ ] Include diagrams where appropriate (STORY-024)
- [ ] Use doc-page template (STORY-023)

### AC6: Write manifest
- [ ] Create `vdocs/_manifest.json`
- [ ] Include documentation array with all generated pages
- [ ] Include source_index with all scanned files
- [ ] Set bidirectional links (documented_in)

---

## Technical Notes

**Category → Doc Page Mapping:**
```
api_routes    → API Reference
components    → Component Library
models        → Data Model
utils         → Utilities Reference
middleware    → Middleware & Hooks
config        → Configuration Guide
services      → Services Reference
tests         → (skip - don't document tests)
other         → Include in Overview or skip
```

**Proposal Format:**
```
I've scanned your project and found 47 files across 5 categories.

Here's what I'd document:

1. **Project Overview** (always included)
   - Purpose, tech stack, getting started
   - Audience: All team members

2. **API Reference** (12 files in src/api/)
   - REST endpoints, request/response formats
   - Audience: Backend engineers

3. **Component Library** (8 files in src/components/)
   - Reusable UI components with props
   - Audience: Frontend engineers

4. **Data Model** (5 files in src/models/)
   - Database schemas and relationships
   - Audience: Backend engineers

Would you like me to proceed with this structure, or would you like to adjust it?
```

**Init Trigger Detection:**
```python
# Pseudocode for AI
if not exists("vdocs/_manifest.json"):
    run_init_workflow()
else:
    run_update_workflow()
```

---

## Definition of Done
- [ ] Init workflow documented in instructions.md
- [ ] Tested with TypeScript fixture project
- [ ] Tested with Python fixture project
- [ ] User can approve/adjust proposal
- [ ] Documentation pages generated correctly
- [ ] Manifest created with correct structure
