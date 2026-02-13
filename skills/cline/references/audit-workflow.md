# Audit Workflow

## Step 1 — Read Current State

Read `vdocs/_manifest.json`. Load the list of documented features and their metadata.

## Step 2 — Detect Stale Docs

Run `git log --name-only --since="<last_updated>" --pretty=format:""` or use `git diff` to find all source files that changed since the last audit.

Cross-reference changed files against each doc's "Key Files" section to identify which docs are stale.

## Step 3 — Detect Coverage Gaps

Scan the codebase for significant features not covered by any doc. Look for:
- New route files / API endpoints
- New service classes or modules
- New database models / schema changes
- New configuration or infrastructure files

If you find undocumented features, propose new docs.

## Step 4 — Detect Dead Docs

Check each doc's "Key Files" section against the actual filesystem. If key files no longer exist, the doc may be dead. Flag it: "PAYMENT_PROCESSING_DOC.md references 3 files that no longer exist — remove or archive?"

## Step 5 — Check Cross-References

Read each doc's "Related Features" section. Verify that:
- Referenced doc filenames still exist
- The described coupling is still accurate (skim the relevant code)

## Step 6 — Report

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
- Update manifest: bump versions, update `last_updated`, `last_commit`
