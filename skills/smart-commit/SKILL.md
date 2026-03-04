---
name: smart-commit
description: "AI-powered git workflow assistant. Generates conventional commit messages following Angular Commit Convention and runs pre-commit checks (lint, format, test). Use for: commit creation, atomic commit splitting, pre-commit validation, conventional commits, changelog generation, version bumping."
---

# Smart Commit

## Commit Message Format

Follow the [Angular Commit Convention](https://github.com/angular/angular/blob/main/CONTRIBUTING.md#commit):

```
<type>(<scope>): <subject>

<body>

<footer>
```

| Type       | Use When                                                        |
| ---------- | --------------------------------------------------------------- |
| `build`    | Build system or external dependencies                           |
| `ci`       | CI configuration                                                |
| `docs`     | Documentation only                                              |
| `feat`     | New feature                                                     |
| `fix`      | Bug fix                                                         |
| `perf`     | Performance improvement                                         |
| `refactor` | Neither fix nor feature                                         |
| `style`    | Formatting, whitespace, semicolons                              |
| `test`     | Adding or correcting tests                                      |

**Subject:** imperative present tense, no capital, no period, max 50 chars.
**Scope:** noun describing affected section (e.g., `auth`, `api`, `core`).
**Body:** explain what and why, wrap at 72 chars.
**Footer:** `BREAKING CHANGE:` or `Fixes #123` / `Closes #456`.

**Do NOT add "Co-Authored-By: Claude" or any AI attribution footer.**

## Core Principles

1. **One feature per commit** — each commit does ONE thing
2. **Small and focused** — if you can split it, split it
3. **Independent commits** — each should build and work on its own
4. **Logical ordering** — dependencies come before dependents

Split when: new construct, modification, config change, docs, refactor, bug fix, or test.

## Workflow: Auto-Commit

### Step 1: Analyze

```bash
git status
git diff --cached --stat
git diff --cached
```

If no staged changes, offer to stage specific files.

### Step 2: Categorize and Split

Group changes into: new constructs, modifications, configuration, documentation, refactoring, bug fixes, tests. Each group becomes a separate commit.

### Step 3: Present Plan

```
## Auto-Commit Plan

I will create [N] commits in this order:

### Commit 1
**Message:** feat(auth): add user authentication endpoint
**Files:** [list]
```

### Step 4: Execute

After user confirmation, execute using HEREDOC:

```bash
git add [specific files]
git commit -m "$(cat <<'EOF'
<type>(<scope>): <subject>

<body if applicable>

<footer if applicable>
EOF
)"
```

### Step 5: Verify

```bash
git log --oneline -n [N]
git status
```

## Workflow: Review & Suggest Splits

Analyze staged changes, categorize, identify split points, then output:

```
## Commit Split Recommendation

### Current staged changes span [N] logical units:

**Commit 1: `<type>: <description>`**
- Files: [list]
- Reason: [why separate]

### Suggested Execution Order:
1. [First commit - why first]
2. [Second commit - dependency]

### Commands to Execute:
[exact git commands]
```

## Workflow: Pre-Commit Hooks

See [references/precommit.md](references/precommit.md) for the full pre-commit workflow including language detection, tool tables, commands per language, auto-fix, and git hooks setup.

## Edge Cases & Examples

See [references/edge-cases.md](references/edge-cases.md) for handling: no staged changes, single file with multiple concerns, merge conflicts, uncommitted dependencies, sensitive files, WIP code, and commit examples.

## Critical Warnings

- **NEVER** run `git push --force` without explicit confirmation
- **NEVER** commit files containing secrets or credentials
- **ALWAYS** verify the commit plan before executing
- **ALWAYS** check for merge conflicts before committing
