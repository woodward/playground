---
name: Amend with chat
overview: Build an Elixir script (amend_with_chat.exs) that amends the last git commit with chat transcript context, using timestamp-based markers to track session boundaries. Test-driven development with incremental commits.
todos:
  - id: gitignore
    content: Add .local/ to .gitignore
    status: completed
  - id: step1-marker-gen
    content: "TDD: generate_marker/0 — returns MARK - YYYY-MM-DD HH:MM"
    status: completed
  - id: step2-marker-io
    content: "TDD: read_marker/1 and write_marker/2 — file round-trip"
    status: completed
  - id: step3-trim
    content: "TDD: trim_transcript/2 — trim content before marker"
    status: completed
  - id: step4-build-msg
    content: "TDD: build_message/2 — combine commit message + divider + chat"
    status: completed
  - id: step5-idempotency
    content: "TDD: already_amended?/1 — detect existing chat section"
    status: completed
  - id: step6-init
    content: "TDD: --init flag integration"
    status: completed
  - id: step7-amend
    content: "TDD: full amend integration with tmp_dir repo"
    status: completed
  - id: step8-dry-run
    content: "TDD: --dry-run preview output"
    status: completed
  - id: step9-force
    content: "TDD: --force flag for pushed commits"
    status: completed
  - id: step10-idempotency-int
    content: "TDD: refuse second run on same commit"
    status: completed
isProject: false
---

# Amend With Chat Script

## Overview

A new script (`scripts/amend_with_chat.exs`) that amends HEAD's commit message with chat transcript context, trimmed to the current session using timestamp-based markers.

## Design Decisions

- **Marker format**: `MARK - YYYY-MM-DD HH:MM` (regex: `~r/MARK - \d{4}-\d{2}-\d{2} \d{2}:\d{2}/`)
- **Marker file**: `.local/last_chat_marker.txt` (`.local/` added to `.gitignore`)
- **Amend mechanism**: `git commit --amend -m "..."` (not filter-branch)
- **Divider**: `\n\n---\n\n## Chat Transcript\n\n` (same as `annotate_commits.exs`, duplicated)
- **Idempotency**: Refuse with warning if `## Chat Transcript` already in HEAD message
- **Scope**: Always amend HEAD only, one commit per run
- **Code sharing**: None — scripts are fully independent

## CLI Flags

- `--init` — bootstrap: generate marker, write to `.local/last_chat_marker.txt`, print to screen
- `--file FILE` — path to exported transcript
- `--force` — allow amending already-pushed commits
- `--dry-run` — preview: description bookends + chat bookends + stats
- `--test` / `--help` — standard

## Workflow

1. `./scripts/amend_with_chat.exs --init` -> creates marker, prints it
2. User pastes marker into chat, works, commits
3. User exports transcript from Cursor
4. `./scripts/amend_with_chat.exs --file TRANSCRIPT.md` -> trims transcript from marker, amends HEAD, generates new marker
5. Repeat from step 2

## TDD Implementation Steps

Each step: write failing test, implement, verify, commit.

### Step 1: Marker generation

- `generate_marker/0` returns `"MARK - YYYY-MM-DD HH:MM"` using current time
- Test: output matches the regex pattern

### Step 2: Marker file I/O

- `read_marker/1` reads marker from file path, returns `{:ok, marker}` or `{:error, :not_found}`
- `write_marker/2` writes marker to file path
- Test: round-trip write then read

### Step 3: Transcript trimming

- `trim_transcript/2` takes transcript content and marker string, returns everything after the marker line
- Test: given a transcript with a marker in the middle, returns only the content after it

### Step 4: Build amended message

- `build_message/2` takes original commit message and trimmed chat, returns the combined message with divider
- Test: output has original message + `---` + `## Chat Transcript` + chat content

### Step 5: Idempotency check

- `already_amended?/1` checks if commit message contains `## Chat Transcript`
- Test: returns true/false appropriately

### Step 6: `--init` flag

- Integration: `--init` creates `.local/` dir, writes marker file, prints marker
- Test with `@tag :tmp_dir`

### Step 7: Amend commit (integration)

- Full flow: create repo, make commit, run amend with transcript + marker
- Verify HEAD message has original subject + chat content
- Verify new marker was written to file
- Test with `@tag :tmp_dir`

### Step 8: `--dry-run` preview

- Shows first 3-4 lines of description, `...`, divider, first 2-3 lines of chat, `...`, last 2-3 lines of chat, plus line counts

### Step 9: `--force` flag

- Test: amending a pushed commit without `--force` is refused
- Test: amending a pushed commit with `--force` succeeds

### Step 10: Idempotency integration

- Test: running twice on the same commit refuses the second time with warning

## Files

- [scripts/amend_with_chat.exs](scripts/amend_with_chat.exs) — main script
- [scripts/amend_with_chat_test.exs](scripts/amend_with_chat_test.exs) — 15 ExUnit tests
- `.gitignore` — `.local/` entry added

