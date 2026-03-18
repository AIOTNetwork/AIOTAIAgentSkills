# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.7.0] - 2026-03-17

### Added

- **pixijs-hud**: new skill for responsive game HUD/UI design with PixiJS 8.x
  - HUD architecture: layered rendering, static/dynamic separation, render groups
  - Screen scaling: scale factor, letterbox, viewport fill strategies
  - Anchor-based positioning, safe zones for notched displays, touch-friendly sizing
  - 10 HUD component patterns: health bar, score, minimap, dialog box, inventory grid, touch joystick, damage numbers, cooldown indicator, toast notifications, FPS counter
  - @pixi/layout flexbox patterns for menus, settings panels, HUD bars
  - Resolution independence, multi-resolution assets, breakpoint-based layouts

## [1.6.0] - 2026-03-17

### Changed

- **pixijs**: rewrite skill for high-performance HTML5 game development
  - SKILL.md restructured as game development workflow guide (bootstrap, scenes, input, camera, collision, pooling)
  - New `references/game-architecture.md` — scene management, input system, camera, collision, spatial hash, object pooling, FSM, entity pattern
  - New `references/ecosystem.md` — integration guides for @pixi/sound, pixi-viewport, @pixi/tilemap, @pixi/ui, @pixi/particle-emitter, Matter.js, Spine v8, pixi-filters
  - Rewritten `references/performance.md` — game-focused: draw call budgets, fixed timestep, spatial partitioning, ParticleContainer, memory lifecycle, mobile targets, profiling
  - Updated `references/api-patterns.md` — added AnimatedSprite and ParticleContainer v8 sections
  - Updated description triggers with game-specific keywords (HTML5 game, collision, tilemap, camera, pooling, etc.)

## [1.5.0] - 2026-03-17

### Added

- **pixijs**: new skill for building 2D graphics, games, and animations with PixiJS 8.x
  - Core workflow: app init, scene graph, render loop, sprites, graphics, text, filters, interaction
  - Reference guides: full API patterns, performance optimization, v7→v8 migration
  - Covers WebGL/WebGPU rendering, asset management, custom shaders, Spine integration

## [1.4.5] - 2026-03-12

### Fixed

- **plancraft**: remove duplicated team-based implementation rule from `references/team-workflow.md` (already in SKILL.md Phase 5)

## [1.4.4] - 2026-03-12

### Changed

- **plancraft**: enforce mandatory team-based implementation when Agent tool is available
  - Added explicit rule in Phase 5 requiring agent teams when plan defines Team Roles
  - Added "implement solo when agents are available" as an anti-pattern

## [1.4.3] - 2026-03-06

### Added

- **CLAUDE.md**: project-wide conventions shared via git (release workflow, skill development best practices, commit convention, plancraft team requirements)

## [1.4.2] - 2026-03-06

### Fixed

- **smart-commit hook**: replace crude 100-char length check with multi-signal trigger detection
  - Slash commands (`/commit`, `/smart-commit`) always trigger immediately
  - Position-based: "commit" must be an action word near the start, not a discussion mention
  - Git state: only trigger when there are actual changes to commit
  - Skip when "commit" is preceded by articles/prepositions ("the commit", "about commits")

## [1.4.1] - 2026-03-04

### Changed

- **plancraft**: restructure SKILL.md with progressive disclosure (845 → 260 lines)
  - Split team workflow, prompt templates, and plan template into `references/`
  - Fix invalid frontmatter fields (`allowed-tools`, `argument-hint`)
  - Enrich description with trigger keywords for better skill activation
- **smart-commit**: restructure SKILL.md with progressive disclosure (489 → 133 lines)
  - Split pre-commit workflow and edge cases/examples into `references/`
  - Fix invalid frontmatter fields
  - Condense Angular commit convention boilerplate
  - Enrich description with trigger keywords

### Removed

- Empty `sprite-gen` skill directory

## [1.4.0] - 2026-03-03

### Added

- **plancraft**: self-iterating quality engine with two-stage verification
  - Definition of Done with minimum and quality bars as verification rubric
  - Two-stage verify-iterate loop: `qa-verifier` (technical) → `product-manager` (product)
  - 7-category QA verification checklist (build, tests, lint, security, integration, plan adherence, NFRs)
  - Cosmetic vs functional fix classification — cosmetic PM fixes skip QA re-review
  - Iteration budget (max 3 cycles per task) with escalation triggers
  - Structured communication protocol (QA PASS/FAIL, PM PASS/FAIL message formats)
  - Regression protocol for fix tasks with full suite re-runs
  - Staggered agent spawning (QA/PM spawn when work is ready, not at team creation)
  - Task graph validation step (Step 2.5) before spawning teammates
  - Deadlock detection checklist for team lead
  - Human-reviewable Team Roles section in plan.md template
  - Quality Metrics table for tracking verdicts and fix iterations per task
  - Phase 5.5 Retrospective for post-implementation learning
  - Discovered Knowledge section for capturing technical insights during implementation
  - Non-Functional Requirements section in plan.md (performance, security, accessibility)

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
