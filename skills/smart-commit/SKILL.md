---
name: smart-commit
description: AI-powered git workflow assistant. Generates conventional commit messages and runs pre-commit checks (lint, format, test). Use for commit creation and pre-commit validation.
allowed-tools: Bash, Read, Grep
argument-hint: [review|commit|precommit]
---

# Smart Commit Skill

This skill provides an intelligent git workflow assistant with the following capabilities:

- **Smart Commits**: Analyzes staged changes and creates atomic, well-formatted commits following the [Angular Commit Message Convention](https://github.com/angular/angular/blob/main/CONTRIBUTING.md#commit)
- **Pre-Commit Hooks**: Runs linters, formatters, and tests before committing

## Commit Message Format

All commits MUST follow this format:

```
<type>(<scope>): <subject>
<BLANK LINE>
<body>
<BLANK LINE>
<footer>
```

### Type (Required)

| Type       | Use When                                                                             |
| ---------- | ------------------------------------------------------------------------------------ |
| `build`    | Changes to build system or external dependencies (gulp, npm, webpack)                |
| `ci`       | Changes to CI configuration files and scripts (GitHub Actions, CircleCI)             |
| `docs`     | Documentation only changes                                                           |
| `feat`     | A new feature                                                                        |
| `fix`      | A bug fix                                                                            |
| `perf`     | A code change that improves performance                                              |
| `refactor` | A code change that neither fixes a bug nor adds a feature                            |
| `style`    | Changes that do not affect the meaning of code (white-space, formatting, semicolons) |
| `test`     | Adding missing tests or correcting existing tests                                    |

### Scope (Optional)

The scope provides additional contextual information about what part of the codebase is affected:

- Should be a noun describing a section of the codebase
- Examples: `core`, `compiler`, `http`, `forms`, `router`, `auth`, `api`
- Surrounded by parentheses: `feat(auth): add login endpoint`

### Subject (Required)

The subject is a succinct description of the change:

- Use imperative, present tense: "change" not "changed" nor "changes"
- Don't capitalize the first letter
- No period (.) at the end
- Maximum 50 characters recommended

### Body (Optional)

The body should include the motivation for the change and contrast with previous behavior:

- Use imperative, present tense
- Wrap at 72 characters
- Explain **what** and **why** vs. how

### Footer (Optional)

The footer is used for:

**Breaking Changes:**

```
BREAKING CHANGE: <description>

<migration instructions if applicable>
```

**Issue References:**

```
Fixes #123
Closes #456, #789
```

## Core Principles

1. **One feature per commit** - Each commit should do ONE thing only
2. **Small and focused** - If you can split it, split it
3. **Independent commits** - Each commit should build and work on its own
4. **Logical ordering** - Commits should be ordered so they can be reviewed/reverted independently

### When to Split Commits

- Adding a new construct → separate commit
- Modifying existing construct → separate commit
- Config changes → separate commit
- Documentation → separate commit
- Refactoring → separate commit
- Bug fixes → separate commit

## Workflow: Review & Suggest Splits

When asked to review staged changes:

### Step 1: Analyze Current State

Run these commands to understand the changes:

```bash
git status
git diff --cached --stat
git diff --cached
```

### Step 2: Categorize Changes

Group the staged changes into categories:

1. **New constructs** - New files, classes, functions, components
2. **Modifications** - Changes to existing code logic
3. **Configuration** - Config files, environment, build settings
4. **Documentation** - README, comments, docstrings
5. **Refactoring** - Code restructuring without behavior change
6. **Bug fixes** - Corrections to existing behavior
7. **Tests** - Test files and test utilities

### Step 3: Identify Split Points

Apply these splitting rules:

- **One feature per commit**: If changes implement multiple features, split them
- **Separate concerns**: Config changes should not be mixed with feature code
- **Independence**: Each commit should build/run successfully on its own
- **Logical order**: Dependencies come before dependents

### Step 4: Present Recommendations

Output a structured recommendation:

```
## Commit Split Recommendation

### Current staged changes span [N] logical units:

**Commit 1: `<type>: <description>`**
- Files: [list files]
- Reason: [why this is separate]

**Commit 2: `<type>: <description>`**
- Files: [list files]
- Reason: [why this is separate]

### Suggested Execution Order:
1. [First commit - explain why first]
2. [Second commit - explain dependency]

### Commands to Execute:
[Provide exact git commands to unstage and restage for each commit]
```

## Workflow: Auto-Commit

When asked to auto-commit:

### Step 1: Verify Prerequisites

```bash
git status
git diff --cached --stat
```

- Confirm there are staged changes
- If no staged changes, offer to stage specific files

### Step 2: Analyze for Atomic Commits

Apply the same categorization as Review workflow.

### Step 3: Generate Commit Messages

For each logical unit, generate a commit message following the format.

### Step 4: Present Plan for Confirmation

Before executing, present the full plan:

```
## Auto-Commit Plan

I will create [N] commits in this order:

### Commit 1
**Message:**
feat(auth): add user authentication endpoint

Implements JWT-based auth for the /api/auth route.

Closes #42

**Files:** [list]
```

### Step 5: Execute Commits

After user confirmation, execute using HEREDOC format:

```bash
git add [specific files for commit 1]
git commit -m "$(cat <<'EOF'
<type>(<scope>): <subject>

<body if applicable>

<footer if applicable>
EOF
)"
```

**IMPORTANT:** Do NOT add "Co-Authored-By: Claude" or any AI attribution footer to commits created by this skill. The commit message should only contain the type, scope, subject, body, and standard footers (BREAKING CHANGE, issue references).

Repeat for each commit in order.

### Step 6: Verify Success

```bash
git log --oneline -n [N]
git status
```

## Workflow: Pre-Commit Hooks

When asked to set up or run pre-commit checks:

### Step 1: Detect Project Type

```bash
# Check for package.json (Node.js)
test -f package.json && echo "nodejs"

# Check for pyproject.toml or setup.py (Python)
test -f pyproject.toml && echo "python"
test -f setup.py && echo "python"

# Check for Cargo.toml (Rust)
test -f Cargo.toml && echo "rust"

# Check for go.mod (Go)
test -f go.mod && echo "go"
```

### Step 2: Identify Available Tools

| Project Type | Linter | Formatter | Type Check |
|--------------|--------|-----------|------------|
| Node.js      | ESLint | Prettier  | TypeScript |
| Python       | Ruff, Flake8 | Black, Ruff | mypy, pyright |
| Rust         | Clippy | rustfmt   | Built-in   |
| Go           | golangci-lint | gofmt | Built-in |

### Step 3: Run Pre-Commit Checks

Before committing, run relevant checks:

**Node.js:**
```bash
# Check if scripts exist in package.json, then run
npm run lint --if-present
npm run format:check --if-present
npm run typecheck --if-present
npm run test --if-present
```

**Python:**
```bash
# Run available tools
ruff check . || flake8 .
ruff format --check . || black --check .
mypy . || pyright .
pytest --co -q  # Collect tests only (quick check)
```

**Rust:**
```bash
cargo fmt --check
cargo clippy -- -D warnings
cargo test --no-run
```

**Go:**
```bash
gofmt -l .
golangci-lint run
go test -run=^$ ./...  # Compile tests only
```

### Step 4: Report Results

```
## Pre-Commit Check Results

| Check      | Status | Details |
|------------|--------|---------|
| Lint       | PASS   | No issues found |
| Format     | FAIL   | 3 files need formatting |
| Type Check | PASS   | No type errors |
| Tests      | PASS   | All tests compile |

### Issues to Fix:
1. [File]: [Issue description]

Would you like me to auto-fix these issues?
```

### Step 5: Auto-Fix (Optional)

If user confirms, run fixers:

```bash
# Node.js
npm run lint:fix --if-present
npm run format --if-present

# Python
ruff check --fix .
ruff format .

# Rust
cargo fmt

# Go
gofmt -w .
```

### Step 6: Setup Git Hooks (Optional)

Offer to install git hooks for automatic checking:

```bash
# Create .git/hooks/pre-commit
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/sh
# Auto-generated by smart-commit

# Run linter
npm run lint --if-present || exit 1

# Run formatter check
npm run format:check --if-present || exit 1

echo "Pre-commit checks passed!"
EOF

chmod +x .git/hooks/pre-commit
```

## Edge Cases

### No Staged Changes

Offer to:

1. Stage all changes (`git add .`)
2. Stage specific files
3. Show unstaged changes for review

### Single File with Multiple Concerns

If a single file contains multiple logical changes:

1. Explain that the file has mixed concerns
2. Suggest using `git add -p` for partial staging
3. Offer to guide through interactive staging

### Merge Conflicts Present

Block and report:

```
Cannot proceed - merge conflicts detected. Please resolve conflicts first:
[list conflicted files]
```

### Uncommitted Dependencies

If commits have dependencies:

1. Identify the dependency chain
2. Order commits so dependencies come first
3. Warn if splitting would break the build

### Sensitive Files Detected

Check for and warn about:

- `.env` files
- Files matching `*secret*`, `*credential*`, `*password*`
- `*.pem`, `*.key` files

```
⚠️ Warning: Potentially sensitive file detected: [filename]
Please confirm this should be committed, or add to .gitignore.
```

### Work in Progress

If changes appear incomplete (TODO comments, incomplete functions):

```
These changes appear to be work-in-progress. Would you like to:
1. Commit anyway with a WIP prefix
2. Continue working before committing
```

## Examples

### Example 1: Feature with Tests

**Input**: Staged changes include new API endpoint and its tests

**Output**:

```
## Commit Split Recommendation

### Current staged changes span 2 logical units:

**Commit 1: `feat(api): add user profile endpoint`**
- Files: src/api/profile.ts, src/routes/index.ts
- Reason: Core feature implementation

**Commit 2: `test(api): add user profile endpoint tests`**
- Files: tests/api/profile.test.ts
- Reason: Tests should be separate for easier review/revert

### Suggested Order:
1. Feature first (tests depend on it existing)
2. Tests second
```

### Example 2: Mixed Config and Feature

**Input**: Staged changes include new ESLint rule and code changes

**Output**:

```
## Commit Split Recommendation

### Current staged changes span 2 logical units:

**Commit 1: `build(eslint): add no-console rule`**
- Files: .eslintrc.js
- Reason: Config changes should be isolated

**Commit 2: `refactor(utils): remove console.log statements`**
- Files: src/utils/logger.ts, src/api/auth.ts
- Reason: Code changes responding to new rule

### Suggested Order:
1. Config first (establishes the rule)
2. Refactor second (applies the rule)
```

### Example 3: Breaking Change

**Input**: Staged changes include API changes that break backwards compatibility

**Full commit message example**:

```
feat(api): change authentication response format

Replace flat token response with nested auth object containing
token, refresh_token, and expires_at fields.

BREAKING CHANGE: Authentication endpoint now returns
{ auth: { token, refresh_token, expires_at } } instead of { token }.

Clients must update their token extraction logic.

Closes #156
```

## Critical Warnings

- **NEVER** run `git push --force` without explicit confirmation
- **NEVER** commit files containing secrets or credentials
- **ALWAYS** verify the commit plan before executing
- **ALWAYS** check for merge conflicts before committing
