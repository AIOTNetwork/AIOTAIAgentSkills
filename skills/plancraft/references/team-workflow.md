# Team-Based Implementation Workflow

## Step 1: Use the approved roles from plan.md

The **Team Roles** section in `plan.md` was populated during planning (Phase 2) and refined during todo creation (Phase 4). The human has already reviewed and approved which roles to spawn and their task assignments.

Read the Team Roles table from `plan.md` and spawn **only the approved roles**. Do not add or remove roles without human approval.

**Two roles are mandatory** — every team must include them regardless of what other roles the plan defines:

1. **`qa-verifier`** — Technical quality gate. Reviews completed work, runs validation commands, checks code quality, and sends issues back to developers for iteration.
2. **`product-manager`** — Product quality gate. After QA passes, verifies the implementation meets the plan's objective, user intent, and acceptance criteria.

No task is truly "complete" until it passes **both** gates: `qa-verifier` first, then `product-manager`.

## Step 2: Create the team and task list

```
1. Use TeamCreate to create a team named "plancraft-<feature-name>"
2. Use TaskCreate to create tasks from the todo list in plan.md
   - Each todo item (or logical group) becomes a task
   - Set dependencies using addBlockedBy for tasks that depend on others
3. Spawn teammates using the Agent tool with:
   - team_name: the team name
   - name: the role name (e.g., "frontend-dev", "backend-dev")
   - subagent_type: "general-purpose" (for implementation work)
   - mode: "bypassPermissions" or as appropriate
```

## Step 2.5: Validate task graph (before spawning teammates)

Before creating any teammates, the team lead must verify:
- No circular dependencies in `addBlockedBy` chains
- Every task is assigned to exactly one role from the Team Roles table
- No role has zero tasks assigned (remove it from the team)
- Validation checkpoint tasks exist between logical phases
- Total task count is reasonable for the team size

If any check fails, fix the task graph before spawning teammates.

## Step 3: Assign tasks and coordinate

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

This avoids idle agents burning tokens while developers are still working.

## Step 4: Verify-Iterate loop (two-stage)

Every completed task passes through two verification stages:

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

### Iteration Budget

Each task has a maximum of **3 full verify-iterate cycles** (developer fix → qa-verifier → product-manager counts as one cycle).

- `qa-verifier` tracks the iteration count per task
- On the **3rd failure** at either stage, the reviewing role MUST:
  1. Stop the cycle
  2. Message the team lead with: task ID, failure history, and what keeps failing
  3. Team lead decides: re-scope the task, revert the approach, or escalate to the human

**Never allow a 4th iteration without team lead intervention.**

### Stage 1 — `qa-verifier`

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

### Stage 2 — `product-manager`

Pick up tasks that `qa-verifier` has approved. For each QA-approved task, verify:
- **Objective alignment** — does this implementation achieve what plan.md set out to do?
- **Acceptance criteria** — are all requirements from the plan satisfied?
- **Completeness** — no missing edge cases, user flows, or functionality gaps
- **Consistency** — changes are coherent with the rest of the system's behavior
- **Non-functional requirements** — if plan.md specifies targets, verify they are met

**On FAIL:** Classify the fix:
- **`cosmetic`** (naming, labels, copy, formatting): skip QA re-review, PM re-reviews directly after developer fixes
- **`functional`** (logic, behavior, missing functionality): must go through Stage 1 again

Create a fix task, assign to original developer, message team lead.

**On PASS:** Message the team lead confirming final approval.

### Regression Protocol

When `qa-verifier` reviews a **fix task** (iteration >= 2), they MUST:
1. Re-run the **full** validation suite, not just tests related to the current task
2. Check `git diff` against all previously approved tasks to identify overlapping file changes
3. If a fix introduces a regression in a previously approved task:
   - Create a new fix task that addresses the regression
   - Message the team lead immediately: "Regression detected — Task #{X} fix broke previously approved Task #{Y}"
   - Block downstream tasks until the regression is resolved

### Communication Protocol

All inter-role messages MUST follow this format:

**QA → PM (task approved):**
> "QA PASS Task #{id}: {task subject}. Ready for product review."

**PM → Team Lead (task fully approved):**
> "PM PASS Task #{id}: {task subject}. Both gates passed."

**QA/PM → Developer (rejection):**
> Created fix task #{new_id} for Task #{original_id}: {one-line summary}. Fix for original task #{original_id}.

**Any role → Team Lead (escalation):**
> "ESCALATION Task #{id}: {reason}. Iteration count: {N}/3."

### Team Lead Responsibilities

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

## Step 5: Finalize

When all tasks are **approved by both `qa-verifier` and `product-manager`**:
- Confirm all validation checkpoints pass (final full run)
- Send shutdown requests to all teammates
- Clean up team with `TeamDelete`
- Proceed to commit

## Solo Implementation (Fallback)

If agent teams are **not available** (e.g., tool restrictions, simple tasks with <3 todo items), implement solo:

- Follow the plan **exactly** — do not deviate or add features not in the plan
- Mark tasks complete in `plan.md` as you go: `- [ ]` → `- [x]`
- Run validation commands **continuously**, not just at the end
- If you hit an unexpected issue, **stop and report** rather than improvising
