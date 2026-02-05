# STORY-014: Write instructions.md Source of Truth

## Metadata
| Field | Value |
|-------|-------|
| **Parent Epic** | [EPIC-002](EPIC.md) |
| **Status** | ✅ Complete |
| **Ambiguity Score** | 🟡 Medium |
| **Actor** | AI Coding Tool |
| **Complexity** | Medium (1 file, detailed content) |

---

## 1. The Spec (The Contract)

### 1.1 User Story
> As an **AI Coding Tool**,  
> I want **clear, structured instructions for vdoc workflows**,  
> So that **I can correctly generate and update documentation**.

### 1.2 Detailed Requirements
- [ ] Define vdoc identity and trigger phrases
- [ ] Document Init workflow (first run, no manifest)
- [ ] Document Update workflow (manifest exists)
- [ ] Define tiered description strategy (docstring → inferred → analyzed)
- [ ] Document manifest schema with all fields
- [ ] Define lock file logic
- [ ] Document error handling procedures
- [ ] Include diagram guidelines per doc type
- [ ] Document user-added section handling (explicit, auto, none)
- [ ] Write for multi-model compatibility (explicit steps, no assumptions)

---

## 2. The Truth (Executable Tests)

### 2.1 Acceptance Criteria (Gherkin)
```gherkin
Feature: instructions.md completeness

  Scenario: Contains identity section
    Given instructions.md exists
    Then it contains "## Identity"
    And it contains trigger phrases

  Scenario: Contains Init workflow
    Given instructions.md exists
    Then it contains "### Init Flow"
    And it describes manifest absence detection
    And it describes interactive proposal

  Scenario: Contains Update workflow
    Given instructions.md exists
    Then it contains "### Update Flow"
    And it describes hash comparison
    And it describes three-bucket sorting

  Scenario: Contains manifest schema
    Given instructions.md exists
    Then it contains "## Manifest Schema"
    And it shows JSON structure
    And it documents all fields

  Scenario: Contains error handling
    Given instructions.md exists
    Then it contains "## Error Handling"
    And it describes scan failure handling
    And it describes manifest corruption handling
```

---

## 3. Technical Context (For Coder Agent)

### 3.1 Affected Files
- `core/instructions.md` - Complete rewrite with full content

### 3.2 Document Structure
```markdown
# vdoc Instructions

## Identity
- What vdoc is
- Trigger phrases
- Version

## Workflows
### Init Flow
1. Detect manifest absence
2. Run scanner
3. Propose structure
4. User confirmation
5. Generate docs
6. Write manifest

### Update Flow
1. Run scanner
2. Compare hashes
3. Sort into buckets (new/changed/deleted)
4. Patch affected sections
5. Update manifest

## Tiered Description Strategy
- Pass A: Script-extracted (docstrings)
- Pass B: Metadata-inferred
- Pass C: Source-analyzed

## Manifest Schema
- Full JSON structure
- Field descriptions
- Bidirectional linking

## Lock File
- Check/create/delete logic
- 10-minute stale cleanup

## Documentation Taxonomy
- Doc types and diagram guidelines
- Max 7 nodes per diagram

## User-Added Sections
- Explicit paths mode
- Auto mode
- None mode

## Error Handling
- Scan failures
- Manifest corruption
- File conflicts
```

---

## 4. Notes
- Current `core/instructions.md` is a placeholder - needs full implementation
- Must be written for lowest-common-denominator AI capability
- No model-specific features (XML tags, system tokens)
- Every step must be explicit and atomic
- Validation checkpoints after critical operations
