ExUnit.start()

defmodule CommitAnnotatorTest do
  use ExUnit.Case, async: true

  describe "parse_transcript/1" do
    test "extracts a single commit segment" do
      transcript = """
      **User**

      Can you alphabetize the dependencies in mix.exs?

      ---

      **Cursor**

      Done — dependencies are now alphabetized.

      Committed: `56fc54c` at 2026-02-14 13:15:32 — Alphabetize mix.exs dependencies
      """

      segments = CommitAnnotator.parse_transcript(transcript)

      assert length(segments) == 1
      [segment] = segments
      assert segment.sha == "56fc54c"
      assert segment.timestamp == "2026-02-14 13:15:32"
      assert segment.subject == "Alphabetize mix.exs dependencies"
      assert segment.conversation =~ "Can you alphabetize the dependencies"
      assert segment.conversation =~ "Done — dependencies are now alphabetized."
    end

    test "extracts multiple commit segments in order" do
      transcript = """
      **User**

      Can you alphabetize the dependencies?

      ---

      **Cursor**

      Done — alphabetized.

      Committed: `aaa1111` at 2026-02-14 13:00:00 — Alphabetize dependencies

      ---

      **User**

      Now update the versions please.

      ---

      **Cursor**

      Updated all versions.

      Committed: `bbb2222` at 2026-02-14 13:10:00 — Update dependency versions

      ---

      **User**

      Thanks, looks great!
      """

      segments = CommitAnnotator.parse_transcript(transcript)

      assert length(segments) == 2

      [first, second] = segments

      assert first.sha == "aaa1111"
      assert first.subject == "Alphabetize dependencies"
      assert first.conversation =~ "Can you alphabetize the dependencies"
      assert first.conversation =~ "Done — alphabetized."

      assert second.sha == "bbb2222"
      assert second.subject == "Update dependency versions"
      assert second.conversation =~ "Now update the versions"
      assert second.conversation =~ "Updated all versions."
    end

    test "returns empty list when no commits found" do
      transcript = """
      **User**

      Just chatting, no commits here.

      ---

      **Cursor**

      Sure, let's just talk!
      """

      assert CommitAnnotator.parse_transcript(transcript) == []
    end
  end
end
