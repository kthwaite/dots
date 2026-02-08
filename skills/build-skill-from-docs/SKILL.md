---
name: build-skill-from-docs
description: Research a library/tool by reading official docs (prefer llms.txt, then linked docs), optionally cloning source/examples, then author and install a high-quality SKILL.md in .pi/skills (and optionally .claude/skills).
license: MIT
---

# Build Skill From Docs

Use this skill when the user asks for a new skill like:
- "write a skill for X"
- "research this library and make a skill"
- "read docs/source and create a reusable skill"

## Inputs to collect first

- Target library/tool name
- Official docs URL (prefer an `llms.txt` endpoint if available)
- Source repository URL (if available)
- Desired skill name (or derive one)
- Install targets:
  - project-local (`.pi/skills/<name>/SKILL.md`)
  - optional Claude mirror (`.claude/skills/<name>/SKILL.md`)

## Workflow

### 1) Discover and read documentation comprehensively

1. Fetch the entry docs page (prefer `llms.txt`).
2. Follow linked docs pages recursively.
3. Prioritize:
   - getting started / installation
   - architecture and core concepts
   - feature docs
   - guides/recipes/troubleshooting
   - changelog/migration pages
4. Capture concrete API names, required config, dependencies, and common pitfalls.

If `llms.txt` is absent, use:
- README
- `/docs`
- examples/sandboxes
- API references

### 2) Inspect source and examples (when useful)

- Clone or inspect source to confirm behavior and naming.
- Check examples for canonical integration patterns.
- Validate uncertain details against real code.

Suggested shell flow:

```bash
# docs
curl -fsSL <docs_or_llms_url>

# source
git clone <repo_url> /tmp/<repo-name>
```

### 3) Synthesize a practical implementation model

Produce a short internal model covering:
- required setup and install commands
- minimum working integration
- feature dependency map
- extension points/customization
- debugging checklist
- version-specific gotchas from changelog

### 4) Author the skill

Create `SKILL.md` with:
- valid frontmatter (`name`, `description` required)
- concise “when to use” trigger
- reliable setup commands
- copy-pasteable templates/snippets
- dependency and feature matrix
- pitfalls + troubleshooting checklist
- links to official docs

Keep content action-oriented and implementation-first.

## Skill quality checklist (must pass)

- Frontmatter name is valid and matches parent directory.
- Description clearly states when the skill should be used.
- Commands are runnable and realistic.
- Examples include required wiring (not just partial snippets).
- Includes at least one minimal “happy path” template.
- Includes common failure modes and quick fixes.
- Avoids speculative claims not supported by docs/source.

## Install locations

Primary:

```bash
.pi/skills/<skill-name>/SKILL.md
```

Optional mirror for Claude project skills:

```bash
.claude/skills/<skill-name>/SKILL.md
```

## Output format for user handoff

When done, report:
- docs/source reviewed
- file paths created/updated
- short summary of what the new skill covers
- optional next step (e.g. copy to global skills directories)

## Minimal SKILL.md starter template

````markdown
---
name: <skill-name>
description: <what it does + when to use>
---

# <Title>

## When to use
- ...

## Setup
```bash
# install commands
```

## Quick start
```tsx
// minimal working example
```

## Common pitfalls
- ...

## References
- <official docs>
```
````
