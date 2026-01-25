#!/bin/bash
# Pre-commit check hook for smart-commit
# This hook runs before Bash tool executions that contain git commit

# Get the command being executed (passed via environment or stdin)
COMMAND="${TOOL_INPUT:-}"

# Only process git commit commands
if [[ ! "$COMMAND" =~ git[[:space:]]+commit ]]; then
    exit 0
fi

echo "Smart-commit hook detected a git commit command."
echo ""

# Check for staged changes
STAGED=$(git diff --cached --name-only 2>/dev/null)
if [[ -z "$STAGED" ]]; then
    echo "Warning: No staged changes detected."
    exit 0
fi

echo "Staged files:"
echo "$STAGED" | sed 's/^/  - /'
echo ""

# Run pre-commit checks based on project type
ERRORS=0

# Node.js project
if [[ -f "package.json" ]]; then
    echo "Running Node.js checks..."

    # Check for lint script
    if grep -q '"lint"' package.json 2>/dev/null; then
        if ! npm run lint --silent 2>/dev/null; then
            echo "  Lint: FAILED"
            ERRORS=$((ERRORS + 1))
        else
            echo "  Lint: PASSED"
        fi
    fi

    # Check for format script
    if grep -q '"format:check"' package.json 2>/dev/null; then
        if ! npm run format:check --silent 2>/dev/null; then
            echo "  Format: FAILED"
            ERRORS=$((ERRORS + 1))
        else
            echo "  Format: PASSED"
        fi
    fi
fi

# Python project
if [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]]; then
    echo "Running Python checks..."

    if command -v ruff &>/dev/null; then
        if ! ruff check . --quiet 2>/dev/null; then
            echo "  Ruff: FAILED"
            ERRORS=$((ERRORS + 1))
        else
            echo "  Ruff: PASSED"
        fi
    fi
fi

# Rust project
if [[ -f "Cargo.toml" ]]; then
    echo "Running Rust checks..."

    if ! cargo fmt --check --quiet 2>/dev/null; then
        echo "  Format: FAILED"
        ERRORS=$((ERRORS + 1))
    else
        echo "  Format: PASSED"
    fi
fi

# Go project
if [[ -f "go.mod" ]]; then
    echo "Running Go checks..."

    UNFORMATTED=$(gofmt -l . 2>/dev/null)
    if [[ -n "$UNFORMATTED" ]]; then
        echo "  Format: FAILED"
        ERRORS=$((ERRORS + 1))
    else
        echo "  Format: PASSED"
    fi
fi

echo ""

if [[ $ERRORS -gt 0 ]]; then
    echo "Pre-commit checks found $ERRORS issue(s)."
    echo "Consider running /smart-commit precommit to fix issues before committing."
    # Don't block, just warn
    exit 0
fi

echo "All pre-commit checks passed."
exit 0
