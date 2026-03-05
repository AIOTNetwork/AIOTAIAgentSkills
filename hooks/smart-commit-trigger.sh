#!/bin/bash
# Smart Commit Auto-Trigger Hook
#
# NOTE: UserPromptSubmit hooks do NOT support the "matcher" field in hooks.json.
# The matcher is silently ignored and the hook fires on every prompt.
# We must check the prompt content here in the script instead.

# Read JSON input from stdin
INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')

# --- Signal 1: Explicit slash command (always trigger) ---
if echo "$PROMPT" | grep -iqE '(^|\s)(\/commit|\/smart-commit)\b'; then
  exec cat << 'EOF'
<user-prompt-submit-hook>
The user wants to commit changes. Use the /smart-commit skill to handle this request.
Follow the smart-commit workflow defined in skills/smart-commit.md.
</user-prompt-submit-hook>
EOF
fi

# --- Signal 2: "commit" must be an ACTION, not a mention ---
# Skip if "commit" is used in discussion context (preceded by articles/prepositions)
if echo "$PROMPT" | grep -iqE '\b(the|a|an|about|for|in|of|this|that|from|with the) commits?\b'; then
  exit 0
fi

# "commit" must appear as one of the first 3 words OR after action words
if ! echo "$PROMPT" | grep -iqE '(^(commit|please commit|now commit|git commit|do commit|lets commit)|push.*(and|with) commit)'; then
  # Not at the start — check if it's a short imperative like "commit changes" anywhere
  if ! echo "$PROMPT" | grep -iqE '^.{0,30}\bcommit\b'; then
    exit 0
  fi
fi

# --- Signal 3: There must be actual changes to commit ---
if git diff --quiet HEAD 2>/dev/null && git diff --cached --quiet 2>/dev/null && [ -z "$(git ls-files --others --exclude-standard 2>/dev/null)" ]; then
  # No staged, unstaged, or untracked changes — nothing to commit
  exit 0
fi

# All signals pass — trigger smart-commit
cat << 'EOF'
<user-prompt-submit-hook>
The user wants to commit changes. Use the /smart-commit skill to handle this request.
Follow the smart-commit workflow defined in skills/smart-commit.md.
</user-prompt-submit-hook>
EOF
