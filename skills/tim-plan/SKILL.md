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
  ✓ follow `change.md`
- if new packages are needed
  ✓ follow `stack.md`
- if new flow is introduced
  ✓ follow `flow.md`
- if api calls involved
  ✓ follow `api.md`
- if file / folder changes
  ✓ follow `structure.md`
- if figma involved
  ✓ read `*.figma.*` fixtures
  ✓ follow `figma.md`
- always generate
  ✓ follow `test.md`

# Iterate 🔑
- iterate 3 times
  ✓ 1st ➜ draft
  ✓ 2nd ➜ check `figma.md` vs `structure.md` vs `change.md`
  ✓ 3rd ➜ revise code practice

# Output 🔑

- when generate documents
  ✓ output to `.claude/temp`