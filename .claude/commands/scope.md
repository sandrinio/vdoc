# Scope Blueprint

Forces a hard pause to align on the execution plan before any code is written.

**Usage:** `/scope $ARGUMENTS`

The `$ARGUMENTS` variable contains the user's request to scope.

## Instructions

**CRITICAL: You MUST NOT write any code until the user explicitly approves this blueprint.**

1. **PAUSE** all coding execution immediately.
2. Draft the **RGCCOV** table below based on the user's request.
3. **WAIT** for explicit user approval (e.g., "Approved", "LGTM", "Go ahead").

## RGCCOV Template

| Attribute | Definition |
|:----------|:-----------|
| **Role** | Who are you acting as? (e.g., "Senior Backend Dev", "n8n Specialist", "Full-Stack Engineer") |
| **Goal** | What is the single specific outcome of this request/iteration? |
| **Context** | Relevant files, database tables, refer to `_manifest.json`. List specific file paths. |
| **Constraints** | Tech stack limits, strict file paths, performance needs, security requirements |
| **Output** | List of specific files to be created or modified (with full paths) |
| **Verification** | How will we verify success? IF complexity >= Medium OR requested → MUST include automated test script |

## Example Output

```
🎯 **SCOPE BLUEPRINT**

| Attribute | Definition |
|:----------|:-----------|
| **Role** | Senior Backend Developer |
| **Goal** | Add rate limiting to the `/api/chat` endpoint |
| **Context** | - `app/api/routers/chat.py` (main endpoint)<br>- `app/core/dependencies.py` (middleware)<br>- `_manifest.json` shows no existing rate limit docs |
| **Constraints** | - Must use Redis for distributed rate limiting<br>- Max 100 req/min per user<br>- Must not break existing tests |
| **Output** | - `app/core/rate_limit.py` (new)<br>- `app/api/routers/chat.py` (modified)<br>- `tests/test_rate_limit.py` (new) |
| **Verification** | - Unit tests for rate limiter<br>- Integration test hitting endpoint 101 times<br>- Manual test with `curl` |

⏸️ **Awaiting your approval before proceeding...**
```

## Rules

- NEVER start coding before approval
- Be specific about file paths (use full paths from project root)
- Always include verification steps
- For medium+ complexity tasks, verification MUST include automated tests
- Use the AskUserQuestion tool if the request is too ambiguous to scope
