---
name: Refactor test setup
overview: "Refactor the integration tests to use an ExUnit `setup :setup_repo` callback inside the describe block, so setup_repo receives the context with tmp_dir and returns [work_dir: work_dir]."
todos:
  - id: refactor-setup-repo
    content: "Change setup_repo from defp setup_repo(tmp_dir) to defp setup_repo(%{tmp_dir: tmp_dir}), returning [work_dir: work_dir]"
    status: pending
  - id: add-setup-directive
    content: "Add `setup :setup_repo` once at the top of the integration describe block"
    status: pending
  - id: update-tests
    content: "Update all 4 integration tests: change %{tmp_dir: tmp_dir} to %{work_dir: work_dir}, remove manual setup_repo call"
    status: pending
  - id: verify-and-commit
    content: Run tests, verify all 9 pass, commit
    status: pending
isProject: false
---

# Refactor Test Setup to Idiomatic ExUnit Pattern

## Current state

Each integration test in [scripts/annotate_commits_test.exs](scripts/annotate_commits_test.exs) does:

```elixir
@tag :tmp_dir
test "...", %{tmp_dir: tmp_dir} do
  %{work_dir: work_dir} = setup_repo(tmp_dir)
  # ...
end
```

## Target state

Register `setup_repo` as a named setup callback once at the top of the describe block. The function receives the full ExUnit context (which includes `tmp_dir` from the tag), creates the repo, and returns `[work_dir: work_dir]` to merge into the context:

```elixir
describe "annotate_commits/2 integration" do
  setup :setup_repo

  @tag :tmp_dir
  test "annotates unpushed commits...", %{work_dir: work_dir} do
    # work_dir is ready to use
  end
end
```

And the setup function signature changes to:

```elixir
defp setup_repo(%{tmp_dir: tmp_dir}) do
  # ... same repo creation logic ...
  [work_dir: work_dir]
end
```

## Changes

- **Refactor** `setup_repo/1` signature from `defp setup_repo(tmp_dir)` to `defp setup_repo(%{tmp_dir: tmp_dir})`, and change its return from `%{work_dir: ..., bare_dir: ...}` to `[work_dir: work_dir]`
- **Add** `setup :setup_repo` once at the top of the `"annotate_commits/2 integration"` describe block
- **Update** all 4 integration tests:
  - Change pattern match from `%{tmp_dir: tmp_dir}` to `%{work_dir: work_dir}`
  - Remove the `%{work_dir: work_dir} = setup_repo(tmp_dir)` line from each test body
- **Run tests** to verify all 9 pass
- **Commit**
