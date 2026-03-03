---
name: tim-figma
description: use this when fetching or implementing designs from Figma
---

# Figma Fetch 🔑

- when given a Figma URL
  ✓ `get_metadata` to identify leaf nodes
  ✓ `get_screenshot` + `get_variable_defs` in parallel
  ✓ `get_design_context` on each leaf node