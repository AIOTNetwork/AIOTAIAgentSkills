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

# Phase 5 > Commit 🔑

- follow `skills/tim-commit/SKILL.md`
  ✓ commit after implementation is complete

# Gate 🔑

- if user rejects at any gate
  ✓ ask what to change, then redo that phase