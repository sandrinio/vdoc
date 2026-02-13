# Exploration Strategies

Smart, targeted codebase exploration. Two phases: fingerprint the project, then follow the right archetype playbook.

## Phase 1 — Fingerprint

Read these high-signal files first (whichever exist) to classify the project. **3-5 reads max.**

### Package / Config Files (read 1-2)

| File | Ecosystem |
|------|-----------|
| `package.json` | Node.js / JavaScript / TypeScript |
| `pyproject.toml` / `setup.py` / `requirements.txt` | Python |
| `go.mod` | Go |
| `Cargo.toml` | Rust |
| `Gemfile` | Ruby |
| `pom.xml` / `build.gradle` | Java / Kotlin |
| `composer.json` | PHP |
| `*.csproj` / `*.sln` | .NET |
| `pubspec.yaml` | Dart / Flutter |

### Structure Scan

- List root directory
- List `src/` or `app/` or `lib/` (whichever exists)

### Entry Points (read 1-2)

- README.md (first 50 lines)
- Main entry file (e.g., `src/index.ts`, `main.py`, `cmd/main.go`)

### Determine

1. **Primary language(s)** and framework(s)
2. **Project archetype** — match to a playbook below
3. **Rough scope** — small (< 20 files), medium (20-100), large (100+)

If the project spans multiple archetypes (e.g., monorepo with frontend + API), apply multiple playbooks.

---

## Phase 2 — Archetype Playbooks

Match the detected archetype and follow its playbook. Each defines:
- **Glob patterns** — files to read, in priority order
- **What to extract** — what each file category reveals
- **Feature signals** — patterns that indicate documentable features

---

### Web API

**Signals:** Express, FastAPI, Django REST, Rails, Spring Boot, Gin, Actix, Phoenix, Hono, NestJS

| Priority | Glob Pattern | What to Extract |
|----------|-------------|-----------------|
| 1 | `**/routes/**`, `**/router.*`, `**/urls.py` | Endpoints, HTTP methods, URL structure |
| 2 | `**/middleware/**`, `**/middleware.*` | Auth, CORS, rate limiting, logging, error handling |
| 3 | `**/models/**`, `**/schema*`, `**/migrations/**` | Data model, entities, relationships |
| 4 | `**/controllers/**`, `**/handlers/**`, `**/views/**` | Business logic per endpoint |
| 5 | `**/services/**`, `**/lib/**` | Shared logic, external integrations |
| 6 | `**/config/**`, `.env*`, `**/settings*` | Environment config, feature flags |
| 7 | `**/tests/**` (skim 2-3) | What's tested reveals what matters |

**Feature signals:**
- Auth routes/middleware → Authentication doc
- Payment/billing routes → Payments doc
- File upload handlers → File Management doc
- WebSocket/SSE handlers → Real-time doc
- Background jobs/queues → Background Processing doc
- Email/notification services → Notifications doc
- Search endpoints → Search doc
- Admin routes → Admin Panel doc

---

### Frontend SPA

**Signals:** React (CRA/Vite), Vue, Svelte, Angular, Solid

| Priority | Glob Pattern | What to Extract |
|----------|-------------|-----------------|
| 1 | `**/pages/**`, `**/views/**`, `**/routes*` | Page tree, routing structure |
| 2 | `**/store/**`, `**/context/**`, `**/state/**`, `**/*slice*` | State shape, data flow |
| 3 | `**/api/**`, `**/services/**`, `**/hooks/use*` | API integration, data fetching |
| 4 | `**/components/**` (skim top-level) | Component architecture, shared vs feature |
| 5 | `**/types/**`, `**/interfaces/**`, `**/*.d.ts` | Data contracts, shared types |
| 6 | `**/utils/**`, `**/helpers/**` | Shared utilities |
| 7 | `**/config/**`, `.env*` | Feature flags, API URLs, build config |

**Feature signals:**
- Auth context/store + login pages → Authentication doc
- Form components + validation → Forms doc
- Data tables with pagination → Data Display doc
- Charts/dashboards → Analytics doc
- Theming/i18n files → Theming / Internationalization doc
- File upload components → Media Management doc

---

### Full-Stack Framework

**Signals:** Next.js, Nuxt, SvelteKit, Remix, RedwoodJS, Blitz, Astro (SSR)

| Priority | Glob Pattern | What to Extract |
|----------|-------------|-----------------|
| 1 | `**/app/**/page.*`, `**/pages/**`, `**/routes/**` | UI pages AND API routes — the router is the architecture |
| 2 | `**/api/**`, `**/server/**`, `**/actions/**` | Server-side logic, server actions |
| 3 | `**/models/**`, `**/schema*`, `**/prisma/**`, `**/drizzle/**` | Data layer, ORM config |
| 4 | `**/middleware.*`, `**/middleware/**` | Request pipeline, auth, redirects |
| 5 | `**/components/**` (skim top-level) | Shared UI components |
| 6 | `**/lib/**`, `**/utils/**`, `**/services/**` | Shared server + client utilities |
| 7 | `**/config/**`, `.env*`, `next.config.*`, `nuxt.config.*` | Framework and environment config |

**Feature signals:**
- All Web API signals + all Frontend SPA signals
- Server actions / mutations → Data Mutation doc
- ISR/SSG configuration → Rendering Strategy doc
- Edge functions / middleware → Edge Computing doc

---

### CLI Tool

**Signals:** Commander, Yargs, Click, Typer, Cobra, Clap, oclif, Argparse

| Priority | Glob Pattern | What to Extract |
|----------|-------------|-----------------|
| 1 | `**/commands/**`, `**/cmd/**`, `**/cli.*` | Command tree, subcommands |
| 2 | Main entry (`bin/*`, `src/index.*`, `src/main.*`) | Argument parsing, top-level flow |
| 3 | `**/config*`, `**/*rc*`, `**/settings*` | Config file formats, defaults |
| 4 | `**/utils/**`, `**/lib/**`, `**/core/**` | Core logic behind commands |
| 5 | `**/output*`, `**/format*`, `**/display*` | Output formatting (JSON, table, etc.) |
| 6 | `**/templates/**`, `**/scaffolds/**` | Code generation templates |

**Feature signals:**
- Multiple subcommands → one doc per command group
- Config file handling → Configuration doc
- Plugin/extension system → Plugin Architecture doc
- Interactive prompts → User Interaction doc
- File I/O operations → File Processing doc

---

### Library / SDK

**Signals:** Published package with `main`/`exports` in package.json, `lib/` with clear public API, type declarations

| Priority | Glob Pattern | What to Extract |
|----------|-------------|-----------------|
| 1 | Main export (`src/index.*`, `lib/index.*`, `__init__.py`) | Public API surface |
| 2 | `**/*.d.ts`, `**/types.*`, `**/interfaces.*` | Type contracts, input/output shapes |
| 3 | `**/core/**`, `**/lib/**` | Internal implementation |
| 4 | `**/utils/**`, `**/helpers/**` | Supporting utilities |
| 5 | `**/examples/**`, `**/demo/**` | Usage patterns |
| 6 | `**/plugins/**`, `**/adapters/**`, `**/providers/**` | Extension points |
| 7 | `**/tests/**` (skim 2-3) | Edge cases, expected behavior |

**Feature signals:**
- Multiple exported classes/functions → Core API doc
- Plugin/adapter pattern → Extension Architecture doc
- Multiple output formats → Serialization doc
- Caching layer → Performance doc

---

### Mobile App

**Signals:** React Native, Flutter, SwiftUI, Jetpack Compose, Expo, Ionic, Capacitor

| Priority | Glob Pattern | What to Extract |
|----------|-------------|-----------------|
| 1 | `**/screens/**`, `**/pages/**`, `**/views/**` | Screen tree, navigation structure |
| 2 | `**/navigation/**`, `**/router*` | Navigation graph, deep linking |
| 3 | `**/store/**`, `**/state/**`, `**/providers/**` | State management, data flow |
| 4 | `**/api/**`, `**/services/**`, `**/network/**` | Backend communication, offline sync |
| 5 | `**/components/**` (skim) | Shared UI components |
| 6 | `**/native/**`, `**/platform/**`, `**/ios/**`, `**/android/**` | Platform-specific code, native modules |
| 7 | `**/assets/**` (list only) | Bundled resources |

**Feature signals:**
- Push notification setup → Notifications doc
- Camera/media access → Media Capture doc
- Offline storage (SQLite, Realm, AsyncStorage) → Data Persistence doc
- Deep linking / universal links → Navigation doc
- Platform-specific native modules → Platform Integration doc

---

### Data Pipeline / ML

**Signals:** Airflow, dbt, Prefect, Dagster, Luigi, Pandas, Spark, TensorFlow, PyTorch, scikit-learn, Jupyter notebooks

| Priority | Glob Pattern | What to Extract |
|----------|-------------|-----------------|
| 1 | `**/dags/**`, `**/pipelines/**`, `**/flows/**`, `**/workflows/**` | Pipeline definitions, DAGs, task graph |
| 2 | `**/models/**` (ML or dbt) | Model definitions, training logic or SQL transforms |
| 3 | `**/sources/**`, `**/extractors/**`, `**/connectors/**` | Data sources, ingestion logic |
| 4 | `**/transforms/**`, `**/processors/**` | Data transformation logic |
| 5 | `**/schemas/**`, `**/contracts/**` | Data contracts, validation |
| 6 | `**/notebooks/**`, `*.ipynb` | Exploratory analysis, experiments |
| 7 | `**/config/**`, `**/profiles*` | Connection strings, environment config |

**Feature signals:**
- Multiple DAGs/pipelines → one doc per pipeline
- ML model training → Model Training doc
- Feature engineering → Feature Store doc
- Data validation (Great Expectations, Pandera) → Data Quality doc
- Scheduled runs → Orchestration doc

---

### Monorepo

**Signals:** Turborepo, Nx, Lerna, Rush, Bazel, pnpm workspaces — has `packages/`, `apps/`, or `workspace` config

| Priority | Glob Pattern | What to Extract |
|----------|-------------|-----------------|
| 1 | Root config (`turbo.json`, `nx.json`, `lerna.json`, `pnpm-workspace.yaml`) | Workspace structure, build pipeline |
| 2 | `packages/*/package.json` or `apps/*/package.json` | All packages/apps and their dependencies |
| 3 | `**/shared/**`, `**/common/**`, `**/core/**` | Shared packages that others depend on |
| 4 | Each app/package entry point (skim) | Purpose of each workspace member |

**Then apply the matching sub-archetype playbook** to each significant package/app (e.g., Web API for the backend, Frontend SPA for the frontend, Library for shared packages).

**Feature signals:**
- Shared packages → Shared Infrastructure doc
- Build/deploy pipeline → Build System doc
- Inter-package dependencies → Architecture Overview doc (dependency graph)

---

### Microservices

**Signals:** Docker Compose, Kubernetes manifests, multiple services with separate entry points, API gateway, service mesh

| Priority | Glob Pattern | What to Extract |
|----------|-------------|-----------------|
| 1 | `docker-compose*`, `**/k8s/**`, `**/helm/**`, `**/terraform/**` | Service topology, infrastructure |
| 2 | API gateway config, `**/gateway/**` | Routing, load balancing, auth gateway |
| 3 | Each service's entry point and routes (skim) | Service responsibilities, API surface |
| 4 | `**/proto/**`, `**/graphql/**`, `**/schemas/**` | Inter-service contracts (gRPC, GraphQL) |
| 5 | `**/queues/**`, `**/events/**`, `**/messaging/**` | Async communication, event bus |
| 6 | `**/shared/**`, `**/common/**` | Shared libraries across services |

**Then apply the Web API playbook** to each significant service.

**Feature signals:**
- Service discovery → Service Mesh doc
- Event-driven communication → Event Architecture doc
- Shared vs per-service database → Data Architecture doc
- Health checks / circuit breakers → Resilience doc

---

### Infrastructure / IaC

**Signals:** Terraform, Pulumi, CloudFormation, Ansible, CDK, Serverless Framework

| Priority | Glob Pattern | What to Extract |
|----------|-------------|-----------------|
| 1 | `**/main.tf`, `**/stacks/**`, `**/lib/**` (CDK) | Resource definitions, stack structure |
| 2 | `**/variables*`, `**/inputs*`, `**/config*` | Parameterization, environment configs |
| 3 | `**/modules/**`, `**/constructs/**` | Reusable infrastructure modules |
| 4 | `**/environments/**`, `**/stages/**` | Environment-specific overrides |
| 5 | `**/outputs*`, `**/exports*` | Cross-stack references |
| 6 | CI/CD config (`.github/workflows/`, `Jenkinsfile`) | Deployment pipeline |

**Feature signals:**
- Networking (VPC, subnets, security groups) → Networking doc
- Compute (ECS, Lambda, EC2) → Compute Architecture doc
- Data stores (RDS, DynamoDB, S3) → Data Infrastructure doc
- CI/CD pipeline → Deployment Pipeline doc
- Monitoring (CloudWatch, Datadog) → Observability doc

---

## Fallback — Unknown Archetype

If the project doesn't clearly match any archetype:

1. List the root directory and `src/` (or equivalent)
2. Read the top 5 largest files by line count
3. Read any files with "main", "app", "server", "index", or "core" in the name
4. Check test files — they reveal what developers think is important
5. Check CI/CD config (`.github/workflows/`, `Jenkinsfile`) — pipeline steps reveal build/deploy architecture

Then propose an archetype to the user: *"This looks like a [X] project. I'll explore it using the [X] playbook. Sound right?"*
