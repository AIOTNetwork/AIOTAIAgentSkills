---
name: tim-plan
description: use this when asked to plan an implementation
---

# Plan 🔑

- when asked to plan a feature or task
  ✓ read `./claude/temp/research.md` (if it exists)
  ✓ read actual codebase
- write documents

# Generate Documents 🔑

- use `tim-document` skill
- always generate
  ✓ `change.md`
- if new packages are needed
  ✓ `stack.md`
- if new flow is introduced
  ✓ `flow.md`
- if api calls involved
  ✓ `api.md`
- if file / folder changes
  ✓ `structure.md`
- always generate
  ✓ `test.md`

# Output 🔑

- when generate documents
  ✓ output to `./claude/temp`