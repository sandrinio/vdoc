# Init Workflow

## Step 1 — Explore

Read the codebase thoroughly. Identify:

- **Tech stack**: languages, frameworks, databases, ORMs
- **Features**: authentication, API, payments, notifications, search, etc.
- **Architecture**: monolith vs microservices, frontend/backend split, key patterns (MVC, event-driven, etc.)
- **Integrations**: third-party services (Stripe, AWS, Redis, etc.)
- **Entry points**: where requests come in, how they flow through the system

Do not skim. Read key files — entry points, config files, route definitions, schema files, middleware. Understand how the system actually works before proposing docs.

**Important:** Use your built-in file-reading tools to explore. Do NOT create scanner scripts, shell scripts, or any tooling. vdoc is purely AI-driven — no scripts, no build steps, no infrastructure.

## Step 2 — Plan

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

## Step 3 — Generate

For each approved doc:

1. Read ALL relevant source files for that feature — not just the main file, but helpers, types, middleware, tests
2. Follow the template in `.junie/vdoc/doc-template.md` exactly
3. Write to `vdocs/FEATURE_NAME_DOC.md`

**Writing rules:**

- **Mermaid diagrams are mandatory** in "How It Works". Show the actual flow — request lifecycle, state transitions, data pipeline. If a flow has more than 7-9 nodes, split into multiple diagrams.
- **Data Model** must show real entities from the code, not generic placeholders. Use mermaid ER diagrams for relational data, tables for simpler models.
- **Constraints & Decisions** is the most valuable section. Dig into the code for non-obvious choices: "Uses polling instead of websockets because...", "Auth tokens expire in 15min because...". If you can't find the reason, state the constraint and mark it: `Reason: unknown — verify with team`.
- **Related Features** must reference other docs by filename and explain the coupling: "Changes to the JWT schema will require updates to API_REFERENCE_DOC.md (auth middleware affects all endpoints)."
- **Configuration** must list actual env vars/secrets from the code, not hypothetical ones.
- **Error Handling** — trace what happens when things fail. What does the user see? What gets logged? Is there retry logic?

## Step 4 — Manifest

Create `vdocs/_manifest.json` using the schema in `.junie/vdoc/manifest-schema.json`.

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
