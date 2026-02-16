#!/bin/bash
# Smart Commit Auto-Trigger Hook
# Triggered when user prompt contains commit-related keywords
#
# NOTE: UserPromptSubmit hooks do NOT support the "matcher" field in hooks.json.
# The matcher is silently ignored and the hook fires on every prompt.
# We must check the prompt content here in the script instead.

# Read JSON input from stdin
INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')

# Only trigger for commit-related keywords (case-insensitive)
if ! echo "$PROMPT" | grep -iqE '\b(commit|commits|committing)\b'; then
  exit 0
fi

# Output instructions for Claude to use the smart-commit skill
cat << 'EOF'
<user-prompt-submit-hook>
The user wants to commit changes. Use the /smart-commit skill to handle this request.
Follow the smart-commit workflow defined in skills/smart-commit.md.
</user-prompt-submit-hook>
EOF
