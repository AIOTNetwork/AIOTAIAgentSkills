---
name: plancraft
description: "Plan-first development workflow. Enforces Research → Plan → Annotate → Implement phases with human-in-the-loop review gates. Never write code until the plan is approved. Use for any non-trivial feature, refactor, or bug investigation. Triggers on: research, plan, annotate, todo, implement, resume, status, team-based implementation, multi-agent coordination, code review workflow, plan-first development."
---

# Plancraft — Plan-First Development Workflow

**Core principle:** Never write code until you've produced a written plan and the human has reviewed and approved it.

## When to Use

Use when: changes span >1 file, estimated work is >30 minutes, architectural decisions are involved, you're unfamiliar with the subsystem, the change has downstream dependencies, or bug root cause is unclear.

Skip when: one-line fix, typo/formatting, adding a simple test, config changes with no logic.

---

## The Flow

```
Research → Plan → Annotate (1-6x) → Todo → Implement → Feedback
                                              ↑
                                          Resume (if session interrupted)
```

Each phase produces a **persistent markdown artifact**. Never give verbal summaries — always write to files.

### Artifact Location

```
.plancraft/
├── research.md
├── plan.md
└── references/       # optional: reference implementations
```

Add `.plancraft/` to `.gitignore` if artifacts shouldn't be committed.

### Definition of Done

Every task must meet ALL criteria before it can pass verification:

**Minimum Bar (non-negotiable):**
- [ ] Tests pass (existing + new where applicable)
- [ ] No regressions introduced
- [ ] Follows codebase conventions
- [ ] Plan adherence — implements exactly what was specified

**Quality Bar (required for task approval):**
- [ ] Code is clean — no dead code, no commented-out blocks, no TODOs left behind
- [ ] Edge cases from research.md are handled
- [ ] Error paths are covered, not just happy paths
- [ ] Changes are minimal — no unnecessary refactoring beyond the plan

Both `qa-verifier` and `product-manager` use this as their rubric.

---

## Phase 1: Research

**Trigger:** `plancraft research` or starting any non-trivial task.

1. Read the target code **deeply** — implementations, edge cases, patterns
2. Understand dependencies, data flow, existing conventions
3. Write everything to `research.md`

### research.md must include:
- Architecture overview of the relevant subsystem
- Key files and their responsibilities
- Data flow and state management patterns
- Existing conventions (naming, patterns, libraries used)
- Potential gotchas, edge cases, or fragile areas
- Dependencies that could be affected by changes

### ⛔ PHASE GATE: Stop here.
> "Research complete. Written to `research.md`. Please review before I proceed to planning."

---

## Phase 2: Plan

**Trigger:** Human approves research, or `plancraft plan`.

Produce a detailed implementation plan in `plan.md`. Use the template from [references/plan-template.md](references/plan-template.md).

### Key rules:
- Base the plan on **actual codebase** — read source files before suggesting changes
- Include **code snippets** showing the real changes, not pseudocode
- Reference **existing patterns** in the codebase
- **Populate the Team Roles section** — identify specialist roles needed, with justification. Only propose roles the plan actually requires
- Fill in **Non-Functional Requirements** if applicable (performance, security, accessibility)

### ⛔ PHASE GATE: Stop here.
> "Plan written to `plan.md`. Please review and add any inline annotations before I proceed."

---

## Phase 3: Annotation Cycle

**Trigger:** Human says they've added notes, or `plancraft annotate`.

Human adds inline notes using `> **[NOTE]:**` prefix. Annotation types:

| Prefix | Meaning |
|--------|---------|
| `[NOTE]` | General feedback |
| `[REJECT]` | Remove this section |
| `[CONSTRAINT]` | Hard rule, don't change |
| `[QUESTION]` | Agent should answer |

Address **ALL** annotations. Move resolved notes to the **Resolved Annotations** section. Never jump to code during annotation.

### ⛔ PHASE GATE: After each round, stop and ask:
> "All notes addressed. Plan updated. [N] annotations resolved. Ready for another review or shall I proceed to the todo list?"

---

## Phase 4: Todo List

**Trigger:** Human approves the plan, or `plancraft todo`.

Add a granular checklist to the Todo section of plan.md:

```markdown
## Todo
### Phase 1: [Name]
- [ ] Task 1 — specific, actionable description
- [ ] Task 2
- [ ] ✅ Validate: run typecheck

### Phase 2: [Name]
- [ ] Task 3
- [ ] ✅ Validate: run tests
```

Rules:
- Tasks should be small enough to verify individually
- Order tasks by dependency
- Include validation checkpoints (✅)
- **Update the Team Roles table** — fill in "Assigned Tasks" column

### ⛔ PHASE GATE: Stop here.
> "Todo list added to `plan.md` — [N] tasks across [M] phases. Review the breakdown and approve to start implementation."

---

## Phase 5: Implementation

**Trigger:** Human approves todo list, or `plancraft implement`.

**Goal:** Execute the plan mechanically. No creative decisions — those were made in planning.

### Pre-Flight Check (MUST run before any implementation)

**Before writing any code, execute this checklist in order:**

1. **Read `plan.md` Team Roles table** — does the plan define team roles?
2. **Check Agent tool availability** — can you spawn agents?
3. **Decision:**
   - If Team Roles exist AND Agent tool is available → **MUST use Team-Based Implementation below. No exceptions.**
   - If Team Roles exist but Agent tool is unavailable → Solo fallback (log why agents were unavailable)
   - If no Team Roles defined AND fewer than 3 todo items → Solo implementation

> ⛔ **HARD RULE:** Never skip this check. Never implement solo when the plan has Team Roles and the Agent tool is available. This is the #1 most common mistake — defaulting to solo because it's easier. Always spin up the team.

```bash
git checkout -b plancraft/<feature-name>
```

### Team-Based Implementation (Default — Required when plan has Team Roles)

See [references/team-workflow.md](references/team-workflow.md) for the full team workflow including:
- Role spawning from approved plan.md Team Roles
- Task graph validation
- Staggered agent spawning (QA/PM spawn when work is ready)
- Two-stage verify-iterate loop (qa-verifier → product-manager)
- Iteration budget (max 3 cycles), regression protocol, communication protocol
- Escalation triggers and deadlock detection

See [references/prompt-templates.md](references/prompt-templates.md) for developer, qa-verifier, and product-manager prompt templates.

### Feedback during implementation:

The human's role shifts to **supervisor**. Expect terse corrections:
- "You missed the deduplication function"
- "This should be in the admin app, not the main app — move it"
- "this table should look exactly like the users table"

### When things go wrong:
```bash
git checkout .  # Revert to clean state
```
**Never patch a bad approach. Revert and re-scope.**

### After completion:
1. **Final integration check** — run the full test suite against the complete changeset
2. **Complete retrospective** (mandatory for team implementation) — see Phase 5.5
3. **Review discovered knowledge** — decide with the human what to persist to project docs
4. **Commit** — stage specific files (avoid git add -A)
5. **Artifact cleanup** — ask the human about plan.md and research.md disposition

---

## Phase 5.5: Retrospective (Post-Implementation)

**Trigger:** All tasks approved, before final commit. **Mandatory for team-based implementation.**

Write to the **Retrospective** section of plan.md:
- Tasks completed, fix iterations required, tasks requiring >2 iterations
- What worked, what didn't work
- Actionable lessons for future sessions

If recurring patterns emerge, suggest updates to the project's CLAUDE.md or documentation.

---

## Phase 6: Resume

**Trigger:** `plancraft resume` — after context compaction, session restart, or agent handoff.

1. Read `plan.md` — understand objective, approach, all changes
2. Check the **Todo** section — identify completed (`[x]`) and remaining (`[ ]`) tasks
3. Read `research.md` if remaining tasks need context
4. Check `git diff` and `git log` for what's already implemented
5. Report status and continue

---

## Phase 7: Status Check

**Trigger:** `plancraft status` at any time.

```markdown
## Plancraft Status
**Phase:** Implementation (Phase 5)
**Branch:** plancraft/feature-name
**Progress:** 7/12 tasks complete (58%)

### Completed:
- [x] Task 1 — description

### Remaining:
- [ ] Task 8 — description

### Blockers:
- None / [describe issue]
```

---

## Quick Reference

| Command | What it does |
|---------|-------------|
| `plancraft research` | Deep-read codebase, write research.md |
| `plancraft plan` | Write implementation plan to plan.md |
| `plancraft annotate` | Address inline notes in plan.md |
| `plancraft todo` | Add granular task checklist to plan.md |
| `plancraft implement` | Execute plan on feature branch |
| `plancraft resume` | Recover context from plan.md |
| `plancraft status` | Show current phase and progress |

---

## Anti-Patterns

- **Skip research** → you'll miss conventions and break things
- **Verbal plans** → no review surface, decisions get lost
- **Jump to code** → wasted effort, wrong assumptions
- **Ignore annotations** → trust breakdown
- **Patch bad approaches** → revert and re-scope instead
- **Add features not in the plan** → scope creep
- **Rely on chat context** → plan.md is the truth
- **Implement solo when agents are available** → always use team-based implementation when the Agent tool is available and the plan has team roles
