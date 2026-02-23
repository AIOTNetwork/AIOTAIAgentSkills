---
name: plancraft
description: Plan-first development workflow. Enforces Research → Plan → Annotate → Implement phases with human-in-the-loop review gates. Never write code until the plan is approved. Use for any non-trivial feature, refactor, or bug investigation.
allowed-tools: Bash, Read, Write, Edit, Grep
argument-hint: [research|plan|annotate|todo|implement|status]
---

# Plancraft — Plan-First Development Workflow

**Core principle:** Never write code until you've produced a written plan and the human has reviewed and approved it.

> "Implementation should be boring. The creative work happens in the planning phase."

## The Flow

```
Research → Plan → Annotate (1-6x) → Todo → Implement → Feedback
```

Each phase produces a **persistent markdown artifact**. Never give verbal summaries — always write to files.

---

## Phase 1: Research

**Trigger:** `plancraft research` or starting any non-trivial task.

**Goal:** Deeply understand the relevant codebase before proposing anything.

### What to do:

1. Read the target code **deeply** — not just signatures, but implementations, edge cases, patterns
2. Understand dependencies, data flow, existing conventions
3. Write everything to `research.md` in the project root (or specified location)

### Research prompts (use strong language):

- "Read this folder **in depth**, understand how it works **deeply**, all its specificities"
- "Study the system **in great detail**, understand the **intricacies**"
- "Go through the flow, understand it deeply and look for potential issues — **don't stop until you've found them all**"

### research.md must include:

- Architecture overview of the relevant subsystem
- Key files and their responsibilities
- Data flow and state management patterns
- Existing conventions (naming, patterns, libraries used)
- Potential gotchas, edge cases, or fragile areas
- Dependencies that could be affected by changes

### ⛔ PHASE GATE: Stop here. Tell the human:

> "Research complete. Written to `research.md`. Please review before I proceed to planning."

**Do NOT proceed to planning until the human confirms.**

---

## Phase 2: Plan

**Trigger:** Human approves research, or `plancraft plan`.

**Goal:** Produce a detailed implementation plan in `plan.md`.

### plan.md must include:

1. **Objective** — what we're building and why
2. **Approach** — detailed explanation of the implementation strategy
3. **Changes** — specific files to modify/create, with code snippets showing actual changes
4. **Considerations** — trade-offs, alternatives considered, risks
5. **Open questions** — anything that needs human input

### Key rules:

- Base the plan on **actual codebase** — read source files before suggesting changes
- Include **code snippets** showing the real changes, not pseudocode
- Reference **existing patterns** in the codebase — new code should look like existing code
- If a reference implementation exists (OSS, another part of the codebase), cite it

### ⛔ PHASE GATE: Stop here. Tell the human:

> "Plan written to `plan.md`. Please review and add any inline annotations before I proceed."

**Do NOT proceed until the human explicitly approves.**

---

## Phase 3: Annotation Cycle

**Trigger:** Human says they've added notes, or `plancraft annotate`.

**Goal:** Refine the plan based on human feedback. Repeat 1-6 times.

### How it works:

1. Human opens `plan.md` in their editor
2. Human adds **inline notes** directly in the document:
   - Corrections: "no — this should be a PATCH, not a PUT"
   - Rejections: "remove this section entirely, we don't need caching here"
   - Domain knowledge: "use drizzle:generate for migrations, not raw SQL"
   - Constraints: "these function signatures must not change"
   - Redirections: "restructure this section — the field belongs on the parent, not the child"
3. Human tells the agent: "I added notes, address them all"
4. Agent reads the plan, addresses **every** note, updates the document
5. Repeat until human is satisfied

### Critical rules:

- Address **ALL** notes — do not skip any
- Update the plan document in-place
- **"Don't implement yet"** — this guard is mandatory. Never jump to code during annotation
- Preserve the human's notes as resolved comments (strikethrough or move to a "Resolved" section) so there's an audit trail

### ⛔ PHASE GATE: After each annotation round, stop and ask:

> "All notes addressed. Plan updated. Ready for another review or shall I proceed to the todo list?"

---

## Phase 4: Todo List

**Trigger:** Human approves the plan, or `plancraft todo`.

**Goal:** Break the plan into a granular, trackable checklist.

### Add to plan.md:

```markdown
## Todo

### Phase 1: [Name]
- [ ] Task 1 — specific, actionable description
- [ ] Task 2
  - [ ] Subtask 2a
  - [ ] Subtask 2b

### Phase 2: [Name]
- [ ] Task 3
- [ ] Task 4
```

### Rules:

- Tasks should be **small enough to verify individually**
- Each task maps to a specific change in the plan
- Order tasks by dependency (what must happen first)
- Include validation steps: "run typecheck", "run tests", "verify endpoint returns 200"

### ⛔ PHASE GATE: Stop here. Tell the human:

> "Todo list added to `plan.md`. Review the task breakdown and approve to start implementation."

---

## Phase 5: Implementation

**Trigger:** Human approves todo list, or `plancraft implement`.

**Goal:** Execute the plan mechanically. No creative decisions — those were made in planning.

### Standard implementation prompt:

```
Implement the plan. When you complete a task, mark it as done in plan.md:
- [ ] → - [x]

Do not stop until all tasks are completed.
Do not add unnecessary comments or jsdocs.
Do not use `any` or `unknown` types (TypeScript).
Run typecheck/lint continuously to catch issues early.
```

### Rules:

- Follow the plan **exactly** — do not deviate or add features not in the plan
- Mark tasks complete in `plan.md` as you go — this is the progress tracker
- Run validation commands (typecheck, lint, test) **continuously**, not just at the end
- If you hit an unexpected issue, **stop and report** rather than improvising

### Feedback during implementation:

Once implementing, the human's role shifts to **supervisor**. Expect terse corrections:

- "You missed the deduplication function"
- "This should be in the admin app, not the main app — move it"
- "wider" / "still cropped" / "2px gap" (for UI work)

These are enough — you have the full plan context.

### When things go wrong:

If implementation goes in a wrong direction:
1. **Revert** (discard git changes)
2. **Narrow scope** — "I reverted. Now just do X, nothing else"
3. Re-implement from the clean state

**Never patch a bad approach. Revert and re-scope.**

---

## Phase 6: Status Check

**Trigger:** `plancraft status` at any time.

**Output:** Current state of the workflow:

```markdown
## Plancraft Status

**Phase:** Implementation (Phase 5)
**Plan:** plan.md
**Progress:** 7/12 tasks complete

### Completed:
- [x] Task 1
- [x] Task 2
...

### Remaining:
- [ ] Task 8
- [ ] Task 9
...

### Blockers:
- None / [describe issue]
```

---

## File Conventions

| File | Purpose | When created |
|------|---------|-------------|
| `research.md` | Deep-read findings | Phase 1 |
| `plan.md` | Implementation plan + annotations + todo | Phase 2-4 |
| `plan.md` (todo section) | Progress tracking | Phase 4-5 |

All files are created in the **project root** unless the human specifies otherwise.

**Clean up:** After successful implementation, ask the human if they want to keep or remove `research.md` and `plan.md`. Some teams commit them for documentation; others discard them.

---

## Quick Reference

| Command | What it does |
|---------|-------------|
| `plancraft research` | Deep-read codebase, write research.md |
| `plancraft plan` | Write implementation plan to plan.md |
| `plancraft annotate` | Address inline notes in plan.md |
| `plancraft todo` | Add granular task checklist to plan.md |
| `plancraft implement` | Execute plan, track progress |
| `plancraft status` | Show current phase and progress |

---

## Anti-Patterns (What NOT to Do)

❌ **Skip research** — "I already know this codebase" → you'll miss conventions and break things
❌ **Verbal plans** — "I'll just explain in chat" → no review surface, decisions get lost
❌ **Jump to code** — implementing without an approved plan → wasted effort, wrong assumptions
❌ **Ignore annotations** — skipping a human's note → trust breakdown
❌ **Patch bad approaches** — trying to fix wrong code → revert and re-scope instead
❌ **Add features not in the plan** — scope creep → stick to what was approved

---

## Why This Works

1. **Research prevents the #1 failure mode** — code that works in isolation but breaks the system
2. **The plan is a shared contract** — human and agent agree before any code is written
3. **Annotation cycles inject human judgement** — domain knowledge, priorities, trade-offs
4. **Implementation is mechanical** — all creative decisions are already made
5. **Markdown files are the source of truth** — not chat history, not memory, not verbal agreements

> Credit: Methodology inspired by [Boris Tane's Claude Code workflow](https://boristane.com/blog/how-i-use-claude-code/)
