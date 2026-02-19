# Playground

A Phoenix project that served as a sandbox for building two reusable tools with Cursor AI:

1. A **Cursor skill** for automating new Phoenix project setup
2. An **Elixir script** for annotating git commits with chat transcript context

## Phoenix Project Setup Skill

`.cursor/skills/phoenix-project-setup/SKILL.md`

A reusable [Cursor AI skill](https://docs.cursor.com/context/skills) that automates the repetitive post-`mix phx.new` setup steps: formatter config, dependency updates, CSS/JS asset wiring, optional DaisyUI and PhoenixTest integration, and more. Each step is designed to be committed individually for a clean git history.

## Commit Format Rule

The annotation script depends on commit markers appearing in the chat transcript. The marker format is:

```
Committed: `<short-sha>` at <YYYY-MM-DD HH:MM:SS> — <commit subject>
```

There are two ways to produce these markers:

### Option A: Post-commit hook (recommended)

A `post-commit` git hook can print the marker automatically after every commit. The AI agent sees the hook output in its shell response and copies it verbatim into the conversation — no manual construction needed.

```bash
#!/bin/sh
# .git/hooks/post-commit
sha=$(git log -1 --format='%h')
timestamp=$(git log -1 --format='%ci' | cut -c1-19)
subject=$(git log -1 --format='%s')

echo ""
echo "Committed: \`${sha}\` at ${timestamp} — ${subject}"
```

Pair this with an `AGENTS.md` (or `AGENTS.local.md`) rule telling the agent to copy the `Committed:` line from the hook output verbatim.

### Option B: AGENTS.md rule only

Add this rule to your `AGENTS.md`:

```markdown
- After every git commit, **always** display the result using this exact format (on a single line):
  `Committed: \`<short-sha>\` at <YYYY-MM-DD HH:MM:SS> — <commit subject>`
  The timestamp comes from `git log -1 --format='%ci'` immediately after the commit. Example:
  `Committed: \`abc1234\` at 2026-02-14 13:15:32 — Set formatter line length to 120`
```

This works but is more error-prone over long conversations since the AI constructs the marker from memory.

For shared projects where modifying `AGENTS.md` isn't an option, use `AGENTS.local.md` instead (typically gitignored and personal to you).

### Transcript compatibility notes

Some Cursor UI widgets are **not captured** in exported transcripts:

- **AskQuestion tool** — renders as an interactive widget; prefer presenting options as plain text in messages instead
- **TodoWrite tool** — renders in the sidebar; echo a brief plain-text summary of task updates in your message as well

## Commit Annotation Script

`scripts/annotate_commits.exs`

An Elixir script that annotates git commits with their corresponding conversation from a chat transcript file. It parses the transcript for commit markers, matches them to commits on the current branch, and uses `git filter-branch` to append the relevant chat context to each commit message. The script is idempotent, handles variable-length abbreviated SHAs, and gracefully falls back to `origin/main..HEAD` when there's no upstream tracking branch.

### Usage

```bash
# Annotate unpushed commits with transcript context
./scripts/annotate_commits.exs --file TRANSCRIPT.md

# Preview what would be annotated (no changes)
./scripts/annotate_commits.exs --file TRANSCRIPT.md --dry-run

# Include already-pushed commits (requires git push --force after)
./scripts/annotate_commits.exs --file TRANSCRIPT.md --force

# Run the self-tests
./scripts/annotate_commits.exs --test

# Show help
./scripts/annotate_commits.exs --help
```

### Tests

The script has a companion test file at `scripts/annotate_commits_test.exs` with ExUnit tests covering parsing, annotation formatting, idempotency, dry-run mode, and full integration tests that create isolated git repos via `@tag :tmp_dir`.

## Running the Phoenix App

```bash
mix setup              # install and setup dependencies
iex -S mix phx.server  # start the server with an IEx shell
```

Then visit [localhost:4000](http://localhost:4000).
