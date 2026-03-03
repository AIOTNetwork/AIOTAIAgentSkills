---
name: plancraft
description: Plan-first development workflow. Enforces Research → Plan → Annotate → Implement phases with human-in-the-loop review gates. Never write code until the plan is approved. Use for any non-trivial feature, refactor, or bug investigation.
allowed-tools: Bash, Read, Write, Edit, Grep, Task, TaskCreate, TaskList, TaskUpdate, TaskGet, TeamCreate, TeamDelete, SendMessage
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

Both `qa-verifier` and `product-manager` use this definition as their rubric. If a task doesn't meet the minimum bar, it fails. If it meets minimum but not quality, it fails with improvement notes.

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

## Non-Functional Requirements
<!-- Optional: specify if the task has performance, security, or accessibility implications -->
- **Performance:** [e.g., "endpoint must respond < 200ms at p95", or "N/A"]
- **Security:** [e.g., "requires auth, input sanitization", or "N/A"]
- **Accessibility:** [e.g., "must meet WCAG 2.1 AA", or "N/A"]

## Team Roles
<!-- Added in Phase 2 when team-based implementation is anticipated -->
<!-- Review and adjust roles before approving the plan -->

| Role | Justification | Assigned Tasks |
|------|---------------|----------------|
| `role-name` | Why this role is needed | Which todo items they'll own |

## Open Questions
- Anything that needs human input

## Resolved Annotations
<!-- Addressed notes move here for audit trail -->

## Todo
<!-- Added in Phase 4 -->

## Quality Metrics
<!-- Updated during implementation by team lead -->

| Task | Developer | QA Verdict | PM Verdict | Fix Iterations | Notes |
|------|-----------|------------|------------|----------------|-------|

## Discovered Knowledge
<!-- Technical insights discovered during implementation — candidates for project documentation -->

## Retrospective
<!-- Added after implementation completes -->
```

### Key rules:

- Base the plan on **actual codebase** — read source files before suggesting changes
- Include **code snippets** showing the real changes, not pseudocode
- Reference **existing patterns** in the codebase — new code should look like existing code
- If a reference implementation exists (OSS, another part of the codebase), add it to the **References** section
- **Populate the Team Roles section** — identify which specialist roles the implementation will need (e.g., `frontend-dev`, `backend-dev`, `tester`). Include a justification for each role so the human can review and adjust before approving. Only propose roles the plan actually requires — don't over-staff

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
- **Update the Team Roles table** — fill in the "Assigned Tasks" column now that tasks are defined. The human reviews role-to-task mapping as part of todo approval

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

### Team-Based Implementation (Default When Available)

**When agent teams are available, ALWAYS use them.** Do not implement solo when you can delegate to a coordinated team.

#### Step 1: Use the approved roles from plan.md

The **Team Roles** section in `plan.md` was populated during planning (Phase 2) and refined during todo creation (Phase 4). The human has already reviewed and approved which roles to spawn and their task assignments.

Read the Team Roles table from `plan.md` and spawn **only the approved roles**. Do not add or remove roles without human approval.

**Two roles are mandatory** — every team must include them regardless of what other roles the plan defines:

1. **`qa-verifier`** — Technical quality gate. Reviews completed work, runs validation commands, checks code quality, and sends issues back to developers for iteration.
2. **`product-manager`** — Product quality gate. After QA passes, verifies the implementation meets the plan's objective, user intent, and acceptance criteria.

No task is truly "complete" until it passes **both** gates: `qa-verifier` first, then `product-manager`.


#### Step 2: Create the team and task list

```
1. Use TeamCreate to create a team named "plancraft-<feature-name>"
2. Use TaskCreate to create tasks from the todo list in plan.md
   - Each todo item (or logical group) becomes a task
   - Set dependencies using addBlockedBy for tasks that depend on others
3. Spawn teammates using the Task tool with:
   - team_name: the team name
   - name: the role name (e.g., "frontend-dev", "backend-dev")
   - subagent_type: "general-purpose" (for implementation work)
   - mode: "bypassPermissions" or as appropriate
```

#### Step 2.5: Validate task graph (before spawning teammates)

Before creating any teammates, the team lead must verify:
- No circular dependencies in `addBlockedBy` chains
- Every task is assigned to exactly one role from the Team Roles table
- No role has zero tasks assigned (remove it from the team)
- Validation checkpoint tasks exist between logical phases
- Total task count is reasonable for the team size

If any check fails, fix the task graph before spawning teammates. Debugging task dependency issues with a live team is expensive.

#### Step 3: Assign tasks and coordinate

- Assign tasks to teammates via `TaskUpdate` with the `owner` parameter
- Each teammate's prompt must include:
  - The relevant section of `plan.md` (objective, approach, their specific changes)
  - The specific tasks they own
  - Language/framework conventions from research.md
  - Instruction to mark tasks complete via `TaskUpdate` when done
  - Instruction to follow the plan **exactly** — no creative decisions or scope creep
- **Do NOT assign verification tasks to `qa-verifier` or `product-manager` upfront** — they pick up work after developers mark tasks as complete (see Step 4)

**Spawning timing:**
- **Developer roles**: Spawn immediately at team creation
- **`qa-verifier`**: Spawn when the first developer task is marked complete
- **`product-manager`**: Spawn when `qa-verifier` approves the first task

This avoids idle agents burning tokens while developers are still working. The team lead is responsible for spawning these roles at the right time.

#### Step 4: Verify-Iterate loop (two-stage)

This is the core quality mechanism. Every completed task passes through two verification stages:

```
Developer completes task
        ↓
  ┌─ Stage 1: qa-verifier ─┐
  │  Technical review       │
  │  Tests, code quality,   │
  │  plan adherence         │
  └─────────┬───────────────┘
            ↓
     QA Pass? ──No──→ Fix task → Developer → re-review
            │
           Yes
            ↓
  ┌─ Stage 2: product-manager ─┐
  │  Product review              │
  │  Objective met, UX correct,  │
  │  acceptance criteria         │
  └─────────┬────────────────────┘
            ↓
     PM Pass? ──No──→ Fix task → Developer → Stage 1 again
            │        (functional fixes go through QA;
            │         cosmetic fixes skip QA, PM re-reviews directly)
           Yes
            ↓
      Task approved ✓
```

#### Iteration Budget

Each task has a maximum of **3 full verify-iterate cycles** (developer fix → qa-verifier → product-manager counts as one cycle).

- `qa-verifier` tracks the iteration count per task
- On the **3rd failure** at either stage, the reviewing role MUST:
  1. Stop the cycle
  2. Message the team lead with: task ID, failure history, and what keeps failing
  3. Team lead decides: re-scope the task, revert the approach, or escalate to the human

**Never allow a 4th iteration without team lead intervention.**

#### Stage 1 — `qa-verifier`

Watch `TaskList` for tasks marked complete by developers. For each completed task, verify:

**1. Build & Type Safety**
- [ ] Project compiles/builds without errors
- [ ] Type checking passes
- [ ] No new compiler/linter warnings introduced

**2. Test Suite**
- [ ] All existing tests pass (full suite, not just changed files)
- [ ] New code has test coverage where the plan specifies it
- [ ] No test files were accidentally modified or deleted

**3. Static Analysis & Linting**
- [ ] Linter passes with zero new violations
- [ ] No dead code introduced (unused imports, unreachable branches)
- [ ] No TODO/FIXME/HACK comments added without tracking

**4. Security (Surface-Level)**
- [ ] No hardcoded secrets, API keys, or credentials
- [ ] No new dependencies with known vulnerabilities (if lockfile changed)
- [ ] Input validation present at system boundaries

**5. Integration & Consistency**
- [ ] Changes work across files — no broken imports, missing exports, or interface mismatches
- [ ] Follows existing codebase conventions
- [ ] No unintended side effects on other features

**6. Plan Adherence**
- [ ] Implementation matches plan.md specification exactly
- [ ] No scope creep — no features or changes beyond what the plan describes
- [ ] Validation checkpoints from the todo list are satisfied

**7. Non-Functional Requirements (if specified in plan.md)**
- [ ] Performance requirements met
- [ ] Security requirements satisfied
- [ ] Accessibility requirements met

**On FAIL:** Create a fix task via `TaskCreate` with file, line, and what's wrong. Assign it back to the original developer. Set `addBlockedBy` so downstream tasks wait.

**On PASS:** Message `product-manager` that the task is ready for product review.

#### Stage 2 — `product-manager`

Pick up tasks that `qa-verifier` has approved. For each QA-approved task, verify:
- **Objective alignment** — does this implementation achieve what plan.md set out to do?
- **Acceptance criteria** — are all requirements from the plan satisfied?
- **Completeness** — no missing edge cases, user flows, or functionality gaps
- **Consistency** — changes are coherent with the rest of the system's behavior
- **Non-functional requirements** — if plan.md specifies targets, verify they are met

**On FAIL:** Classify the fix:
- **`cosmetic`** — naming, labels, copy, formatting → does NOT require QA re-review. Product-manager re-reviews directly after developer completes it.
- **`functional`** — logic, behavior, missing functionality → MUST go through Stage 1 again after developer completes it.

Create a fix task, assign to original developer, message team lead.

**On PASS:** Message the team lead confirming final approval.

#### Regression Protocol

When `qa-verifier` reviews a **fix task** (iteration >= 2), they MUST:
1. Re-run the **full** validation suite, not just tests related to the current task
2. Check `git diff` against all previously approved tasks to identify overlapping file changes
3. If a fix introduces a regression in a previously approved task:
   - Create a new fix task that addresses the regression
   - Message the team lead immediately: "Regression detected — Task #{X} fix broke previously approved Task #{Y}"
   - Block downstream tasks until the regression is resolved

#### Communication Protocol

All inter-role messages MUST follow this format:

**QA → PM (task approved):**
> "QA PASS Task #{id}: {task subject}. Ready for product review."

**PM → Team Lead (task fully approved):**
> "PM PASS Task #{id}: {task subject}. Both gates passed."

**QA/PM → Developer (rejection):**
> Created fix task #{new_id} for Task #{original_id}: {one-line summary}. Fix for original task #{original_id}.

**Any role → Team Lead (escalation):**
> "ESCALATION Task #{id}: {reason}. Iteration count: {N}/3."

#### Team Lead Responsibilities

- Monitor task progress via `TaskList`
- Respond to teammate messages (blockers, questions, conflicts)
- Resolve merge conflicts or task dependencies
- Update `plan.md` todo items only after **both stages pass**: `- [ ]` → `- [x]`
- Update the **Quality Metrics** table in plan.md after each task is fully approved

**Escalation triggers — pause and inform the human when:**
- Any single task requires more than 3 fix iterations
- A developer and verifier disagree on whether a fix is needed
- The implementation requires a change to the approved plan
- Total fix tasks created exceed 50% of the original task count
- Any teammate reports being blocked for more than 2 task cycles

**Deadlock detection:**
- If a task has been in `in_progress` status for longer than all other tasks combined, message the owner to check status
- If a teammate has not responded after a check-in, consider reassigning the task or spawning a replacement
- If QA and PM are both idle but tasks remain incomplete, verify the communication chain isn't broken

#### Step 5: Finalize

When all tasks are **approved by both `qa-verifier` and `product-manager`**:
- Confirm all validation checkpoints pass (final full run)
- Send shutdown requests to all teammates
- Clean up team with `TeamDelete`
- Proceed to commit

#### Team prompt template for developer teammates:

```
You are a {role} on a plancraft implementation team.

**Objective:** {from plan.md Objective section}
**Your tasks:** {list of assigned tasks}

**Rules:**
- Follow the plan EXACTLY — do not deviate or add features not in the plan
- Mark tasks complete via TaskUpdate when done
- If you hit an unexpected issue, message the team lead rather than improvising
- Run validation commands after each change
- Check TaskList after completing each task for newly unblocked work
- When qa-verifier or product-manager creates a fix task assigned to you, prioritize it

**Context:**
{relevant sections from plan.md and research.md}
```

#### Team prompt template for qa-verifier:

```
You are the qa-verifier on a plancraft implementation team.

**Objective:** {from plan.md Objective section}
**Plan:** Read plan.md thoroughly — you are the technical quality enforcer.
**Definition of Done:** See the Definition of Done section — every task must meet both minimum and quality bars.

**Your workflow:**
1. Watch TaskList for tasks marked complete by developers
2. For each completed task, run through the verification checklist (Build & Type Safety, Test Suite, Static Analysis, Security, Integration, Plan Adherence, Non-Functional Requirements)
3. Track iteration count per task (max 3 cycles before escalation)
4. If issues found:
   - Create a fix task via TaskCreate — include file, line, and what's wrong
   - Assign it to the original developer via TaskUpdate
   - Message: "QA FAIL Task #{id}: {summary}. Iteration {N}/3."
5. If task passes:
   - Message product-manager: "QA PASS Task #{id}: {task subject}. Ready for product review."
6. For FIX tasks (iteration >= 2): re-run the FULL validation suite and check for regressions against previously approved tasks
7. Check TaskList again for more completed work
8. When you discover a gotcha or non-obvious behavior, add it to the Discovered Knowledge section in plan.md

**Rules:**
- Never fix code yourself — always send it back to the developer
- Be specific in fix tasks: include the file, line, and what's wrong
- Run the FULL validation suite, not just the changed files
- A task is only done when it passes your review AND product-manager's review
- After all tasks pass, do a final integration check across the whole changeset
- On 3rd failure for any task, STOP and escalate to team lead
```

#### Team prompt template for product-manager:

```
You are the product-manager on a plancraft implementation team.

**Objective:** {from plan.md Objective section}
**Plan:** Read plan.md thoroughly — you are the product quality enforcer.
**Definition of Done:** See the Definition of Done section — verify the quality bar is met from a product perspective.

**Your workflow:**
1. Pick up tasks that qa-verifier has approved (they will message you: "QA PASS Task #{id}...")
2. For each QA-approved task, verify:
   - Objective alignment: does the implementation achieve what plan.md set out to do?
   - Acceptance criteria: are all requirements from the plan satisfied?
   - Completeness: no missing edge cases, user flows, or functionality gaps
   - Consistency: changes are coherent with the rest of the system's behavior
   - Non-functional requirements: if plan.md specifies targets, verify they are met
3. If issues found, classify the fix:
   - **cosmetic** (naming, labels, copy, formatting): skip QA re-review, you re-review directly after developer fixes
   - **functional** (logic, behavior, missing functionality): must go through qa-verifier again
   - Create a fix task via TaskCreate, assign to original developer
   - Message: "PM FAIL Task #{id}: {summary}. Fix type: cosmetic|functional. Iteration {N}/3."
4. If task passes:
   - Message team lead: "PM PASS Task #{id}: {task subject}. Both gates passed."
5. Check TaskList again for more QA-approved work
6. When you discover a gotcha or product insight, add it to the Discovered Knowledge section in plan.md

**Rules:**
- Never fix code yourself — always send it back to the developer
- Focus on WHAT the code does, not HOW — leave code quality to qa-verifier
- Verify against the plan's Objective and acceptance criteria, not personal preferences
- On 3rd failure for any task, STOP and escalate to team lead
```

### Solo Implementation (Fallback)

If agent teams are **not available** (e.g., tool restrictions, simple tasks with <3 todo items), implement solo:

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

1. **Final integration check** — run the full test suite one more time against the complete changeset
2. **Complete retrospective** (mandatory for team implementation) — see Phase 5.5
3. **Review discovered knowledge** — decide with the human what to persist to project docs
4. **Commit:**
   ```bash
   # Stage specific files (avoid git add -A)
   git add [specific files from the plan]
   git commit -m "feat(scope): description — plancraft implementation"
   ```
5. **Artifact cleanup** — ask the human about plan.md and research.md disposition

---

## Phase 5.5: Retrospective (Post-Implementation)

**Trigger:** All tasks approved by both qa-verifier and product-manager, before final commit.

**Goal:** Capture what worked, what didn't, and what to change for next time.

### What to do:

1. The team lead reviews the full implementation history:
   - How many fix tasks were created? By whom? For what reasons?
   - Were there any tasks that required more than 2 iterations?
   - Did the plan need to be revised during implementation?

2. Write a brief retrospective to the **Retrospective** section of `plan.md`:

```markdown
## Retrospective

### Quality Summary
- Tasks completed: N
- Fix iterations required: N (by qa-verifier), N (by product-manager)
- Tasks requiring >2 iterations: [list]

### What Worked
- [specific things that went smoothly]

### What Didn't Work
- [specific problems encountered]

### Lessons for Next Time
- [actionable improvements for future plancraft sessions]
```

3. If recurring patterns emerge (e.g., "tests were always missing for edge cases"), suggest updates to the project's CLAUDE.md or documentation to prevent recurrence.

**This phase is mandatory for team-based implementation. Skip only for solo implementation of <3 tasks.**

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
