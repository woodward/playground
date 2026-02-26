ExUnit.start()

defmodule AmendWithChatTest do
  use ExUnit.Case, async: true

  @marker_regex ~r/^MARK - \d{4}-\d{2}-\d{2} \d{2}:\d{2}$/

  describe "generate_marker/0" do
    test "returns a marker matching the expected format" do
      marker = AmendWithChat.generate_marker()
      assert Regex.match?(@marker_regex, marker)
    end

    test "contains the current date" do
      marker = AmendWithChat.generate_marker()
      today = Date.utc_today() |> Date.to_string()
      assert String.contains?(marker, today)
    end
  end

  describe "marker file I/O" do
    @tag :tmp_dir
    test "write_marker then read_marker round-trips", %{tmp_dir: tmp_dir} do
      path = Path.join(tmp_dir, "last_chat_marker.txt")
      marker = "MARK - 2026-02-26 11:30"

      AmendWithChat.write_marker(path, marker)
      assert {:ok, ^marker} = AmendWithChat.read_marker(path)
    end

    @tag :tmp_dir
    test "read_marker returns error when file does not exist", %{tmp_dir: tmp_dir} do
      path = Path.join(tmp_dir, "nonexistent.txt")
      assert {:error, :not_found} = AmendWithChat.read_marker(path)
    end
  end

  describe "trim_transcript/2" do
    test "returns content after the marker line" do
      transcript = """
      Old conversation before the marker.

      ---

      **User**

      Some old question

      MARK - 2026-02-25 17:34

      **User**

      Please fix the login bug

      ---

      **Cursor**

      Fixed the login bug.
      """

      result = AmendWithChat.trim_transcript(transcript, "MARK - 2026-02-25 17:34")

      refute result =~ "Old conversation"
      refute result =~ "Some old question"
      refute result =~ "MARK - 2026-02-25 17:34"
      assert result =~ "Please fix the login bug"
      assert result =~ "Fixed the login bug."
    end

    test "returns error when marker is not found in transcript" do
      transcript = """
      **User**

      Some conversation with no marker.
      """

      assert {:error, :marker_not_found} =
               AmendWithChat.trim_transcript(transcript, "MARK - 2026-02-25 17:34")
    end
  end
end
