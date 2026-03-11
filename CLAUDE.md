# Project Instructions

## Release Workflow

When committing and pushing changes, always update all 3 version files in sync before pushing:

1. `.claude-plugin/plugin.json` — main version
2. `.claude-plugin/marketplace.json` — all plugin entries' versions
3. `CHANGELOG.md` — new entry following [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format

Version bumps follow [Semantic Versioning](https://semver.org/):

- **Patch** (x.x.1): bug fixes, hook improvements
- **Minor** (x.1.0): new features, new skill capabilities
- **Major** (1.0.0): breaking changes

After pushing, consumers update via:

```
/plugin marketplace update aiot-skills
/plugin update aiot-ai-agent-skills@aiot-skills
```

## Skill Development

Skills follow the [skill-creator](https://github.com/anthropics/skills) best practices:

- **SKILL.md must stay under 500 lines** — use `references/` for detailed content
- **Frontmatter**: only `name` and `description` fields (no `allowed-tools`, no `argument-hint`)
- **Description**: include all trigger keywords — this is how the skill gets activated
- **Progressive disclosure**: keep core workflow in SKILL.md, split details into `references/`

## Commit Convention

Use [Angular Commit Convention](https://github.com/angular/angular/blob/main/CONTRIBUTING.md#commit): `<type>(<scope>): <subject>`

Types: `feat`, `fix`, `docs`, `build`, `refactor`, `test`, `style`, `perf`, `ci`
