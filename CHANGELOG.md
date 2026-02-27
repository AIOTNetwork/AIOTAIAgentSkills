# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.1] - 2026-02-27

### Added

- **plancraft**: team-based implementation workflow with multi-agent coordination
  - Role-based agent spawning (frontend-dev, backend-dev, tester, reviewer, etc.)
  - Task delegation from plan.md todo items with dependency tracking
  - Team lifecycle management (create, monitor, finalize, shutdown)
  - Team prompt template for consistent teammate instructions
  - Solo implementation preserved as fallback for simple tasks
- Expanded plancraft allowed-tools to include Task, Team, and SendMessage tools

## [1.3.0] - 2026-02-23

### Added

- **plancraft** skill: plan-first development workflow with human-in-the-loop review gates
  - 7 phases: Research → Plan → Annotate → Todo → Implement → Resume → Status
  - Phase gates enforce human approval before code is written
  - Annotation syntax (`[NOTE]`, `[REJECT]`, `[CONSTRAINT]`, `[QUESTION]`) for structured feedback
  - Resume phase for session recovery after context compaction
  - Git integration: `plancraft/<feature>` branching convention
  - Language-agnostic with customizable validation rules (TS, Python, Go, Rust examples)
  - `.plancraft/` directory option for clean project roots
  - Resolved annotations audit trail
- Updated README with plancraft documentation
- Updated plugin keywords and marketplace description

## [1.2.0] - 2026-01-25

### Added

- Auto-trigger hook: automatically runs pre-commit checks when git commit is detected
- Hook script supports Node.js, Python, Rust, and Go projects

## [1.1.0] - 2026-01-25

### Added

- Auto-changelog workflow: generates CHANGELOG.md entries from commit history
- Pre-commit hooks workflow: runs linters, formatters, type checks before commits
- Version bump workflow: suggests semantic version bumps based on commit types
- Multi-language support for pre-commit (Node.js, Python, Rust, Go)

### Changed

- Renamed skill from `commit-standards` to `smart-commit`
- Updated skill description to reflect new capabilities

## [1.0.0] - 2026-01-21

### Added

- Initial release as Claude Code plugin
- `smart-commit` skill for Angular Commit Convention enforcement
  - Atomic commit analysis and suggestions
  - Auto-commit with generated messages
  - Support for scope, body, and footer
  - Breaking change detection
  - Issue reference linking
  - Edge case handling (merge conflicts, sensitive files, WIP code)
- Plugin marketplace support for easy installation
