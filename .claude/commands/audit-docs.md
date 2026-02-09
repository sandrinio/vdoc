# Docs Synchronizer

Analyze the git diff to determine if code changes require corresponding updates to `_manifest.json` or feature documentation.

## Instructions

1. **Analyze Diff:** Run `git diff HEAD` and focus on:
   - `app/api/`
   - `app/core/`
   - `app/workflows/`
   - `app/db/` or database-related files

2. **Evaluate Impact (LLM Decision):**

   **Low Impact (Ignore):**
   - Refactoring, variable renames
   - CSS/UI tweaks
   - Internal helper functions
   - Comments and docstrings only

   **High Impact (Action Required):**
   - New/Modified API Endpoints
   - Database Schema changes
   - Changes to core business logic flow
   - New external dependencies (new n8n hooks, third-party services)

3. **Cross-Check Manifest:**
   - Read `product_documentation/_manifest.json`
   - Does the modified feature exist in `_manifest.json`?
   - If NO (and High Impact) → Prompt: "New feature detected. Add to Manifest?"
   - If YES (and High Impact) → Prompt: "Core logic changed. Update [FEATURE]_DOC.md?"

## Output Format

Provide a checklist-style audit report:

```
📋 **Docs Audit:**
- [x] **Manifest:** Up to date.
- [ ] **Feature Docs:** ⚠️ `api/payments` changed but `PAYMENTS_DOC.md` is old. Update? (y/n)
```

## Rules

- Always check the manifest first before suggesting new documentation
- Group related changes together in your analysis
- Be specific about which files need updates
- Use the AskUserQuestion tool to get user confirmation before making changes
