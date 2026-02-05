# STORY-027: Define Interactive Proposal Format

## Metadata
| Field | Value |
|-------|-------|
| **Status** | ✅ Complete |
| **Story Points** | 2 |
| **Priority** | P1 - High |
| **Parent Epic** | EPIC-003 |

---

## User Story
**As a** developer initializing vdoc
**I want** a clear, actionable proposal for documentation
**So that** I can quickly approve or customize the structure

---

## Acceptance Criteria

### AC1: Summary statistics
- [ ] Total files scanned
- [ ] Files per category
- [ ] Estimated documentation pages

### AC2: Proposed structure
- [ ] Numbered list of proposed doc pages
- [ ] Brief description of each
- [ ] Target audience for each
- [ ] File count per section

### AC3: Actionable options
- [ ] Clear "proceed" path
- [ ] Clear "adjust" path
- [ ] Examples of adjustments user can request

### AC4: Adjustment handling
- [ ] Add custom section
- [ ] Remove proposed section
- [ ] Change audience/scope
- [ ] Merge sections
- [ ] Split sections

---

## Technical Notes

**Full Proposal Format:**
```
╔══════════════════════════════════════════════════════════════╗
║                    vdoc Documentation Proposal                ║
╚══════════════════════════════════════════════════════════════╝

📊 Scan Summary
───────────────
• Total files scanned: 47
• Categories detected: api_routes (12), components (8), models (5),
                       utils (7), config (3), other (12)
• Estimated reading time: ~15 minutes total

📄 Proposed Documentation Structure
────────────────────────────────────

1. **Project Overview** ⭐ Always included
   Purpose, tech stack, and getting started guide
   Audience: All team members
   Covers: README.md, package.json, src/index.ts

2. **API Reference** (12 files)
   REST endpoints with request/response documentation
   Audience: Backend engineers
   Covers: src/api/**/*.ts
   Includes: 1 diagram (request flow)

3. **Component Library** (8 files)
   Reusable UI components with props and examples
   Audience: Frontend engineers
   Covers: src/components/**/*.tsx

4. **Data Model** (5 files)
   Database schemas and entity relationships
   Audience: Backend engineers
   Covers: src/models/**/*.ts
   Includes: 1-2 ER diagrams

5. **Utilities Reference** (7 files)
   Helper functions and shared utilities
   Audience: All engineers
   Covers: src/utils/**/*.ts

───────────────────────────────────────────────────────────────

🎯 Ready to Generate?

• Type "proceed" or "yes" to generate this documentation
• Type "adjust" to modify the structure
• Or tell me what you'd like to change:
  - "Add a deployment section"
  - "Remove utilities reference"
  - "Merge components and utilities"
  - "Change API audience to 'API consumers'"
```

**Adjustment Examples:**

**Add Section:**
```
User: Add a section for authentication

AI: I'll add an "Authentication & Security" section.

Looking for auth-related files...
Found:
- src/middleware/auth.ts
- src/utils/jwt.ts
- src/config/oauth.ts

I'll include these in the new section. Updated proposal:

6. **Authentication & Security** (3 files)
   Auth flows, token handling, and security middleware
   Audience: Backend engineers, Security team
   Includes: 1-2 sequence diagrams (login, token refresh)

Proceed with updated structure?
```

**Remove Section:**
```
User: Remove the utilities reference, those are internal

AI: Got it. I'll remove "Utilities Reference" from the proposal.

The 7 utility files will still be tracked in the manifest but
won't have dedicated documentation.

Updated proposal has 4 sections. Proceed?
```

**Change Audience:**
```
User: The API reference should be for external developers

AI: Updated "API Reference" audience to "External API consumers".

I'll adjust the content to:
- Include authentication requirements upfront
- Add more complete request/response examples
- Exclude internal implementation details

Proceed?
```

**Minimal Proposal (Small Projects):**
```
📊 Scan Summary: 8 files scanned

📄 Proposed Documentation
─────────────────────────

1. **Project Overview**
   Complete documentation for this small project
   Covers all 8 files in a single comprehensive guide

For small projects, I recommend a single documentation file
rather than multiple pages. Proceed?
```

---

## Definition of Done
- [ ] Proposal format documented in instructions.md
- [ ] Includes scan summary with statistics
- [ ] Clear numbered structure with details
- [ ] Actionable options presented
- [ ] Adjustment examples documented
- [ ] Small project variant defined
- [ ] Tested with various project sizes
