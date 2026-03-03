---
name: tim-ai
description: use this when asked to run the full development flow
---

# Flow 🔑

```
┌──────────────┐
│   tim-ask    │
└──────┬───────┘
       │ gate
┌──────▼───────┐
│ tim-research │
└──────┬───────┘
       │ gate
┌──────▼───────┐
│   tim-plan   │
└──────┬───────┘
       │ gate
┌──────▼───────┐
│   tim-code   │
└──────┬───────┘
       │ gate
┌──────▼───────┐
│  tim-review  │
└──────┬───────┘
       │ gate
┌──────▼───────┐
│  tim-commit  │
└──────────────┘
```

# Phase 1 > Ask 🔑

- follow `skills/tim-ask/SKILL.md`
  ✓ gather requirements before doing anything
- stop and wait for user to confirm before proceeding

# Phase 2 > Research 🔑

- follow `skills/tim-research/SKILL.md`
  ✓ explore codebase and look up external information
- stop and wait for user to confirm before proceeding

# Phase 3 > Plan 🔑

- follow `skills/tim-plan/SKILL.md`
  ✓ generate documents based on what the feature involves
- stop and wait for user to confirm before proceeding

# Phase 4 > Code 🔑

- follow `skills/tim-code/SKILL.md`
  ✓ implement based on approved plan documents
- stop and wait for user to confirm before proceeding

# Phase 5 > Review 🔑

- follow `skills/tim-review/SKILL.md`
  ✓ review uncommitted files (skip asking, use uncommitted)
  ✓ fix findings before proceeding
- stop and wait for user to confirm before proceeding

# Phase 6 > Commit 🔑

- follow `skills/tim-commit/SKILL.md`
  ✓ commit after implementation is complete

# Phase 7 > Cleanup 🔑
- on successful commit
  ✓ ask user if temp files should be archived or deleted
  ✓ archive format `temp/@2026-03-03-1340`

# Gate 🔑

- if user rejects at any gate
  ✓ ask (1) what to change (2) cancel the flow
