# AIOT AI Agent Skills

A collection of Claude Code skills for AI-assisted development workflows.

## Installation

### Option 1: Add Marketplace (Recommended)

Add the AIOT skills marketplace to Claude Code:

```bash
/plugin marketplace add AIOTNetwork/AIOTAIAgentSkills
```

Then install the plugin:

```bash
/plugin install aiot-ai-agent-skills@aiot-skills
```

### Option 2: Direct Install from GitHub

```bash
/plugin install AIOTNetwork/AIOTAIAgentSkills
```

### Option 3: Manual Copy

Copy the `skills/` directory to your project's `.claude/skills/`:

```bash
cp -r skills/* /path/to/your/project/.claude/skills/
```

## Available Skills

### `/smart-commit`

AI-powered git workflow assistant. Generates conventional commit messages and runs pre-commit checks.

**Features:**

- **Smart Commits**: Analyzes staged changes and suggests atomic commits following Angular convention
- **Pre-Commit Hooks**: Runs linters, formatters, type checks before committing
- **Edge Cases**: Handles merge conflicts, sensitive files, WIP code

**Usage:**

```
/smart-commit              # Review staged changes, then offer to commit
/smart-commit review       # Analyze and suggest splits only
/smart-commit commit       # Auto-commit with generated messages
/smart-commit precommit    # Run pre-commit checks (lint, format, test)
```

**Commit Message Format:**

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Allowed Types:**

| Type       | Description                                              |
| ---------- | -------------------------------------------------------- |
| `build`    | Changes to build system or external dependencies         |
| `ci`       | Changes to CI configuration files and scripts            |
| `docs`     | Documentation only changes                               |
| `feat`     | A new feature                                            |
| `fix`      | A bug fix                                                |
| `perf`     | A code change that improves performance                  |
| `refactor` | A code change that neither fixes a bug nor adds a feature|
| `style`    | Changes that do not affect the meaning of code           |
| `test`     | Adding missing tests or correcting existing tests        |

**Examples:**

```
feat(auth): add OAuth2 login support
fix(api): handle null response from external service
docs(readme): update installation instructions
refactor(core): extract validation logic into separate module

BREAKING CHANGE: rename authToken to accessToken in config
```

### `/plancraft`

Plan-first development workflow. Enforces human-in-the-loop review gates before any code is written.

**Core principle:** Never let the agent write code until you've reviewed and approved a written plan.

**The Flow:**

```
Research → Plan → Annotate (1-6x) → Todo → Implement → Feedback
```

**Usage:**

```
/plancraft research    # Deep-read codebase, write research.md
/plancraft plan        # Write implementation plan to plan.md
/plancraft annotate    # Address inline notes in plan.md
/plancraft todo        # Add granular task checklist to plan.md
/plancraft implement   # Execute plan on feature branch, track progress
/plancraft resume      # Recover context after session restart
/plancraft status      # Show current phase and progress
```

**Key Features:**

- **Phase gates** — agent stops and waits for human approval at each phase
- **Annotation cycle** — human adds `> **[NOTE]:**` inline notes, agent refines the plan (1-6 rounds)
- **Session resilience** — `resume` recovers from context compaction by reading plan.md
- **Git integration** — works on `plancraft/<feature>` branches, revert = clean slate
- **Language-agnostic** — customizable validation rules for any language/toolchain

**When to use:** Changes spanning multiple files, >30 min estimated work, architectural decisions, unfamiliar subsystems.

**Annotation types:**

| Prefix | Meaning |
|--------|---------|
| `[NOTE]` | General feedback |
| `[REJECT]` | Remove this section |
| `[CONSTRAINT]` | Hard rule, don't change |
| `[QUESTION]` | Agent should answer |

> Methodology inspired by [Boris Tane's Claude Code workflow](https://boristane.com/blog/how-i-use-claude-code/)

---

## Auto-Trigger Hooks

### Prompt-Based Trigger

The plugin automatically triggers the `/smart-commit` skill when your prompt contains commit-related keywords:

- `commit`
- `commits`
- `committing`

**Examples that will auto-trigger:**
```
"commit my changes"
"help me commit this"
"I want to commit"
"create a commit for these changes"
```

### Pre-Commit Check

The plugin also includes a pre-commit hook that automatically runs when Claude executes a `git commit` command. It will:

1. Detect staged files
2. Run pre-commit checks (lint, format) based on project type
3. Report results before the commit executes

Supported project types: Node.js, Python, Rust, Go

## Plugin Structure

```
AIOTAIAgentSkills/
├── .claude-plugin/
│   ├── plugin.json          # Plugin manifest
│   └── marketplace.json     # Marketplace distribution config
├── hooks/
│   ├── hooks.json           # Hook configuration
│   └── pre-commit-check.sh  # Pre-commit check script
├── skills/
│   ├── smart-commit/
│   │   └── SKILL.md         # Smart commit skill
│   └── plancraft/
│       └── SKILL.md         # Plan-first dev workflow
├── LICENSE
├── CHANGELOG.md
└── README.md
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feat/amazing-skill`)
3. Commit your changes (use `/smart-commit` of course!)
4. Push to the branch (`git push origin feat/amazing-skill`)
5. Open a Pull Request

## License

MIT
