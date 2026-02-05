# STORY-022: Implement Tiered Description Strategy

## Metadata
| Field | Value |
|-------|-------|
| **Status** | ✅ Complete |
| **Story Points** | 3 |
| **Priority** | P1 - High |
| **Parent Epic** | EPIC-003 |

---

## User Story
**As an** AI documentation tool
**I want** a cost-efficient strategy for describing files
**So that** I minimize token usage while maintaining quality

---

## Acceptance Criteria

### AC1: Pass A - Script-Extracted (Zero Tokens)
- [ ] Use docstring from scanner output directly
- [ ] No additional AI processing needed
- [ ] Target: 40-60% of files covered
- [ ] Example: `src/api/users.ts | ... | User CRUD operations`

### AC2: Pass B - Metadata-Inferred (Minimal Tokens)
- [ ] Derive description from available metadata:
  - File name: `userController.ts` → "User controller"
  - Category: `api_routes` → "API endpoint for..."
  - Directory: `src/auth/` → "Authentication-related"
- [ ] Use pattern matching, not file reading
- [ ] Target: 25-40% of files

### AC3: Pass C - Source-Analyzed (Full Read)
- [ ] Only when Pass A and B insufficient
- [ ] Read actual source file
- [ ] AI generates summary
- [ ] Target: 10-20% of files max
- [ ] Log when this pass is used

### AC4: Track description source
- [ ] Record in manifest: `description_source: "docstring" | "inferred" | "analyzed"`
- [ ] Enables metrics on coverage quality
- [ ] Helps identify files needing better docstrings

---

## Technical Notes

**Decision Tree:**
```
For each file:
  1. Does scan output have docstring?
     → Yes: Use it (Pass A) ✓
     → No: Continue to Pass B

  2. Can we infer from metadata?
     → File name meaningful? Use it
     → Category clear? Add context
     → Directory suggests purpose? Use it
     → If any work: (Pass B) ✓
     → No: Continue to Pass C

  3. Read source and analyze (Pass C)
     → Generate 1-2 sentence summary
     → Mark as "analyzed" in manifest
```

**Pass B Inference Rules:**
```
File Name Patterns:
- *Controller.* → "Controller for [name]"
- *Service.* → "Service handling [name]"
- *Model.* → "Data model for [name]"
- *Utils.* / *Helpers.* → "Utility functions for [name]"
- *Config.* → "Configuration for [name]"
- index.* → "Entry point for [parent directory]"
- main.* → "Main application entry"

Category Context:
- api_routes → "API endpoint"
- components → "UI component"
- models → "Data model"
- middleware → "Request middleware"
- utils → "Utility module"
```

**Example Descriptions:**
```
Pass A (from docstring):
  "User CRUD operations and profile management"

Pass B (inferred):
  File: src/services/PaymentService.ts
  Category: services
  Result: "Payment service handling payment processing"

Pass C (analyzed):
  File: src/utils/helpers.ts
  [AI reads file, finds date formatting functions]
  Result: "Utility functions for date formatting and timezone handling"
```

**Token Usage Reporting:**
```
Description Strategy Summary:
- Pass A (docstring): 28 files (60%) - 0 tokens
- Pass B (inferred): 14 files (30%) - ~100 tokens
- Pass C (analyzed): 5 files (10%) - ~2,500 tokens
Total: 47 files, ~2,600 tokens for descriptions
```

---

## Definition of Done
- [ ] Three-pass strategy documented in instructions.md
- [ ] Pass A extracts docstrings correctly
- [ ] Pass B inference rules comprehensive
- [ ] Pass C used sparingly and logged
- [ ] `description_source` tracked in manifest
- [ ] Tested with projects having varied docstring coverage
