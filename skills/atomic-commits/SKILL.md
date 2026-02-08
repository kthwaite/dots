---
name: atomic-commits
description: Split a dirty git working tree into sensible, atomic commits with conventional commit messages. Use when changes span Rust/backend and UI/frontend code and need careful staging, validation, and commit sequencing.
license: MIT
---

# Atomic Commits

Use this skill when the user asks to:
- "commit these in sensible/atomic commits"
- "split backend and frontend commits"
- "clean up commit history before push"

## Commit standard

Follow repo history style:

```text
<type>(<scope>): <short imperative summary>
```

Common types:
- `feat` new behavior
- `fix` bug fix
- `refactor` behavior-preserving code restructuring
- `test` test additions/changes
- `style` formatting-only edits
- `chore` tooling/config housekeeping
- `docs` documentation-only changes

## Core rules (non-negotiable)

1. **Never use broad staging** (`git add .`, `git add -A`) in a dirty tree.
2. Stage by explicit file list and/or hunk (`git add -p`).
3. Each commit must contain **one logical reason to change**.
4. Keep generated files with their source change (e.g. route generators, lockfiles, schema outputs).
5. Keep formatting-only changes separate from behavior changes when practical.
6. Leave unrelated untracked files untouched.

## Workflow

### 1) Scan and plan

```bash
git status --short
git diff --stat
git log --oneline -n 20
```

Build a commit plan before staging:
- commit message
- file set
- why these files belong together
- validation command(s)

### 2) Execute commit groups one by one

For each planned commit:

1. Stage only relevant files:
   ```bash
   git add <file1> <file2> ...
   ```
2. If a file has mixed concerns, stage only selected hunks:
   ```bash
   git add -p <file>
   ```
3. Verify staged content:
   ```bash
   git diff --cached --stat
   git diff --cached
   ```
4. Run targeted validation for that group.
5. Commit:
   ```bash
   git commit -m "<type>(<scope>): <summary>"
   ```

### 3) Final verification

```bash
git status --short
git log --oneline -n <num_new_commits>
```

Return a concise summary with:
- commits created (hash + message)
- what each commit contains
- remaining unstaged/untracked files

## Validation matrix for this repo

- Rust/backend changes (`src/`, `tests/`, `Cargo.*`):
  ```bash
  cargo test
  ```
- UI changes (`ui/`):
  ```bash
  cd ui && bun run typecheck && bun run lint
  ```

Prefer narrower checks only when they fully cover the changed behavior.

## Rust + UI split heuristic

When both ecosystems changed, default to:
1. backend/core commits
2. backend tests
3. frontend feature/fix commits
4. frontend style/chore commits

Do not combine Rust and UI in one commit unless a single inseparable change requires both.

## Hunk-splitting protocol

If you staged too much:

```bash
git restore --staged <file>
git add -p <file>
```

Repeat until staged diff matches the single-commit intent.

## Done criteria

- Commit history reads as a clear narrative.
- Every commit can be understood without "and also".
- Conventional messages match repository style.
- Working tree contains only intentionally uncommitted files.
