**vdoc**

AI-Powered Product Documentation Generator

Multi-Platform • Zero Dependencies • Update-First

Comprehensive Product Specification

Version 2.0 \| February 2026

**Status: Design Phase**

**Table of Contents**

**1. Executive Summary**

**1.1 What Is vdoc?**

vdoc is an open-source developer tool that generates and maintains product documentation from source code. It works across multiple AI-powered coding environments including Claude Code, Cursor, Windsurf, Aider, and Continue (VS Code). The core tooling is universal (pure bash, zero dependencies); only a thin adapter layer is platform-specific.

The tool solves a persistent problem in software development: documentation that either does not exist, is outdated the day after it is written, or lives only in the heads of the developers who wrote the code. vdoc makes it trivial to generate comprehensive product documentation from a codebase and, critically, to keep that documentation current as the codebase evolves.

**1.2 Design Principles**

-   **Zero dependencies.** The entire tool runs on bash, POSIX utilities (find, grep, sed, awk), and git. No Python, Node.js, or any other runtime is required beyond what every developer already has.

-   **Multi-platform by architecture.** A single source-of-truth instruction file is wrapped by thin adapters into each platform's native format. The core is written once, maintained once.

-   **Script execution required.** vdoc only supports platforms where the AI can execute bash scripts autonomously. This is a deliberate constraint that enables full automation.

-   **Update-first architecture.** Initial generation happens once. Updates happen forever. The system is optimized for the command that runs fifty times, not the one that runs once.

-   **Token efficiency.** Heavy lifting (filesystem scanning, hashing, docstring extraction) is performed by bash scripts whose output, not source code, enters the AI context window.

-   **The manifest as a universal context file.** The \_manifest.json serves triple duty: update tracking for vdoc, instant project orientation for any AI, and table of contents for humans.

**1.3 Target Users**

The primary user is a developer who works with any supported AI coding tool and wants to generate documentation useful for product managers, new team members, engineering leads, and other stakeholders who need to understand the product without reading source code.

**1.4 Supported Platforms**

vdoc supports AI coding tools that can execute bash scripts autonomously. This is the hard requirement for full automation.

  --------------------------------------------------------------------------------------------
  **Platform**         **Script Execution**    **Instruction Format**        **Status**
  -------------------- ----------------------- ----------------------------- -----------------
  Claude Code          Native bash execution   SKILL.md (YAML frontmatter)   Primary

  Cursor               Agent/Composer mode     .cursor/rules/vdoc.md         Primary

  Windsurf (Codeium)   Cascade agent           .windsurfrules                Supported

  Aider                /run command            .aider.conf.yml conventions   Supported

  Continue (VS Code)   Agent mode execution    .continue/ config             Supported
  --------------------------------------------------------------------------------------------

Platforms without script execution (GitHub Copilot Chat, Gemini Code Assist, standard VS Code extensions) are explicitly excluded. They could read the manifest and documentation but cannot run the scanner autonomously.

**2. Architecture**

**2.1 System Overview**

vdoc is composed of four layers. The first three are universal; only the fourth is platform-specific.

  -----------------------------------------------------------------------------------------------------------------------------------------------------
  **Layer**         **Responsibility**                                                    **Technology**                       **Platform-Specific?**
  ----------------- --------------------------------------------------------------------- ------------------------------------ ------------------------
  Distribution      Installing tool files onto the developer's machine                    Bash (install.sh)                    Installer flag only

  Scanning          Building a codebase snapshot: paths, categories, hashes, docstrings   Bash + POSIX utilities (scan.sh)     No

  State             Tracking documentation coverage, file hashes, bidirectional links     JSON (\_manifest.json)               No

  Intelligence      Interpreting scans, generating/updating documentation prose           Platform-specific instruction file   Yes (adapter layer)
  -----------------------------------------------------------------------------------------------------------------------------------------------------

**2.2 The Adapter Pattern**

The intelligence layer uses a single source-of-truth instruction file (instructions.md) that contains all vdoc logic: when to run the scanner, how to interpret the manifest, the tiered description strategy, how to generate and update docs. Each supported platform has a thin adapter script that reformats this content into the platform's native instruction format.

> instructions.md (universal)
>
> \|
>
> ├── adapter/claude → SKILL.md with YAML frontmatter
>
> ├── adapter/cursor → .cursor/rules/vdoc.md
>
> ├── adapter/windsurf → .windsurfrules section
>
> ├── adapter/aider → .aider conventions file
>
> └── adapter/continue → .continue/ config file

Each adapter is a short bash script (20--30 lines) that reads instructions.md and wraps it in the target format. When you update instructions.md, every platform gets the update. When a platform changes its config format, only that adapter changes.

**2.3 Repository Structure**

> github.com/you/vdoc/
>
> ├── install.sh ← Universal installer with platform flag
>
> ├── core/
>
> │ ├── instructions.md ← Single source of truth (all logic)
>
> │ ├── scan.sh ← Codebase scanner (pure bash)
>
> │ ├── presets/
>
> │ │ ├── typescript.conf
>
> │ │ ├── javascript.conf
>
> │ │ ├── python.conf
>
> │ │ ├── go.conf
>
> │ │ ├── rust.conf
>
> │ │ ├── java.conf
>
> │ │ └── default.conf ← Fallback for unknown languages
>
> │ └── templates/
>
> │ └── doc-page.md
>
> ├── adapters/
>
> │ ├── claude/generate.sh ← instructions.md → SKILL.md
>
> │ ├── cursor/generate.sh ← instructions.md → .cursor/rules/
>
> │ ├── windsurf/generate.sh
>
> │ ├── aider/generate.sh
>
> │ └── continue/generate.sh
>
> ├── README.md
>
> └── LICENSE

**2.4 Project-Level File Layout**

After installation, the developer's project contains these vdoc-related files:

> my-project/
>
> ├── .cursor/rules/vdoc.md ← Platform-specific (gitignored)
>
> ├── vdocs/
>
> │ ├── .vdoc/ ← Shared tools (committed to git)
>
> │ │ ├── instructions.md ← Platform-agnostic source of truth
>
> │ │ ├── scan.sh
>
> │ │ ├── presets/
>
> │ │ └── templates/
>
> │ ├── \_manifest.json ← Project state (committed)
>
> │ ├── overview.md ← Generated docs (committed)
>
> │ ├── api-reference.md
>
> │ └── architecture.md
>
> └── \...

+---+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
|   | **Key Separation**                                                                                                                                                                                                                                                                                                                                                   |
|   |                                                                                                                                                                                                                                                                                                                                                                      |
|   | Platform-specific instruction files (e.g. .cursor/rules/vdoc.md) are gitignored and local. The universal tools live inside vdocs/.vdoc/ and are committed. When a teammate clones the repo, they run the installer with their preferred platform flag, which generates their local instruction file from the already-present instructions.md. No re-download needed. |
+---+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+

**3. The Manifest (\_manifest.json)**

**3.1 Purpose**

The manifest is vdoc's most important design decision. It serves three distinct audiences simultaneously:

-   **For vdoc itself:** Tracks which source files are documented where, and stores file hashes at time of documentation. This enables diff-aware updates.

-   **For any AI tool:** Provides instant structured orientation to the entire project. A developer can tell any AI coding tool to "read \_manifest.json first" and the AI immediately knows what files exist, how they relate, and what documentation covers them. This works regardless of which platform generated the docs.

-   **For humans:** Acts as a living table of contents with descriptions of every documentation page and what it covers.

+---+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
|   | **Cross-Platform Context**                                                                                                                                                                                                                                                                            |
|   |                                                                                                                                                                                                                                                                                                       |
|   | Because the manifest is platform-agnostic JSON, a developer who generated docs with Claude Code can hand the project to a teammate using Cursor. The teammate's AI reads the same \_manifest.json and understands the project identically. The manifest is the shared contract between all platforms. |
+---+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+

**3.2 Schema**

The manifest contains two main sections: the documentation array (outward-facing) and the source index (inward-facing).

**Documentation Array**

Each entry describes a documentation page that vdoc has generated or the user has requested.

  --------------------------------------------------------------------------------------------------------------
  **Field**               **Type**                             **Description**
  ----------------------- ------------------------------------ -------------------------------------------------
  path                    string                               Relative path to the doc file from project root

  title                   string                               Human-readable title of the documentation page

  covers                  string\[\] \| \"auto\" \| \"none\"   Source files this doc page is derived from

  audience                string                               Who this page is written for

  description             string                               Brief summary of what the page documents
  --------------------------------------------------------------------------------------------------------------

The covers field supports three modes:

-   **Explicit paths:** An array of source file paths or glob patterns. The AI reads exactly these files when generating or updating.

-   **\"auto\":** The AI searches the source index for files semantically related to the section title. Used for user-added custom sections.

-   **\"none\":** The AI generates a template structure for the user to fill manually. Used when no matching source files exist.

**Source Index**

  -------------------------------------------------------------------------------------------------------------------------------
  **Field**               **Type**                **Description**
  ----------------------- ----------------------- -------------------------------------------------------------------------------
  hash                    string                  SHA-256 hash of the file at time of last documentation

  category                string                  Functional category assigned by the scanner

  description             string                  Brief description of what the file does

  description_source      string                  How the description was derived: \"docstring\", \"inferred\", or \"analyzed\"

  documented_in           string\[\]              List of doc page paths that reference this file
  -------------------------------------------------------------------------------------------------------------------------------

**3.3 Bidirectional Linking**

The manifest creates bidirectional links between source files and documentation pages. From any documentation page, the covers field traces back to source files. From any source file, the documented_in field points to its documentation. This bidirectionality is what makes the update workflow efficient: when a file hash changes, vdoc follows the documented_in pointer to know exactly which documentation page needs attention.

**3.4 Example**

> {
>
> \"project\": \"my-app\",
>
> \"language\": \"typescript\",
>
> \"last_updated\": \"2026-02-05T14:30:00Z\",
>
> \"vdoc_version\": \"2.0.0\",
>
> \"documentation\": \[
>
> {
>
> \"path\": \"vdocs/overview.md\",
>
> \"title\": \"Project Overview\",
>
> \"covers\": \[\"README.md\", \"package.json\"\],
>
> \"audience\": \"all team members\",
>
> \"description\": \"High-level overview: purpose, tech stack, getting started\"
>
> },
>
> {
>
> \"path\": \"vdocs/api-reference.md\",
>
> \"title\": \"API Reference\",
>
> \"covers\": \[\"src/api/users.ts\", \"src/api/auth.ts\"\],
>
> \"audience\": \"backend engineers\",
>
> \"description\": \"REST endpoints, request/response formats, authentication\"
>
> }
>
> \],
>
> \"source_index\": {
>
> \"src/api/users.ts\": {
>
> \"hash\": \"a3f2c1\...\",
>
> \"category\": \"api_routes\",
>
> \"description\": \"User CRUD operations and profile management\",
>
> \"description_source\": \"docstring\",
>
> \"documented_in\": \[\"vdocs/api-reference.md\"\]
>
> }
>
> }
>
> }

**4. Installation & Distribution**

**4.1 Per-Platform Installation**

The developer chooses their platform explicitly with a single command. Each install is independent and optimized for the target platform.

> \# Claude Code
>
> curl -fsSL vdoc.dev/install \| bash -s \-- claude
>
> \# Cursor
>
> curl -fsSL vdoc.dev/install \| bash -s \-- cursor
>
> \# Windsurf
>
> curl -fsSL vdoc.dev/install \| bash -s \-- windsurf
>
> \# Aider
>
> curl -fsSL vdoc.dev/install \| bash -s \-- aider
>
> \# Continue (VS Code)
>
> curl -fsSL vdoc.dev/install \| bash -s \-- continue

If a developer uses multiple tools, they run the installer once per tool. Each creates its own platform-specific instruction file without interfering with the others. Additionally, \--auto flag detects which tool config directories exist on the machine and installs for those automatically.

**4.2 What the Installer Does**

The install.sh script performs six operations, completing in under two seconds:

1.  Validates the platform argument (claude, cursor, windsurf, aider, continue).

2.  Detects project language by checking for package.json, requirements.txt, go.mod, Cargo.toml, pom.xml, or build.gradle.

3.  Creates ./vdocs/.vdoc/ and copies the universal core files (scan.sh, all presets, templates, instructions.md) into it.

4.  Runs the platform-specific adapter script to generate the instruction file in the correct format and location.

5.  Adds the platform-specific instruction file path to .gitignore (if not already present).

6.  Prints a confirmation with the next step for that platform.

**4.3 Teammate Onboarding**

When a teammate clones a project that already has vdoc set up, the universal tools are already present in vdocs/.vdoc/ (committed to git). The teammate only needs to generate their platform-specific instruction file:

> git clone project-repo
>
> cd project-repo
>
> curl -fsSL vdoc.dev/install \| bash -s \-- cursor
>
> \# Or, if vdoc is already installed globally:
>
> bash vdocs/.vdoc/setup.sh cursor

The second option (setup.sh) uses the already-present instructions.md to generate the adapter output. No download from GitHub needed, no internet required. This makes onboarding work in air-gapped environments.

**4.4 Uninstalling**

Removing a platform integration removes only the platform-specific instruction file:

> curl -fsSL vdoc.dev/install \| bash -s \-- uninstall cursor

This leaves all shared files (vdocs/.vdoc/, \_manifest.json, generated documentation) intact. The developer can switch platforms without losing any documentation state.

**5. Language Presets**

**5.1 What Presets Define**

Each preset is a bash-sourceable .conf file that tells the scanner how to interpret a specific language ecosystem. Presets affect input only (what to scan and how to categorize); the documentation output is always language-agnostic prose.

  ------------------------------------------------------------------------------------------------------------
  **Variable**            **Purpose**                 **Example (TypeScript)**
  ----------------------- --------------------------- --------------------------------------------------------
  EXCLUDE_DIRS            Directories to skip         node_modules dist build .next coverage

  EXCLUDE_FILES           File patterns to skip       \*.min.js \*.bundle.js \*.map \*.lock

  ENTRY_PATTERNS          Likely entry point files    src/index.\* src/app.\* pages/\* app/\*

  DOCSTRING_PATTERN       Regex for docstring start   \^\\s\*/\\\*\\\*

  DOCSTRING_END           Regex for docstring end     \\\*/

  DOC_SIGNALS             Category-to-glob mappings   api_routes:src/api/\*\* components:src/components/\*\*
  ------------------------------------------------------------------------------------------------------------

**5.2 Supported Languages**

  ----------------------------------------------------------------------------------------------------
  **Preset**              **Detection File**                 **Key Exclusions**
  ----------------------- ---------------------------------- -----------------------------------------
  typescript.conf         tsconfig.json                      node_modules, dist, .next, coverage

  javascript.conf         package.json (no tsconfig)         node_modules, dist, build, coverage

  python.conf             requirements.txt, pyproject.toml   \_\_pycache\_\_, .venv, .egg-info, dist

  go.conf                 go.mod                             vendor, bin

  rust.conf               Cargo.toml                         target, debug, release

  java.conf               pom.xml, build.gradle              target, build, .gradle, .class files

  default.conf            Fallback                           Generic: .git, .idea, .vscode
  ----------------------------------------------------------------------------------------------------

**5.3 Doc Signals**

The DOC_SIGNALS variable maps glob patterns to functional categories. These categories determine what documentation pages the AI proposes. A project with files matching the api_routes signal gets an API Reference page. No matching files, no proposal. This keeps the documentation plan relevant to the actual codebase.

**5.4 Custom Presets**

Developers can create custom presets by adding a .conf file to vdocs/.vdoc/presets/. Since this directory is committed to git, custom presets are shared with the team automatically.

**6. The Scanner (scan.sh)**

**6.1 Design Philosophy**

The scanner is a pure bash script using only POSIX utilities (find, grep, sed, awk, shasum). It has zero external dependencies. Its output enters the AI context window; its source code never does. This means the scanner can be arbitrarily complex without consuming tokens. This design is critical for multi-platform support: every supported tool can execute a bash script and consume its stdout.

**6.2 Output Format**

The scanner outputs a pipe-delimited, line-based format that is compact, human-readable, and trivially parsable by any AI model:

> \# vdoc scan output
>
> \# generated: 2026-02-05T14:30:00Z
>
> \# language: typescript
>
> \# files: 47
>
> src/api/users.ts \| api_routes \| a3f2c1 \| User CRUD operations and profile management
>
> src/api/auth.ts \| api_routes \| b7d4e2 \| JWT authentication, OAuth flow
>
> src/middleware/rateLimit.ts \| middleware \| c8e3f1 \|
>
> src/components/Button.tsx \| components \| d2a4b7 \| Reusable button with variant support

Each line contains: file path, category (from doc signals), SHA-256 hash (truncated), and the extracted docstring (empty if none found). This format avoids JSON generation in bash and is model-agnostic.

**6.3 Scanner Operations**

7.  Sources the appropriate language preset based on auto-detection.

8.  Walks the file tree using find, applying EXCLUDE_DIRS and EXCLUDE_FILES filters.

9.  Computes a truncated SHA-256 hash per file for change detection.

10. Categorizes each file by matching its path against DOC_SIGNALS globs.

11. Extracts the first docstring/comment block using language-specific patterns.

12. Outputs the result in the pipe-delimited format to stdout.

**6.4 Token Efficiency**

A typical 200-file project produces scanner output of approximately 10--15 KB of text. Reading even a fraction of those files directly could consume 500 KB+ of context. The scanner compresses relevant information by roughly 30--50x. Additionally, the AI never reads scan.sh itself --- only its stdout enters the context window.

**7. Workflows**

**7.1 Init (First Run)**

Triggered when a developer first uses vdoc in a project. The AI detects the absence of \_manifest.json and enters interactive onboarding. This workflow is identical across all platforms.

**Sequence**

13. The scanner (scan.sh) executes and produces a fresh codebase snapshot.

14. The AI reads the scan output and proposes a documentation structure based on detected categories.

15. The developer reviews and adjusts interactively. *They can request additions, removals, or reorganization in natural language.*

16. Once confirmed, the AI generates all documentation pages and writes \_manifest.json.

**Interactive Proposal Example**

> I see this is a TypeScript project using Next.js with Prisma.
>
> I've scanned 142 source files across 12 directories.
>
> Here's what I'd document:
>
> 1\. Project Overview --- purpose, tech stack, getting started
>
> 2\. API Reference --- 8 API routes found in src/api/
>
> 3\. Database Schema --- Prisma models and relationships
>
> 4\. Authentication Flow --- auth middleware, JWT, OAuth
>
> 5\. Component Library --- 23 React components in src/components/
>
> Want me to proceed, or would you like to adjust?

**7.2 Update**

The primary workflow. Designed to run repeatedly as the codebase evolves. Non-interactive by default. Identical logic across all platforms.

**Sequence**

17. The scanner executes and produces a fresh snapshot with current hashes.

18. The AI compares current hashes against those stored in \_manifest.json.

19. Files are sorted into three buckets:

    -   New files: present in scan, absent from manifest.

    -   Changed files: present in both, but hash mismatch.

    -   Deleted files: present in manifest, absent from scan.

20. For changed files, the AI reads the existing doc section and the updated source, then rewrites the section.

21. For new files, the AI checks if they fit an existing doc page or proposes a new one.

22. For deleted files, the AI flags references for removal or rewording.

23. The manifest is updated with new hashes and any structural changes.

+---+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
|   | **Preserving User Edits**                                                                                                                                                                                      |
|   |                                                                                                                                                                                                                |
|   | The update is a diff-aware patch, not a full regeneration. If the user has hand-edited a documentation page, those edits are preserved. The AI only modifies sections that correspond to changed source files. |
+---+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+

**7.3 Tiered Description Strategy**

When building or updating file descriptions, vdoc uses a three-pass strategy to minimize token consumption:

  ---------------------------------------------------------------------------------------------------------
  **Pass**               **Method**                                     **Token Cost**    **Coverage**
  ---------------------- ---------------------------------------------- ----------------- -----------------
  A: Script-extracted    Docstrings extracted by scan.sh                Zero              \~40--60%

  B: Metadata-inferred   AI derives from file name, category, exports   Minimal           \~25--40%

  C: Source-analyzed     AI reads actual source code                    Full file read    \~10--20%
  ---------------------------------------------------------------------------------------------------------

**7.4 Handling User-Added Sections**

When a user adds a documentation section for a topic not auto-detected, three scenarios apply:

**Scenario A: Source Files Specified**

> The user provides explicit file paths in the covers field. The AI reads those files and generates documentation directly.

**Scenario B: \"auto\" Mode**

> The user adds a section title with covers set to \"auto\". The AI searches the source index for semantically related files and presents candidates for confirmation.

**Scenario C: No Matching Files**

> No source files match. The AI offers to generate a template for manual filling or skip the section.

**8. Platform Adapters**

**8.1 The Instructions File**

The core/instructions.md file contains all vdoc logic in a platform-agnostic format. It covers: init detection, scanner execution, manifest interpretation, tiered description, documentation generation, update diffing, and user-added section handling. This file is the single source of truth for vdoc's behavior.

**8.2 Adapter Responsibilities**

Each adapter script (adapters/\<platform\>/generate.sh) performs three tasks:

24. Reads core/instructions.md.

25. Wraps the content in the platform's required format (frontmatter, config structure, etc.).

26. Writes the output to the platform's expected file path.

**8.3 Platform-Specific Considerations**

While the core logic is identical, each platform has behavioral differences that the adapter must account for in its instruction wrapping:

  ----------------------------------------------------------------------------------------------------------------------------------------------
  **Platform**            **Permission Model**                       **Adapter Note**
  ----------------------- ------------------------------------------ ---------------------------------------------------------------------------
  Claude Code             Runs bash freely                           No special handling needed

  Cursor                  May prompt user before terminal commands   Instructions include guidance to explain what scan.sh does before running

  Windsurf                Cascade agent runs with approval           Instructions note that scan.sh is read-only and safe to approve

  Aider                   Explicit /run command required             Instructions guide the AI to suggest the /run command to the user

  Continue                Agent mode with tool approval              Instructions include approval context for terminal tool use
  ----------------------------------------------------------------------------------------------------------------------------------------------

**8.4 Path Resolution**

All instruction files tell the AI to resolve paths relative to the project root. The scanner validates it is running from a directory containing ./vdocs/ and exits with a clear error if not. This prevents path-related issues across platforms that may resolve working directories differently.

**9. Edge Cases & Mitigations**

**9.1 Multi-Developer, Multi-Platform Teams**

Developer A uses Claude Code, Developer B uses Cursor. Both work on the same repo.

-   **How it works:** Both developers share the same vdocs/.vdoc/ tools, \_manifest.json, and generated docs. Only their platform-specific instruction files differ, and those are gitignored.

-   **Risk:** Both run vdoc update simultaneously and push, causing a merge conflict on \_manifest.json or doc files.

-   **Mitigation:** The manifest uses deterministic key ordering and consistent formatting. Documentation files are section-based. Git merges resolve cleanly in most cases. True conflicts are resolved manually, same as code conflicts.

**9.2 Platform Instruction Files in Git**

If a platform-specific file accidentally gets committed, developers using other tools see an irrelevant config file.

-   **Mitigation:** The installer automatically adds the generated instruction file path to .gitignore. The only committed vdoc files are inside vdocs/ (universal).

**9.3 Platform Format Changes**

A supported tool changes its instruction file format (e.g. Cursor moves from .cursor/rules/ to a new directory).

-   **Mitigation:** Only the affected adapter script needs updating. Core instructions don't change. Adapters can be versioned independently for migration support.

**9.4 Varying AI Capabilities**

Different AI models behind different tools may interpret the same instructions with varying quality. A less capable model might miss the diff-aware update logic and regenerate entire pages.

-   **Mitigation:** Instructions are written with explicit, numbered steps and validation checkpoints. No step relies on the AI inferring multi-step reasoning. Each instruction is atomic and verifiable.

-   **Transparency:** The README states that vdoc works best with Claude Code and Cursor (primary platforms). Other tools are supported but may produce less refined output.

**9.5 Script Execution Path Differences**

Claude Code resolves ./vdocs/.vdoc/scan.sh relative to the project root. Another tool might resolve it relative to the current file.

-   **Mitigation:** Instructions explicitly tell the AI to cd to the project root before running the scanner. scan.sh validates its execution context and errors with a clear message if not in the right directory.

**9.6 Partial Installation**

The installer is interrupted mid-execution (network failure during download, Ctrl+C).

-   **Mitigation:** The installer downloads to a temporary directory first, then copies atomically. If interrupted, no partial state is left in the project. Re-running the installer completes cleanly.

**9.7 Concurrent Updates from Multiple Tools**

A developer has both Claude Code and Cursor installed. They accidentally trigger vdoc update from both tools simultaneously.

-   **Mitigation:** The instructions tell the AI to check for a .vdoc.lock file before starting an update. If present, the AI informs the user another update is in progress. The lock file includes a timestamp and is automatically cleaned up if stale (older than 10 minutes).

**10. Developer Experience**

**10.1 Complete User Journey**

**Day 1: Install (Cursor Example)**

> \$ curl -fsSL vdoc.dev/install \| bash -s \-- cursor
>
> ✓ Detected: TypeScript (tsconfig.json found)
>
> ✓ Copied vdoc tools to ./vdocs/.vdoc/
>
> ✓ Generated .cursor/rules/vdoc.md
>
> ✓ Added .cursor/rules/vdoc.md to .gitignore
>
> ✓ Created ./vdocs/ directory
>
> Next: Open Cursor and ask \"generate my documentation\"

**Day 1: First Generation**

> \> generate documentation for this project
>
> \[AI runs scan.sh, proposes structure, user confirms\]
>
> \[AI generates docs, writes \_manifest.json\]
>
> ✓ Created vdocs/overview.md
>
> ✓ Created vdocs/api-reference.md
>
> ✓ Created vdocs/architecture.md
>
> ✓ Created vdocs/\_manifest.json

**Day 30: After Code Changes**

> \> vdoc update
>
> \[AI runs scan.sh, compares hashes against \_manifest.json\]
>
> 3 files changed, 2 new files, 1 deleted file.
>
> Updating vdocs/api-reference.md (2 endpoints changed)
>
> Adding payments section to vdocs/api-reference.md
>
> Flagging removed auth helper in vdocs/architecture.md
>
> ✓ Documentation updated.

**New Teammate Joins (Uses Claude Code)**

> \$ git clone project-repo && cd project-repo
>
> \$ curl -fsSL vdoc.dev/install \| bash -s \-- claude
>
> ✓ Found existing vdocs/.vdoc/ (tools already present)
>
> ✓ Generated \~/.claude/skills/vdoc/SKILL.md
>
> ✓ Ready to use
>
> \$ claude
>
> \> read \_manifest.json and explain the project architecture

**10.2 Using the Manifest as AI Context**

Beyond vdoc's own workflows, the manifest is a universal context file for any AI interaction, regardless of which platform the developer uses:

-   **Pre-refactoring:** \"Read vdocs/\_manifest.json, then refactor src/api/auth.ts.\" The AI understands intended behavior from documentation before touching code.

-   **Onboarding:** \"Based on \_manifest.json, what should I read first?\" The AI recommends pages based on audience tags.

-   **PM context:** \"Read \_manifest.json and explain the payments feature to a non-technical stakeholder.\"

-   **Code review:** \"Read \_manifest.json, then review this PR for consistency with documented architecture.\"

**11. Instruction Architecture**

**11.1 Writing for Multiple Models**

The instructions.md file must work across different AI models with varying capabilities. Design rules:

-   **Explicit over implicit.** Every step is numbered and atomic. No step assumes the AI will infer a multi-step process.

-   **Validation checkpoints.** After critical operations (scan, manifest update), include a verification step: "Confirm the manifest has N entries matching the scan output."

-   **No model-specific features.** Instructions use standard markdown. No XML tags, no model-specific tokens, no system-prompt conventions.

-   **Graceful degradation.** If the AI cannot execute a step (e.g. fails to run scan.sh), the instructions tell it to ask the user for help rather than silently failing.

**11.2 Instruction Sections**

The instructions.md is organized into clearly separated sections that map to vdoc's workflows:

  ---------------------------------------------------------------------------------------------------------------------------------------
  **Section**             **Content**                                                           **When Used**
  ----------------------- --------------------------------------------------------------------- -----------------------------------------
  Identity                What vdoc is, what it does, trigger phrases                           Always loaded

  Init Flow               First-run detection, scanning, proposing structure, generating docs   When \_manifest.json absent

  Update Flow             Hash comparison, three-bucket sorting, diff-aware patching            When \_manifest.json present

  Description Strategy    Three-pass tiered approach rules                                      During init and update

  User-Added Sections     auto/explicit/none handling for custom sections                       When user edits manifest or adds topics

  Manifest Schema         Exact JSON structure with field descriptions                          During manifest read/write

  Error Handling          What to do when scan fails, files are missing, or conflicts arise     On failure conditions
  ---------------------------------------------------------------------------------------------------------------------------------------

**12. Documentation Taxonomy & Diagram Guidelines**

vdoc generates documentation across a defined taxonomy of page types. Each type has specific content requirements and, where visual communication adds genuine value, Mermaid diagram guidelines. Not every page needs a diagram. Diagrams are included only when they clarify relationships, flows, or architecture that prose alone cannot efficiently convey.

**12.1 Diagram Rules**

When the AI determines a diagram is appropriate for a documentation page, the following rules apply:

-   **Maximum 7 nodes per diagram.** Diagrams with more than 7 nodes become unreadable. If a concept requires more, the AI splits it into 2--3 focused diagrams, each with a clear title explaining the view it represents (e.g., "Authentication Flow: Login" and "Authentication Flow: Token Refresh" rather than one 12-node diagram).

-   **Diagram type matches content.** Flowcharts for request/data flows and decision paths. Sequence diagrams for multi-actor interactions (user → frontend → backend → database). ER diagrams for data model relationships. The AI selects the appropriate type rather than defaulting to flowcharts.

-   **Every diagram gets a descriptive caption.** A one-line caption above the diagram explains what the reader should take away. Not "Architecture Diagram" but "How a request flows from the client through middleware to the database."

-   **Diagrams supplement prose, never replace it.** The paragraph before the diagram sets context. The diagram provides the visual. The paragraph after highlights what to notice. A reader who cannot render Mermaid should still understand the documentation from prose alone.

**12.2 Documentation Types and Diagram Mapping**

The following table defines each documentation type, its purpose, and whether diagrams are expected. Diagrams are only included when they genuinely aid comprehension; a page that does not benefit from a visual should not include one.

  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  **Doc Type**                         **Diagram Guidance**                                                                                                                                                                                                             **Diagram Type**
  ------------------------------------ -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- ----------------------
  **Project Overview**                 No diagrams by default. Optional: one high-level system context diagram if the project integrates with many external services.                                                                                                   Flowchart (optional)

  **Architecture**                     2--3 diagrams expected. System overview (max 7 nodes), request lifecycle, and optionally a component relationship diagram. Split into "high-level overview" and "detailed subsystem" views if the system exceeds 7 components.   Flowchart, Sequence

  **API Reference**                    1 diagram. The middleware/request pipeline showing the shared processing chain: request → rate limiter → auth → validation → handler → response.                                                                                 Flowchart

  **Data Model**                       1--2 diagrams. Entity relationships showing how models connect. Split into core entities and secondary entities if the schema has more than 7 models.                                                                            ER Diagram

  **Authentication & Authorization**   1--2 sequence diagrams. Login flow and token refresh flow. Auth flows are notoriously confusing in prose; sequence diagrams showing the actor interactions are significantly clearer.                                            Sequence Diagram

  **Feature Guides**                   1 diagram per feature. Data flow for the specific feature. If the feature touches many services, split into "happy path" and "error/edge case" diagrams.                                                                         Flowchart

  **Configuration & Deployment**       No diagrams by default. This is reference material (environment variables, config tables). Optional: 1 deployment pipeline diagram if CI/CD is present.                                                                          Flowchart (optional)
  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

**13. Open Design Questions**

The following decisions remain open and should be resolved during implementation:

  ------------------------------------------------------------------------------------------------------------------------------------------------------------------
  **Question**              **Options**                                         **Consideration**
  ------------------------- --------------------------------------------------- ------------------------------------------------------------------------------------
  Manifest location         vdocs/\_manifest.json vs project root               Root is more discoverable; inside vdocs/ keeps everything contained

  Git tracking              Which vdoc files should be committed?               vdocs/ contents and .vdoc/ tools: yes. Platform instructions: no. Scan output: no.

  Multi-language projects   One preset vs multiple presets per project          May need a vdoc.config.json for complex monorepos

  Incremental scanning      Full scan every time vs git diff based              Full scan is simpler; incremental saves time on large codebases

  Doc template format       Standardized vs freeform per section                Templates ensure consistency; freeform allows flexibility

  Lock file strategy        File-based vs timestamp-based vs advisory           File-based with stale cleanup (10 min) is simplest

  Adapter versioning        Semver per adapter vs unified version               Independent versioning handles platform changes better

  Quality variance          Accept it vs platform-specific instruction tuning   Transparent quality tiers (primary/supported) is more honest
  ------------------------------------------------------------------------------------------------------------------------------------------------------------------

**14. Roadmap**

**Phase 1: Core Tool (Single Platform)**

-   install.sh with Claude Code adapter

-   scan.sh with TypeScript/JavaScript and Python presets

-   instructions.md with init and update workflows

-   \_manifest.json generation and hash-based diffing

-   Basic documentation generation from source

-   Tiered description strategy (docstring / inferred / analyzed)

**Phase 2: Multi-Platform Launch**

-   Cursor adapter and testing

-   Windsurf adapter and testing

-   Aider adapter and testing

-   Continue (VS Code) adapter and testing

-   \--auto flag for install.sh

-   Uninstall command

-   Teammate onboarding flow (setup.sh from existing vdocs/.vdoc/)

**Phase 3: Language Expansion**

-   Go, Rust, and Java presets

-   Custom preset support in vdocs/.vdoc/presets/

-   Improved docstring extraction per language

-   default.conf fallback for unrecognized languages

**Phase 4: Advanced Features**

-   Dependency tracking between files in the source index

-   Incremental scanning via git diff for large codebases

-   Multi-language project support with composite presets

-   Documentation quality scoring (coverage, freshness, completeness)

-   .vdoc.lock file for concurrent update prevention

**Phase 5: Ecosystem**

-   Claude Code Plugin distribution via /plugin install

-   Community preset repository

-   CI/CD integration for automated documentation freshness checks

-   Export to Notion, Confluence, GitBook

-   New platform adapters as the ecosystem evolves

*End of Document*

vdoc v2.0 Product Specification • February 2026
