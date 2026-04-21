Spawn a subagent to analyze the project structure and code organization.

Review:
- Files that have grown too large or taken on too many responsibilities
- Classes or modules that violate single responsibility principle
- Circular dependencies or tight coupling between modules
- Code that belongs in a separate module but hasn't been extracted yet
- Patterns that will make the codebase harder to maintain as it grows

For each issue found, suggest:
- What the problem is and why it matters
- A concrete refactoring approach
- What the new file/module structure would look like

Report findings only. Do not modify any files.
Format as a prioritized list — most impactful changes first.
