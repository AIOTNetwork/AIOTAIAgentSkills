---
name: tim-review
description: use this when asked to review code changes
---

# Source 🔑

- ask user which diff to review
  ✓ option 1: commit hash (use `git diff <hash>~1 <hash>`)
  ✓ option 2: uncommitted files (use `git diff` + `git diff --cached`)
- collect changed file list from chosen diff

# Practice Check 🔑

- read applicable practice file from `skills/tim-code/practice/`
- for each changed file
  ✓ check against Do rules
  ✓ check against Don't rules
  ✓ check naming conventions
  ✓ check structure placement

# Style Check 🔑

- for each changed file
  ✓ no hardcoded color → use design token
  ✓ no hardcoded typography → use design token
  ✓ no redundant tailwind classes

# Spell Check 🔑

- run `bunx cspell --no-progress --no-summary <file>` on each changed file
  ✓ collect misspellings

# Lint Check 🔑

- run `bunx biome check <file>` on each changed file
  ✓ collect lint issues

# Output 🔑

- use `tim-document` skill with `review.md` template
- output to `.claude/temp/review.md`
