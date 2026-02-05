# Changelog

All notable changes to vdoc will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial project structure
- Core scanner placeholder (`core/scan.sh`)
- Universal instructions (`core/instructions.md`)
- Language presets: TypeScript, Python, Default
- Platform adapter scaffolding: Claude, Cursor, Windsurf, Aider, Continue
- Universal installer placeholder (`install.sh`)
- CI workflow with shellcheck and bats
- Project documentation: README, CONTRIBUTING, LICENSE

### Design Decisions (EPIC-000)
- Manifest location: `vdocs/_manifest.json`
- Git tracking: Commit tools, docs, manifest; gitignore platform files
- Multi-language: Support from start via `vdoc.config.json`
- Incremental scanning: Full scan for Phase 1
- Doc templates: Hybrid (standard + overrides)
- Lock file: File-based with 10-min stale cleanup
- Adapter versioning: Unified
- Quality variance: Accept + transparent tiers

---

## [2.0.0] - TBD

Initial release of vdoc v2.

### Planned
- EPIC-001: Core Scanner & Manifest System
- EPIC-002: Claude Code Adapter & Installation
- EPIC-003: Documentation Generation Engine
- EPIC-004: Multi-Platform Adapters
- EPIC-005: Language Presets Expansion
- EPIC-006: Advanced Features
- EPIC-007: Ecosystem & Distribution
