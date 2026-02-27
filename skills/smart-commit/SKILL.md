---
name: smart-commit
description: pre-commit check ➜ generates conventional commit
allowed-tools: Bash, Read, Grep
argument-hint: "[review|commit|precommit]"
---

# commit 🔑

- follow [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/)
- do not add AI attribution like "Co-Authored-By: Claude"

```
feat(auth)!: [APP-42] add JWT login endpoint
```

```bash
# type    = feat | fix | docs | style | refactor | perf | test | build | ci
# scope   = affected module (optional)
# !       = breaking change
# issue   = ticket reference (optional | [APP-42])
# subject = max 72 chars (50 ideal)
```

# atomic commits 🔑

- one logical change per commit (split it as you can)
- split order: deps before dependents (config → feat → test → docs)

```bash
> build(eslint): add no-console rule        # 1. config
> refactor(utils): remove console.log calls # 2. code
> test(utils): update logger tests          # 3. tests
```

# pre-commit checks 🔑

- before committing, run available checks for the project type
- report results, offer auto-fix, then commit

```bash
# Node.js
npm run lint --if-present && npm run format:check --if-present && npm run typecheck --if-present

# Python
ruff check . && ruff format --check .

# Rust
cargo fmt --check && cargo clippy -- -D warnings

# Go
gofmt -l . && golangci-lint run
```

# warnings 🔑

- warn user if TODO / incomplete functions are staged

# block 🔑

- block commit if `.env`, `*.pem`, `*.key`, `*secret*`, `*credential*` are staged
- block commit if merge conflicts present