#!/bin/bash

set -euo pipefail

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name' | sed 's/mcp__figma__//')
NODE_ID=$(echo "$INPUT" | jq -r '.tool_input.nodeId // "unknown"' | tr ':' '-')

DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/temp"
mkdir -p "$DIR"

extract_text() {
  echo "$INPUT" | jq -r '.tool_response | if type == "array" then [.[] | select(.type == "text") | .text] | join("\n") elif type == "string" then . else tostring end'
}

case "$TOOL_NAME" in
  get_design_context)
    FILENAME="${NODE_ID}-design-context.figma.jsx"
    extract_text | sed '/SUPER CRITICAL/,$d' > "$DIR/$FILENAME"
    ;;
  get_metadata)
    FILENAME="${NODE_ID}-metadata.figma.xml"
    extract_text | sed '/IMPORTANT/,$d' > "$DIR/$FILENAME"
    ;;
  get_screenshot)
    FILENAME="${NODE_ID}-screenshot.figma.png"
    echo "$INPUT" | jq -r '.tool_response[0].source.data' | base64 -d > "$DIR/$FILENAME"
    ;;
  get_variable_defs)
    FILENAME="${NODE_ID}-variable-defs.figma.json"
    extract_text | jq . > "$DIR/$FILENAME"
    ;;
  *)
    exit 0
    ;;
esac

echo "saved → .claude/temp/$FILENAME" >&2
