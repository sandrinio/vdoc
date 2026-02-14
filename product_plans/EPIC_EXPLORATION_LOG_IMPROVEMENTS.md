# EPIC: Exploration Log Improvements

> Make the exploration log output more actionable — prioritize signals, quantify scope, recommend defaults, and scale to large repos. All changes must remain language/framework agnostic.

## Context

The exploration log (`vdocs/_exploration_log.md`) currently does a strong job at discovery: fingerprinting the project, reading files with stated intent, detecting feature signals across layers, and surfacing ambiguities honestly. What it lacks is actionability — the output is a flat list of findings that requires the user (or the Plan step) to do the prioritization, sizing, and decision-making work. Five targeted improvements make the log directly feed into better plans without adding domain-specific logic.

## Guiding Constraint

vdoc is universal. Every change must work for a React app, a Rust CLI, a Python ML pipeline, a Go microservice, and a monorepo. If an improvement requires framework-specific knowledge, it doesn't belong here — it belongs in the archetype playbooks.

---

### 1. Feature Signal Priority Ordering

**Problem:** All feature signals are listed flat. Auth and AI Chat appear at the same level, even though half the features depend on auth. The Plan step has to re-derive dependencies from scratch.

**Solution:** After detecting signals, sort them into two tiers based on import/reference analysis:

| Tier | Rule | Example |
|------|------|---------|
| **Foundation** | Signal's source files are imported by 3+ other signals | Auth, Data Model, Caching |
| **Feature** | Everything else | AI Chat, Admin Panel, Communications |

Within each tier, order by number of dependents (most depended-on first).

**How to detect (language-agnostic):** Cross-reference the source files listed in each signal. If Signal A's files appear in `import`/`require`/`use`/`include` statements within Signal B's files, Signal B depends on Signal A. This works via Grep — no AST parsing needed.

**Exploration log output change:**

```markdown
## Feature Signals Detected

### Foundation (depended on by other features)
| Signal | Source File(s) | Proposed Doc | Dependents |
|--------|---------------|--------------|------------|
| Google OAuth + JWT + token refresh | lib/auth.ts, hooks/useAuth.ts | AUTHENTICATION_DOC.md | 12 |
| Multi-layer caching (memory + Redis) | lib/cacheManager.ts, lib/redis.ts | CACHING_DOC.md | 5 |

### Features
| Signal | Source File(s) | Proposed Doc | Depends On |
|--------|---------------|--------------|------------|
| AI streaming chat + RAG + mentions | api/ai/chat/stream, components/ai/ | AI_CHAT_DOC.md | Auth, Caching |
| Admin dashboard + stats + feedback | app/admin/, api/admin/ | ADMIN_DOC.md | Auth |
```

**Files to change:**
- `skills/claude/vdoc-init.md` — Update Step 1 exploration log template
- `skills/claude/references/exploration-strategies.md` — Add dependency detection instructions
- Propagate equivalent changes to all 9 other platform skill files

---

### 2. Complexity Indicator Per Signal

**Problem:** A signal spanning 2 files (Admin CRUD) and a signal spanning 15 files across 4 layers (AI Chat with streaming, RAG, workers, types) appear identical in the log. The Plan step can't allocate appropriate depth.

**Solution:** Add two metrics per signal, both derivable from what's already detected:

- **File count** — number of source files listed in the signal
- **Layer count** — number of distinct code layers touched (e.g., API, components, hooks, types, workers = 5 layers)

Layer detection is directory-based, not semantic — count distinct top-level directories in the source file paths. This works for any language's convention (`routes/` vs `handlers/` vs `views/` — they're all different directories).

**Exploration log output change:**

```markdown
## Feature Signals Detected
| Signal | Source File(s) | Files | Layers | Proposed Doc |
|--------|---------------|-------|--------|--------------|
| AI streaming chat + RAG | api/ai/, components/ai/, hooks/, workers/, types/ | 14 | 5 | AI_CHAT_DOC.md |
| Admin dashboard | app/admin/, api/admin/, components/admin/ | 6 | 3 | ADMIN_DOC.md |
```

**Files to change:**
- `skills/claude/vdoc-init.md` — Update signal table template with Files/Layers columns
- Propagate to all 9 other platform skill files

---

### 3. Exact Counts in Scope

**Problem:** The Fingerprint section uses approximations like "~150+ component files, ~95 lib files". The scanner read the directories — it has exact counts. Approximations undermine trust in the rest of the log.

**Solution:** Replace "~N+" with exact counts from the directory listings already performed. Add a Scope table:

```markdown
## Fingerprint
- **Language(s):** TypeScript (React 19, Node.js)
- **Framework(s):** Next.js 16 (App Router), Tailwind CSS 3.4
- **Archetype(s):** Full-Stack Framework + Web API
- **Scope:**

| Category | Count |
|----------|-------|
| Page routes | 24 |
| API endpoints | 197 |
| Components | 152 |
| Lib/utils | 95 |
| Hooks | 47 |
| Type files | 20 |
```

Categories are derived from whatever directories the scanner actually found — not a fixed set. A Rust CLI would show `commands: 8, modules: 12`. A Python pipeline would show `dags: 5, transforms: 22`.

**Files to change:**
- `skills/claude/vdoc-init.md` — Update Fingerprint template in Step 1
- Propagate to all 9 other platform skill files

---

### 4. Ambiguities Should Propose Defaults

**Problem:** The Ambiguities section asks questions but doesn't suggest answers. "Should X or Y?" forces the user to stop, investigate, and decide. This breaks momentum (violates EFF from CLAUDE.md).

**Solution:** Every ambiguity must include a recommended default with reasoning. The user can override, but doesn't have to stop and think.

**Current:**
```markdown
## Ambiguities / Open Questions
- Intelligence Service vs N8N: Both paths exist. Should both be documented?
- `src/stores/` directory exists but is empty — likely deprecated.
```

**Proposed:**
```markdown
## Ambiguities / Open Questions
| Question | Recommendation | Reasoning |
|----------|---------------|-----------|
| Intelligence Service vs N8N: both paths exist | Document Intelligence Service as primary, add legacy note for N8N | Intelligence Service has more recent commits and is imported by the main chat flow |
| `src/stores/` is empty | Exclude from docs | No code to document; note in PROJECT_OVERVIEW as deprecated |
| Debug/test routes (`/api/debug/*`) | Exclude from docs | Not user-facing; no business logic |
| Redis hard-dependency unclear | Document Redis as optional with in-memory fallback | `lib/redis.ts` explicitly implements fallback pattern |
```

**Files to change:**
- `skills/claude/vdoc-init.md` — Update Ambiguities template, add instruction to always propose a default
- `skills/claude/references/exploration-strategies.md` — Add guidance on forming recommendations from code signals (recent commits, import frequency, fallback patterns)
- Propagate to all 9 other platform skill files

---

### 5. Files Read Table Scalability

**Problem:** The Files Read table works fine at 20 rows. A monorepo with 200+ packages would produce a table nobody reads. The format doesn't scale.

**Solution:** Cap the table at 25 rows. Beyond that, collapse into a summary + detail section:

**Under 25 reads — current format (no change):**
```markdown
## Files Read
| # | File | Why | What I Found |
|---|------|-----|--------------|
| 1 | package.json | Fingerprint | ... |
```

**25+ reads — summary + collapsed detail:**
```markdown
## Files Read (42 total)

| Category | Count | Key Findings |
|----------|-------|-------------|
| Config/package files | 6 | Next.js 16, 3 microservices, shared tsconfig |
| Route/endpoint files | 12 | 197 API endpoints, 24 pages |
| Infrastructure | 8 | Redis, Supabase, S3, auth middleware |
| Business logic | 11 | AI chat, sync engine, document ops |
| Type definitions | 5 | 20 type files, strong typing throughout |

<details>
<summary>Full file list</summary>

| # | File | Why | What I Found |
|---|------|-----|--------------|
| 1 | package.json | Fingerprint | ... |
...
</details>
```

Categories are dynamically derived from the "Why" column — group by exploration intent, not by file type.

**Files to change:**
- `skills/claude/vdoc-init.md` — Add scalability rule to Step 1 log output
- Propagate to all 9 other platform skill files

---

## Tracking

| # | Improvement | Design | Implement (Claude) | Propagate (9 platforms) |
|---|------------|--------|-------------------|------------------------|
| 1 | Signal priority ordering | TODO | TODO | TODO |
| 2 | Complexity indicator | TODO | TODO | TODO |
| 3 | Exact scope counts | TODO | TODO | TODO |
| 4 | Ambiguity defaults | TODO | TODO | TODO |
| 5 | Files Read scalability | TODO | TODO | TODO |

## Implementation Notes

- **Propagation** means updating the equivalent skill files for Cursor, Windsurf, VS Code, Continue, Cline, Gemini, JetBrains AI, Junie, and AGENTS.md. Each platform has its own format, but the exploration log template and instructions are embedded in their respective workflow files.
- Changes 1 and 4 also touch `exploration-strategies.md` (or equivalent reference file per platform).
- All changes are to instruction/template files only — no code changes to `bin/vdoc.mjs` or CI.
- Changes should be tested by running `/vdoc-init` on at least 2 different archetype repos (e.g., a CLI tool and a full-stack app) to verify the output stays clean across project types.
