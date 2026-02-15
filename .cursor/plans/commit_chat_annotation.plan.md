---
name: Commit Chat Annotation
overview: Add a rule to AGENTS.md for consistent commit output format, update the phoenix-project-setup skill, and create a self-testing Elixir script that annotates unpushed git commits with their corresponding chat transcript from TRANSCRIPT.md.
todos:
  - id: rule
    content: Add commit format rule to AGENTS.md (do immediately)
    status: completed
  - id: skill
    content: Add rule-check step to phoenix-project-setup skill
    status: completed
  - id: script-core
    content: Create scripts/annotate_commits.exs with CommitAnnotator module (parse, match, amend)
    status: completed
  - id: script-tests
    content: Add ExUnit self-tests with @tag :tmp_dir for isolated git repo testing
    status: completed
  - id: test-run
    content: Test the script against our actual repo
    status: completed
  - id: commit
    content: Commit everything
    status: completed
isProject: false
---

# Commit Chat Annotation

All tasks completed! The script has been tested against the real repo and works as expected.

## Part 1: Add commit format rule to AGENTS.md — DONE

Added a rule to [AGENTS.md](AGENTS.md) requiring a consistent format after every git commit:

```
Committed: `abc1234` at 2026-02-14 13:15:32 — Set formatter line length to 120 and reformat project
```

The timestamp comes from `git log -1 --format='%ci'` right after the commit.

## Part 2: Update phoenix-project-setup skill — DONE

Made the rule **Step 1** in [.cursor/skills/phoenix-project-setup/SKILL.md](.cursor/skills/phoenix-project-setup/SKILL.md) so it's in place before any commits happen in a new project.

## Part 3: Elixir script — `scripts/annotate_commits.exs` — DONE

### What it does

1. Reads a transcript file (specified via `--file` flag)
2. Parses it into conversation segments, splitting on the commit marker regex
3. Writes per-SHA annotation files to a temp directory
4. Runs a single `git filter-branch --msg-filter` pass on `@{u}..HEAD` (unpushed commits only)
5. For each commit, the shell filter checks for a matching annotation file and appends the chat transcript
6. Idempotent via two mechanisms: SHA mismatch (rewritten SHAs no longer match) and `## Chat Transcript` marker check

### CLI interface

- `./scripts/annotate_commits.exs --file TRANSCRIPT.md` — annotate commits
- `./scripts/annotate_commits.exs --test` — run ExUnit self-tests
- `./scripts/annotate_commits.exs --help` — show colorized usage

Uses `OptionParser` for flag parsing, `IO.ANSI` for colored output, and `__ENV__.file` for dynamic test file discovery.

### Self-testing with ExUnit — DONE

Tests live in a separate `scripts/annotate_commits_test.exs` file, loaded via `Code.require_file`.

7 tests covering:

- Single commit parsing
- Multiple commit parsing
- Empty transcript (no commits)
- Annotation text formatting
- Idempotency marker detection
- Full integration: annotates unpushed commits in a temp git repo (`@tag :tmp_dir`)
- Full integration: idempotency — running twice does not double-annotate

### Commit message output format

```
Original commit subject

Original commit body (if any)

---

## Chat Transcript

**User**
Can you alphabetize the dependencies in mix.exs?

---

**Cursor**
Done — dependencies are now alphabetized.

Committed: `56fc54c` at 2026-02-14 13:15:32 — Alphabetize mix.exs dependencies
```

