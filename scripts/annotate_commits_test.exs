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
  end
end
