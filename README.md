# Playground

A Phoenix project that served as a sandbox for building two reusable tools with Cursor AI:

1. A **Cursor skill** for automating new Phoenix project setup
2. An **Elixir script** for annotating git commits with chat transcript context

## Phoenix Project Setup Skill

`.cursor/skills/phoenix-project-setup/SKILL.md`

A reusable [Cursor AI skill](https://docs.cursor.com/context/skills) that automates the repetitive post-`mix phx.new` setup steps: formatter config, dependency updates, CSS/JS asset wiring, optional DaisyUI and PhoenixTest integration, and more. Each step is designed to be committed individually for a clean git history.

## Commit Format Rule

`AGENTS.md`

The annotation script depends on commit markers appearing in the chat transcript. To make this happen, we added a rule to `AGENTS.md` that instructs Cursor to print a standardized line after every git commit: `Committed: \`<sha>\` at <timestamp> — <subject>`. When the conversation is exported to a transcript file, these markers become the anchors that the annotation script uses to match chat segments to their corresponding commits. This creates a feedback loop: the AI follows the rule, the transcript captures the markers, and the script stitches it all together.

For shared projects where modifying the top-level `AGENTS.md` isn't an option, you can add the same rule to `AGENTS.local.md` instead (which is typically gitignored and personal to you).

## Commit Annotation Script

`scripts/annotate_commits.exs`

An Elixir script that annotates unpushed git commits with their corresponding conversation from a chat transcript file. It parses the transcript for commit markers, matches them to unpushed commits, and uses `git filter-branch` to append the relevant chat context to each commit message. The script is idempotent and only touches unpushed history.

### Usage

```bash
# Annotate unpushed commits with transcript context
./scripts/annotate_commits.exs --file TRANSCRIPT.md

# Preview what would be annotated (no changes)
./scripts/annotate_commits.exs --file TRANSCRIPT.md --dry-run

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
