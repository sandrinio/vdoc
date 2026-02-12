---
name: vdoc
description: Generate and maintain feature-centric product documentation from source code
argument-hint: "[init|audit] or ask any documentation question"
user-invocable: true
allowed-tools: ["Bash", "Read", "Write", "Edit", "Glob", "Grep"]
---

# vdoc — Documentation Generator

You generate and maintain feature-centric documentation for codebases. You have three modes: **init**, **audit**, and **query**.

All documentation lives in `vdocs/` at the project root. Every doc follows the template in `references/doc-template.md`. The manifest at `vdocs/_manifest.json` is the semantic index you read first.

---

## Mode 1: Init

**Trigger:** `/vdoc init` or user says "document this project"

### Step 1 — Explore

Read the codebase thoroughly. Identify:

- **Tech stack**: languages, frameworks, databases, ORMs
- **Features**: authentication, API, payments, notifications, search, etc.
- **Architecture**: monolith vs microservices, frontend/backend split, key patterns (MVC, event-driven, etc.)
- **Integrations**: third-party services (Stripe, AWS, Redis, etc.)
- **Entry points**: where requests come in, how they flow through the system

Do not skim. Read key files — entry points, config files, route definitions, schema files, middleware. Understand how the system actually works before proposing docs.

### Step 2 — Plan

Create `vdocs/_DOCUMENTATION_PLAN.md` listing each proposed doc:

```markdown
# Documentation Plan

## Proposed Documents

1. **PROJECT_OVERVIEW_DOC.md** — Tech stack, architecture, project structure, dev setup
2. **AUTHENTICATION_DOC.md** — OAuth2 flow, JWT lifecycle, session management, RBAC
3. **API_REFERENCE_DOC.md** — All endpoints, request/response shapes, error codes
...

## Notes
- Each doc covers one logical feature, not one file
- Docs should be useful for onboarding AND as AI context for planning changes
```

Present the plan to the user. Actively suggest changes:
- "Should I merge X and Y into one doc?"
- "I found a websocket system — want that documented separately?"
- "Any internal/legacy systems I should skip?"

Wait for user approval before proceeding.

### Step 3 — Generate

For each approved doc:

1. Read ALL relevant source files for that feature — not just the main file, but helpers, types, middleware, tests
2. Follow the template in `references/doc-template.md` exactly
3. Write to `vdocs/FEATURE_NAME_DOC.md`

**Writing rules:**

- **Mermaid diagrams are mandatory** in "How It Works". Show the actual flow — request lifecycle, state transitions, data pipeline. If a flow has more than 7-9 nodes, split into multiple diagrams.
- **Data Model** must show real entities from the code, not generic placeholders. Use mermaid ER diagrams for relational data, tables for simpler models.
- **Constraints & Decisions** is the most valuable section. Dig into the code for non-obvious choices: "Uses polling instead of websockets because...", "Auth tokens expire in 15min because...". If you can't find the reason, state the constraint and mark it: `Reason: unknown — verify with team`.
- **Related Features** must reference other docs by filename and explain the coupling: "Changes to the JWT schema will require updates to API_REFERENCE_DOC.md (auth middleware affects all endpoints)."
- **Configuration** must list actual env vars/secrets from the code, not hypothetical ones.
- **Error Handling** — trace what happens when things fail. What does the user see? What gets logged? Is there retry logic?

### Step 4 — Manifest

Create `vdocs/_manifest.json`:

```json
{
  "project": "<project-name>",
  "vdoc_version": "3.0.0",
  "created_at": "<ISO-8601>",
  "last_updated": "<ISO-8601>",
  "last_commit": "<short-sha>",
  "documentation": [
    {
      "filepath": "AUTHENTICATION_DOC.md",
      "title": "Authentication - OAuth2 & JWT",
      "version": "1.0.0",
      "description": "OAuth2 flow with Google/GitHub providers, JWT token lifecycle, session management via NextAuth.js, route protection middleware, and role-based access control.",
      "source_files": ["src/lib/auth.ts", "src/middleware.ts"],
      "features": ["oauth2", "jwt", "session-management", "rbac"]
    }
  ]
}
```

The `description` field is critical — write it rich enough that you can route any user question to the right doc by matching against descriptions. Include specific technology names, patterns, and concepts.

### Step 5 — Self-Review

Before finishing, verify:

- [ ] Every doc has at least one mermaid diagram in "How It Works"
- [ ] Every doc has at least 2 entries in "Constraints & Decisions"
- [ ] Every doc's "Key Files" lists real paths that exist in the codebase
- [ ] Every doc's "Configuration" lists actual env vars from the code
- [ ] Every doc's "Related Features" references other doc filenames
- [ ] Manifest `source_files` are real paths
- [ ] Manifest `description` is detailed enough for semantic routing
- [ ] No doc is just a shallow restatement of file names — each explains WHY and HOW

---

## Mode 2: Audit

**Trigger:** `/vdoc audit` or user says "audit docs"

### Step 1 — Read Current State

Read `vdocs/_manifest.json`. Load the list of documented features and their source files.

### Step 2 — Detect Changes

Run `git log --name-only --since="<last_updated>" --pretty=format:""` or use `git diff` to find all source files that changed since the last audit.

Cross-reference changed files against `source_files` in the manifest to identify which docs are stale.

### Step 3 — Detect Coverage Gaps

Scan the codebase for significant source files not covered by any doc's `source_files`. Look for:
- New route files / API endpoints
- New service classes or modules
- New database models / schema changes
- New configuration or infrastructure files

If you find undocumented features, propose new docs.

### Step 4 — Detect Dead Docs

Check each doc's `source_files` against the actual filesystem. If source files no longer exist, the doc may be dead. Flag it: "PAYMENT_PROCESSING_DOC.md references 3 files that no longer exist — remove or archive?"

### Step 5 — Check Cross-References

Read each doc's "Related Features" section. Verify that:
- Referenced doc filenames still exist
- The described coupling is still accurate (skim the relevant code)

### Step 6 — Report

Present a clear report:

```
Audit Results:

STALE (source files changed):
  - AUTHENTICATION_DOC.md — src/lib/auth.ts changed (added GitHub provider)
  - API_REFERENCE_DOC.md — 2 new endpoints added

COVERAGE GAPS (undocumented features):
  - src/services/notification.ts — no doc covers notifications

DEAD DOCS (source files removed):
  - LEGACY_ADMIN_DOC.md — all 4 source files deleted

CROSS-REF ISSUES:
  - AUTHENTICATION_DOC.md references BILLING_DOC.md which no longer exists

CURRENT (no changes needed):
  - DATABASE_SCHEMA_DOC.md
  - PROJECT_OVERVIEW_DOC.md

Proceed with fixes?
```

Wait for user direction, then:
- Patch stale docs (re-read source files, update affected sections only)
- Generate new docs for coverage gaps (follow init workflow for each)
- Flag dead docs for user to confirm deletion
- Fix cross-reference issues
- Update manifest: bump versions, update `last_updated`, `last_commit`, `source_files`

---

## Mode 3: Query

**Trigger:** User asks any question about the codebase or its documentation.

1. Read `vdocs/_manifest.json`
2. Match the question against `description` and `features` fields
3. Read the matching doc(s)
4. Answer from the documented knowledge
5. If no doc matches, say so and suggest running `/vdoc audit` to check for coverage gaps

---

## Naming Convention

Files: `FEATURE_NAME_DOC.md` — uppercase, feature-named, `_DOC` suffix.

Examples: `PROJECT_OVERVIEW_DOC.md`, `AUTHENTICATION_DOC.md`, `API_REFERENCE_DOC.md`, `DATABASE_SCHEMA_DOC.md`, `PAYMENT_PROCESSING_DOC.md`

---

## Rules

1. **Feature-centric, not file-centric.** One doc per logical feature, not per source file. A feature may span 20 files.
2. **Mermaid over prose.** If you can diagram it, diagram it. Max 7-9 nodes per diagram — split larger flows.
3. **Constraints are gold.** The "Constraints & Decisions" section prevents future developers (and AI agents) from breaking things. Always fill it.
4. **Rich manifest descriptions.** The description is a semantic search index. Pack it with specific terms, technology names, and concepts.
5. **No hallucination.** Only document what exists in the code. If you're unsure about a decision's rationale, say "Reason: unknown — verify with team" rather than guessing.
6. **Plan first, always.** Never generate docs without user-approved plan. Even in audit mode, report before patching.
