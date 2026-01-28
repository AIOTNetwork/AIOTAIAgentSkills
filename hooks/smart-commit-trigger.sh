#!/bin/bash
# Smart Commit Auto-Trigger Hook
# Triggered when user prompt contains commit-related keywords

# Output instructions for Claude to use the smart-commit skill
cat << 'EOF'
<user-prompt-submit-hook>
The user wants to commit changes. Use the /smart-commit skill to handle this request.
Follow the smart-commit workflow defined in skills/smart-commit.md.
</user-prompt-submit-hook>
EOF
