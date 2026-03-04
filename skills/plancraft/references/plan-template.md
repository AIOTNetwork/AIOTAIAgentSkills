# plan.md Template

Copy this template when creating a new plan.md.

```markdown
# Plan: [Feature/Task Name]

## Objective
What we're building and why.

## References
<!-- Paste or link reference implementations here -->
- [Reference 1]: description of what to adopt from it
- [Reference 2]: existing pattern in our codebase to follow

## Approach
Detailed explanation of the implementation strategy.

## Changes
### file: path/to/file.ext
- What changes and why
- Code snippet showing the actual change

### file: path/to/other.ext
- ...

## Considerations
- Trade-offs and alternatives considered
- Risks and mitigation

## Non-Functional Requirements
<!-- Optional: specify if the task has performance, security, or accessibility implications -->
- **Performance:** [e.g., "endpoint must respond < 200ms at p95", or "N/A"]
- **Security:** [e.g., "requires auth, input sanitization", or "N/A"]
- **Accessibility:** [e.g., "must meet WCAG 2.1 AA", or "N/A"]

## Team Roles
<!-- Added in Phase 2 when team-based implementation is anticipated -->
<!-- Review and adjust roles before approving the plan -->

| Role | Justification | Assigned Tasks |
|------|---------------|----------------|
| `role-name` | Why this role is needed | Which todo items they'll own |

## Open Questions
- Anything that needs human input

## Resolved Annotations
<!-- Addressed notes move here for audit trail -->

## Todo
<!-- Added in Phase 4 -->

## Quality Metrics
<!-- Updated during implementation by team lead -->

| Task | Developer | QA Verdict | PM Verdict | Fix Iterations | Notes |
|------|-----------|------------|------------|----------------|-------|

## Discovered Knowledge
<!-- Technical insights discovered during implementation — candidates for project documentation -->

## Retrospective
<!-- Added after implementation completes -->
```
