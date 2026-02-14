# Init Workflow

## Step 1 — Explore

Follow the two-phase exploration strategy in `references/exploration-strategies.md`:

**Phase 1 — Fingerprint** (3-5 file reads max)
Read package/config files and directory structure to identify the project's language, framework, and archetype. Also check for existing documentation (`vdocs/`, `docs/`, `product_documentation/`, substantial `*.md` files). If found, read them first — they're a head start. See the "Existing Documentation" section in `references/exploration-strategies.md`.

**Phase 2 — Targeted Exploration** (archetype-specific)
Apply the matching archetype playbook from `references/exploration-strategies.md`. Read files in priority order using the glob patterns listed. Identify feature signals — each signal maps to a documentable feature. Combine multiple playbooks when the project doesn't fit a single archetype (see "Composing Archetypes" in the strategies file).

If no archetype matches, use the Fallback strategy and confirm with the user.

Do not skim. Understand how the system actually works before proposing docs.

**Important:** Use your built-in file-reading tools to explore. Do NOT create scanner scripts, shell scripts, or any tooling. vdoc is purely AI-driven — no scripts, no build steps, no infrastructure.

**Phase 3 — Write Exploration Log**
After exploring, write `vdocs/_exploration_log.md` documenting what you found:

```markdown
# Exploration Log

## Fingerprint
- **Language(s):** e.g., TypeScript, Python
- **Framework(s):** e.g., Next.js 14, FastAPI
- **Archetype(s):** e.g., Full-stack Framework
- **Scope:** e.g., ~85 files, medium

## Files Read
| # | File | Why | What I Found |
|---|------|-----|--------------|
| 1 | package.json | Fingerprint | Next.js 14, Prisma, NextAuth |
| 2 | src/app/ (listing) | Page tree | 12 routes, 3 API routes |
| ... | ... | ... | ... |

## Feature Signals Detected
| Signal | Source File(s) | Proposed Doc |
|--------|---------------|--------------|
| Auth middleware + login page | middleware.ts, app/login/page.tsx | AUTHENTICATION_DOC.md |
| Prisma schema with 8 models | prisma/schema.prisma | DATA_MODEL_DOC.md |
| ... | ... | ... |

## Ambiguities / Open Questions
- Could not determine why Redis is in dependencies — no usage found. Ask user.
- Payments folder exists but appears incomplete / WIP.
```

This log is your working memory. It feeds directly into Step 2 (Plan).

## Step 2 — Plan

Write `vdocs/_DOCUMENTATION_PLAN.md` to disk AND present it to the user in the same step. The file must be persisted — do not just show it in chat.

Use this format:

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

After writing the file, present the plan to the user. Actively suggest changes:
- "Should I merge X and Y into one doc?"
- "I found a websocket system — want that documented separately?"
- "Any internal/legacy systems I should skip?"

Wait for user approval before proceeding.

## Step 3 — Generate

Read the template from `.agents/vdoc/doc-template.md` once before starting.

Then generate docs **one at a time, sequentially**. For each approved doc:

1. Read ALL relevant source files for that feature — not just the main file, but helpers, types, middleware, tests
2. Write `vdocs/FEATURE_NAME_DOC.md` following the template exactly
3. Confirm the file was written before moving to the next doc

Do NOT attempt to generate multiple docs from memory. Each doc is a fresh cycle: read sources → write doc → next.

**Writing rules:**

- **Mermaid diagrams are mandatory** in "How It Works". Show the actual flow — request lifecycle, state transitions, data pipeline. If a flow has more than 7-9 nodes, split into multiple diagrams.
- **Data Model** must show real entities from the code, not generic placeholders. Use mermaid ER diagrams for relational data, tables for simpler models.
- **Constraints & Decisions** is the most valuable section. Dig into the code for non-obvious choices: "Uses polling instead of websockets because...", "Auth tokens expire in 15min because...". If you can't find the reason, state the constraint and mark it: `Reason: unknown — verify with team`.
- **Related Features** must reference other docs by filename and explain the coupling: "Changes to the JWT schema will require updates to API_REFERENCE_DOC.md (auth middleware affects all endpoints)."
- **Configuration** must list actual env vars/secrets from the code, not hypothetical ones.
- **Error Handling** — trace what happens when things fail. What does the user see? What gets logged? Is there retry logic?

## Step 4 — Manifest

Create `vdocs/_manifest.json` using the schema in `.agents/vdoc/manifest-schema.json`.

The `description` field is critical — write it rich enough that you can route any user question to the right doc by matching against descriptions. Include specific technology names, patterns, and concepts.

Example:

```json
{
  "filepath": "AUTHENTICATION_DOC.md",
  "title": "Authentication - OAuth2 & JWT",
  "version": "1.0.0",
  "description": "OAuth2 flow with Google/GitHub providers, JWT token lifecycle, session management via NextAuth.js, route protection middleware, and role-based access control.",
  "tags": ["oauth2", "jwt", "session-management", "rbac"]
}
```

## Step 5 — Self-Review

Before finishing, verify:

- [ ] Every doc has at least one mermaid diagram in "How It Works"
- [ ] Every doc has at least 2 entries in "Constraints & Decisions"
- [ ] Every doc's "Key Files" lists real paths that exist in the codebase
- [ ] Every doc's "Configuration" lists actual env vars from the code
- [ ] Every doc's "Related Features" references other doc filenames
- [ ] Manifest `description` is detailed enough for semantic routing
- [ ] No doc is just a shallow restatement of file names — each explains WHY and HOW
