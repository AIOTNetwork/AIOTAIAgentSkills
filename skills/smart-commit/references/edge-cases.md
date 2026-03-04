# Edge Cases & Examples

## Edge Cases

### No Staged Changes
Offer to: stage all changes (`git add .`), stage specific files, or show unstaged changes for review.

### Single File with Multiple Concerns
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
1. Identify the dependency chain
2. Order commits so dependencies come first
3. Warn if splitting would break the build

### Sensitive Files Detected
Check for and warn about `.env`, `*secret*`, `*credential*`, `*password*`, `*.pem`, `*.key`:
```
Warning: Potentially sensitive file detected: [filename]
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

### Feature with Tests
**Input**: Staged changes include new API endpoint and its tests

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

### Mixed Config and Feature
**Input**: Staged changes include new ESLint rule and code changes

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

### Breaking Change
```
feat(api): change authentication response format

Replace flat token response with nested auth object containing
token, refresh_token, and expires_at fields.

BREAKING CHANGE: Authentication endpoint now returns
{ auth: { token, refresh_token, expires_at } } instead of { token }.

Clients must update their token extraction logic.

Closes #156
```
