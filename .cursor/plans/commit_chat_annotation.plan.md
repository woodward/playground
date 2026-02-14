---
name: Commit Chat Annotation
overview: Add a rule to AGENTS.md for consistent commit output format, update the phoenix-project-setup skill, and create a self-testing Elixir script that annotates unpushed git commits with their corresponding chat transcript from TRANSCRIPT.md.
todos:
  - id: rule
    content: Add commit format rule to AGENTS.md (do immediately)
    status: pending
  - id: skill
    content: Add rule-check step to phoenix-project-setup skill
    status: pending
  - id: script-core
    content: Create scripts/annotate_commits.exs with CommitAnnotator module (parse, match, amend)
    status: pending
  - id: script-tests
    content: Add ExUnit self-tests with @tag :tmp_dir for isolated git repo testing
    status: pending
  - id: test-run
    content: Test the script against our actual repo
    status: pending
  - id: commit
    content: Commit everything
    status: pending
isProject: false
---

# Commit Chat Annotation

## Part 1: Add commit format rule to AGENTS.md (do first)

Add a rule to [AGENTS.md](AGENTS.md) requiring a consistent format after every git commit:

```
Committed: `abc1234` at 2026-02-14 13:15:32 — Set formatter line length to 120 and reformat project
```

This must be done immediately so all subsequent commits in this session (and future sessions) produce parseable output in transcripts.

The timestamp comes from `git log -1 --format='%ci'` right after the commit.

## Part 2: Update phoenix-project-setup skill

Make this the **new Step 1** (before all other steps, shifting existing steps down) in [.cursor/skills/phoenix-project-setup/SKILL.md](.cursor/skills/phoenix-project-setup/SKILL.md):

- Ensure the AGENTS.md file contains the commit format rule (the `Committed:` line format)

This must be the very first step so the rule is in place before any commits happen in a new project.

## Part 3: Elixir script — `scripts/annotate_commits.exs`

### What it does

1. Reads `TRANSCRIPT.md` from the repo root
2. Parses it into conversation segments, splitting on the commit marker pattern: `Committed: \`([a-f0-9]+) at (\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) — (.+)`
3. Gets the list of unpushed commits authored by the current user: `git log --format=... origin/main..HEAD` (or similar)
4. For each unpushed commit whose SHA matches a marker in the transcript:
  - Skip if the commit message already contains `## Chat Transcript` (idempotency)
  - Amend the commit message by appending `## Chat Transcript` heading + the conversation text for that segment
5. Uses `git rebase --exec` or interactive rebase to rewrite the relevant commits (since you can't amend non-HEAD commits directly)

### Key design decisions

- **Matching**: by short SHA from the `Committed:` marker in the transcript
- **Idempotency**: check for `## Chat Transcript` already present in commit message; skip if found
- **Safety**: only touch commits that are (a) unpushed and (b) authored by the current git user
- **History rewriting**: this will change SHAs of all amended commits and their descendants; this is acceptable since they are unpushed

### Rebase approach

Since we need to amend commits that aren't HEAD, the script will need to use `git filter-branch`, `git rebase`, or build a sequence of cherry-picks. The simplest reliable approach:

1. Find the oldest commit to amend
2. Use `GIT_SEQUENCE_EDITOR` with a script that changes `pick` to `edit` for target commits
3. For each stopped commit, amend the message and continue
4. Alternatively: use `git filter-branch --msg-filter` which is simpler for message-only changes

`git filter-branch --msg-filter` is likely the cleanest since we're only changing messages, not content.

### Self-testing with ExUnit

The script supports a `--test` flag:

- `mix run scripts/annotate_commits.exs` — normal execution
- `mix run scripts/annotate_commits.exs -- --test` — runs ExUnit tests

Tests use `@tag :tmp_dir` to create isolated git repos and cover:

- Commit with matching transcript gets annotated correctly
- Already-annotated commit is skipped (idempotency)
- Pushed commits are not touched
- Commits by different authors are not touched
- Multiple commits in sequence are all annotated
- Transcript with no matching commits produces no changes

### Script structure

```
defmodule CommitAnnotator do
  def run(repo_path, transcript_path)
  def parse_transcript(content)          # returns list of {sha, timestamp, subject, conversation_text}
  def unpushed_commits(repo_path)        # returns list of {sha, author, subject, body}
  def annotate_commits(repo_path, segments)  # performs the rebase/filter-branch
  def already_annotated?(commit_body)    # checks for ## Chat Transcript heading
end
```

### Commit message output format

```
Original commit subject

Original commit body (if any)

## Chat Transcript

**User**
Can you alphabetize the dependencies in mix.exs?

---

**Cursor**
Done — dependencies are now alphabetized.

Committed: `56fc54c` at 2026-02-14 13:15:32 — Alphabetize mix.exs dependencies
```

