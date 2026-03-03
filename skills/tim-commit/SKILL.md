---
name: tim-commit
description: use this when asked to commit or stage changes
---

# Commit 🔑

- MUST use [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/)
  ✓ don't write commit message
  ✓ don't add co-author
  ✓ prefer lowercase subject, avoid special characters
```bash
feat(auth)!: [APP-42] JWT on login endpoint
```

```bash
# type    = feat | fix | docs | style | refactor | perf | test | build | ci
# scope   = affected generic module
# !       = breaking change
# issue   = ticket reference (optional | [APP-42])
# subject = max 72 chars (50 ideal)
```

# Atomic Commit 🔑

- SHOULD one logical change per commit
  ✓ split unrelated changes into separate commits

# Warn 🔑

- SHOULD warn user before committing if TODO / incomplete functions are staged
  ✓ tell user which files and why, then proceed

# Block 🔑

- MUST block commit if `.env`, `*.pem`, `*.key`, `*secret*`, `*credential*` are staged
- MUST block commit if merge conflicts present