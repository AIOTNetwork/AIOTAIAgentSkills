---
name: plancraft
description: Plan-first development workflow. Enforces Research → Plan → Annotate → Implement phases with human-in-the-loop review gates. Never write code until the plan is approved. Use for any non-trivial feature, refactor, or bug investigation.
allowed-tools: Bash, Read, Write, Edit, Grep
argument-hint: [research|plan|annotate|todo|implement|resume|status]
---

# Plancraft — Plan-First Development Workflow

**Core principle:** Never write code until you've produced a written plan and the human has reviewed and approved it.

> "Implementation should be boring. The creative work happens in the planning phase."

## When to Use Plancraft

✅ **Use when:**
- Changes span **more than 1 file**
- Estimated work is **>30 minutes**
- **Architectural decisions** are involved
- You're unfamiliar with the subsystem
- The change has **downstream dependencies**
- Bug investigation where root cause is unclear

❌ **Skip when:**
- One-line fix with obvious solution
- Typo / formatting / comment changes
- Adding a simple test for existing code
- Config changes with no logic

**Rule of thumb:** If you'd want a code review, you want plancraft.

---

## The Flow

```
Research → Plan → Annotate (1-6x) → Todo → Implement → Feedback
                                              ↑
                                          Resume (if session interrupted)
```

Each phase produces a **persistent markdown artifact**. Never give verbal summaries — always write to files.

### Artifact Location

By default, artifacts go in the **project root**. For teams that prefer a clean root:

```
.plancraft/
├── research.md
├── plan.md
└── references/       # optional: reference implementations
```

Set the location once; be consistent. Add `.plancraft/` to `.gitignore` if artifacts shouldn't be committed.

---

## Phase 1: Research

**Trigger:** `plancraft research` or starting any non-trivial task.

**Goal:** Deeply understand the relevant codebase before proposing anything.

### What to do:

1. Read the target code **deeply** — not just signatures, but implementations, edge cases, patterns
2. Understand dependencies, data flow, existing conventions
3. Write everything to `research.md`

### Research prompts (use strong language):

- "Read this folder **in depth**, understand how it works **deeply**, all its specificities"
- "Study the system **in great detail**, understand the **intricacies**"
- "Go through the flow, understand it deeply and look for potential issues — **don't stop until you've found them all**"

Without words like "deeply", "intricacies", "all specificities", the agent will skim. These signals force thorough reading.

### research.md must include:

- Architecture overview of the relevant subsystem
- Key files and their responsibilities
- Data flow and state management patterns
- Existing conventions (naming, patterns, libraries used)
- Potential gotchas, edge cases, or fragile areas
- Dependencies that could be affected by changes

### ⛔ PHASE GATE: Stop here.

> "Research complete. Written to `research.md`. Please review before I proceed to planning."

**Do NOT proceed to planning until the human confirms.**

---

## Phase 2: Plan

**Trigger:** Human approves research, or `plancraft plan`.

**Goal:** Produce a detailed implementation plan in `plan.md`.

### plan.md structure:

```markdown
# Plan: [Feature/Task Name]

## Objective
What we're building and why.

## References
<!-- Paste or link reference implementations here -->
- [Reference 1]: description of what to adopt from it
- [Reference 2]: existing pattern in our codebase to follow

## Approach
Detailed explanation of the implementation strategy.

## Changes
### file: path/to/file.ext
- What changes and why
- Code snippet showing the actual change

### file: path/to/other.ext
- ...

## Considerations
- Trade-offs and alternatives considered
- Risks and mitigation

## Open Questions
- Anything that needs human input

## Resolved Annotations
<!-- Addressed notes move here for audit trail -->

## Todo
<!-- Added in Phase 4 -->
```

### Key rules:

- Base the plan on **actual codebase** — read source files before suggesting changes
- Include **code snippets** showing the real changes, not pseudocode
- Reference **existing patterns** in the codebase — new code should look like existing code
- If a reference implementation exists (OSS, another part of the codebase), add it to the **References** section

### ⛔ PHASE GATE: Stop here.

> "Plan written to `plan.md`. Please review and add any inline annotations before I proceed."

**Do NOT proceed until the human explicitly approves.**

---

## Phase 3: Annotation Cycle

**Trigger:** Human says they've added notes, or `plancraft annotate`.

**Goal:** Refine the plan based on human feedback. Repeat 1-6 times.

### Annotation syntax:

Human adds inline notes using this format:

```markdown
> **[NOTE]:** This should be a PATCH, not a PUT.
```

Or for longer annotations:

```markdown
> **[NOTE]:** The visibility field needs to be on the list itself, not on
> individual items. When a list is public, all items are public.
> Restructure the schema section accordingly.
```

The `> **[NOTE]:**` prefix makes annotations easy to find and distinguish from plan content.

### How it works:

1. Human opens `plan.md` in their editor
2. Human adds `> **[NOTE]:**` annotations inline — right next to the relevant section
3. Human tells the agent: "I added notes, address them all"
4. Agent reads the plan, addresses **every** `[NOTE]`
5. Agent moves resolved notes to the **Resolved Annotations** section with a one-line summary
6. Repeat until human is satisfied

### Annotation types:

| Prefix | Meaning | Example |
|--------|---------|---------|
| `[NOTE]` | General feedback | "use drizzle:generate for migrations, not raw SQL" |
| `[REJECT]` | Remove this section | "remove caching entirely, we don't need it" |
| `[CONSTRAINT]` | Hard rule, don't change | "these function signatures must not change" |
| `[QUESTION]` | Agent should answer | "would this break the existing API?" |

### Critical rules:

- Address **ALL** annotations — do not skip any
- Update the plan document in-place
- **"Don't implement yet"** — this guard is mandatory. Never jump to code during annotation
- Move resolved notes to the **Resolved Annotations** section:

```markdown
## Resolved Annotations
- ~~PATCH not PUT~~ → Updated endpoint method in Changes section
- ~~Remove caching~~ → Removed section 3.2 entirely
```

### ⛔ PHASE GATE: After each annotation round, stop and ask:

> "All notes addressed. Plan updated. [N] annotations resolved. Ready for another review or shall I proceed to the todo list?"

---

## Phase 4: Todo List

**Trigger:** Human approves the plan, or `plancraft todo`.

**Goal:** Break the plan into a granular, trackable checklist.

### Add to the Todo section of plan.md:

```markdown
## Todo

### Phase 1: [Name]
- [ ] Task 1 — specific, actionable description
- [ ] Task 2
  - [ ] Subtask 2a
  - [ ] Subtask 2b
- [ ] ✅ Validate: run typecheck

### Phase 2: [Name]
- [ ] Task 3
- [ ] Task 4
- [ ] ✅ Validate: run tests
```

### Rules:

- Tasks should be **small enough to verify individually**
- Each task maps to a specific change in the plan
- Order tasks by dependency (what must happen first)
- Include **validation checkpoints** (marked with ✅): typecheck, tests, manual verification
- Estimate total task count for progress tracking

### ⛔ PHASE GATE: Stop here.

> "Todo list added to `plan.md` — [N] tasks across [M] phases. Review the breakdown and approve to start implementation."

---

## Phase 5: Implementation

**Trigger:** Human approves todo list, or `plancraft implement`.

**Goal:** Execute the plan mechanically. No creative decisions — those were made in planning.

### Before starting:

```bash
# Create a feature branch — clean state always available
git checkout -b plancraft/<feature-name>
```

### Implementation rules:

- Follow the plan **exactly** — do not deviate or add features not in the plan
- Mark tasks complete in `plan.md` as you go: `- [ ]` → `- [x]`
- Run validation commands **continuously**, not just at the end
- If you hit an unexpected issue, **stop and report** rather than improvising

### Customization (language-specific rules):

Add project-specific rules to the implementation prompt. Examples:

**TypeScript:**
```
Do not use `any` or `unknown` types.
Run `tsc --noEmit` after each phase.
```

**Python:**
```
Use type hints on all function signatures.
Run `mypy .` and `ruff check .` after each phase.
```

**Go:**
```
Run `go vet ./...` and `go test ./...` after each phase.
```

**Rust:**
```
Run `cargo clippy` and `cargo test` after each phase.
```

These are examples — adapt to your project's toolchain.

### Feedback during implementation:

Once implementing, the human's role shifts to **supervisor**. Expect terse corrections:

- "You missed the deduplication function"
- "This should be in the admin app, not the main app — move it"
- "wider" / "still cropped" / "2px gap" (for UI work)
- "this table should look exactly like the users table" (reference existing code)

These are enough — you have the full plan context.

### When things go wrong:

If implementation goes in a wrong direction:

```bash
# 1. Revert to clean state
git checkout .

# 2. Narrow scope and retry
"I reverted. Now just do X, nothing else."
```

**Never patch a bad approach. Revert and re-scope.**

### After completion:

```bash
# Commit with a meaningful message
git add -A
git commit -m "feat(scope): description — plancraft implementation"

# Optional: squash if many intermediate commits
git rebase -i main
```

---

## Phase 6: Resume (Session Recovery)

**Trigger:** `plancraft resume` — after context compaction, session restart, or handoff to another agent.

**Goal:** Restore context and continue where you left off.

### What to do:

1. Read `plan.md` — understand the objective, approach, and all changes
2. Check the **Todo** section — identify completed (`[x]`) and remaining (`[ ]`) tasks
3. Read `research.md` if the remaining tasks touch areas you need context on
4. Check `git diff` and `git log` to see what's already been implemented
5. Report status and continue

### Resume output:

> "Resumed plancraft session. Reading plan.md...
>
> **Phase:** Implementation
> **Progress:** 7/12 tasks complete
> **Next task:** [description]
>
> Continuing implementation."

### This is why plan.md matters:

The plan document survives context compaction, session restarts, and even agent swaps. It's the **single source of truth** — not chat history, not memory, not the agent's internal state. Any agent can pick up a plancraft session by reading plan.md.

---

## Phase 7: Status Check

**Trigger:** `plancraft status` at any time.

**Output:**

```markdown
## Plancraft Status

**Phase:** Implementation (Phase 5)
**Branch:** plancraft/feature-name
**Plan:** plan.md
**Progress:** 7/12 tasks complete (58%)

### Completed:
- [x] Task 1 — description
- [x] Task 2 — description
...

### Remaining:
- [ ] Task 8 — description
- [ ] Task 9 — description
...

### Blockers:
- None / [describe issue]
```

---

## File Conventions

| File | Purpose | When created |
|------|---------|-------------|
| `research.md` | Deep-read findings | Phase 1 |
| `plan.md` | Plan + annotations + todo + progress | Phase 2-5 |
| `references/` | Reference implementations (optional) | Phase 2 |

**Clean up:** After successful implementation and merge, ask the human if they want to keep or remove artifacts. Options:
- **Keep:** Commit to repo as documentation (move to `docs/decisions/`)
- **Archive:** Move to `.plancraft/archive/`
- **Delete:** Remove entirely

---

## Quick Reference

| Command | What it does |
|---------|-------------|
| `plancraft research` | Deep-read codebase, write research.md |
| `plancraft plan` | Write implementation plan to plan.md |
| `plancraft annotate` | Address inline notes in plan.md |
| `plancraft todo` | Add granular task checklist to plan.md |
| `plancraft implement` | Execute plan, track progress on feature branch |
| `plancraft resume` | Recover context from plan.md, continue work |
| `plancraft status` | Show current phase and progress |

---

## Anti-Patterns (What NOT to Do)

❌ **Skip research** — "I already know this codebase" → you'll miss conventions and break things
❌ **Verbal plans** — "I'll just explain in chat" → no review surface, decisions get lost
❌ **Jump to code** — implementing without an approved plan → wasted effort, wrong assumptions
❌ **Ignore annotations** — skipping a human's note → trust breakdown
❌ **Patch bad approaches** — trying to fix wrong code → revert and re-scope instead
❌ **Add features not in the plan** — scope creep → stick to what was approved
❌ **Rely on chat context** — sessions get compacted; plan.md is the truth

---

## Why This Works

1. **Research prevents the #1 failure mode** — code that works in isolation but breaks the system
2. **The plan is a shared contract** — human and agent agree before any code is written
3. **Annotation cycles inject human judgement** — domain knowledge, priorities, trade-offs
4. **Implementation is mechanical** — all creative decisions are already made
5. **Markdown files survive everything** — compaction, restarts, agent swaps
6. **Git branches provide safety** — revert is always one command away

> Credit: Methodology inspired by [Boris Tane's Claude Code workflow](https://boristane.com/blog/how-i-use-claude-code/)
