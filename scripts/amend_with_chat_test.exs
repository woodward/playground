ExUnit.start()

defmodule AmendWithChatTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO

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

  describe "already_amended?/1" do
    test "returns true when message contains chat transcript marker" do
      message = "Fix a bug\n\n---\n\n## Chat Transcript\n\nSome chat here"
      assert AmendWithChat.already_amended?(message)
    end

    test "returns false for a plain commit message" do
      refute AmendWithChat.already_amended?("Fix a bug\n\nJust a normal description")
    end
  end

  describe "build_message/2" do
    test "combines commit message with divider and chat content" do
      original = "Fix the login bug\n\nDetailed description of the fix."
      chat = "**User**\n\nPlease fix the login bug\n\n---\n\n**Cursor**\n\nFixed it."

      result = AmendWithChat.build_message(original, chat)

      assert String.starts_with?(result, "Fix the login bug\n\nDetailed description of the fix.")
      assert result =~ "\n\n---\n\n## Chat Transcript\n\n"
      assert String.ends_with?(result, chat)
    end
  end

  describe "run/1 integration" do
    defp git(repo_dir, args) do
      {output, 0} = System.cmd("git", args, cd: repo_dir, stderr_to_stdout: true)
      String.trim(output)
    end

    defp setup_repo(%{tmp_dir: tmp_dir}) do
      work_dir = Path.join(tmp_dir, "repo")
      System.cmd("git", ["init", work_dir])
      git(work_dir, ["config", "user.email", "test@test.com"])
      git(work_dir, ["config", "user.name", "Test User"])

      File.write!(Path.join(work_dir, "README.md"), "# Test")
      git(work_dir, ["add", "."])
      git(work_dir, ["commit", "-m", "Initial commit"])

      [work_dir: work_dir]
    end

    @tag :tmp_dir
    test "amends last commit with trimmed chat content", %{tmp_dir: tmp_dir} do
      [work_dir: work_dir] = setup_repo(%{tmp_dir: tmp_dir})

      marker = "MARK - 2026-02-25 17:34"
      marker_path = Path.join(tmp_dir, "marker.txt")
      AmendWithChat.write_marker(marker_path, marker)

      transcript_path = Path.join(work_dir, "TRANSCRIPT.md")

      File.write!(transcript_path, """
      Old conversation before the marker.

      #{marker}

      **User**

      Please fix the login bug

      ---

      **Cursor**

      Fixed the login bug by updating the auth module.
      """)

      output =
        capture_io(fn ->
          AmendWithChat.run(
            file: transcript_path,
            marker_path: marker_path,
            work_dir: work_dir
          )
        end)

      # The commit message should now contain the chat content
      commit_msg = git(work_dir, ["log", "-1", "--format=%B"])
      assert commit_msg =~ "Initial commit"
      assert commit_msg =~ "## Chat Transcript"
      assert commit_msg =~ "Please fix the login bug"
      assert commit_msg =~ "Fixed the login bug by updating the auth module."
      refute commit_msg =~ "Old conversation before the marker"

      # A new marker should be written to the marker file
      {:ok, new_marker} = AmendWithChat.read_marker(marker_path)
      assert Regex.match?(~r/^MARK - \d{4}-\d{2}-\d{2} \d{2}:\d{2}$/, new_marker)
      assert new_marker != marker

      # Output should mention success
      assert output =~ "Amended"
    end
  end

  describe "init/1" do
    @tag :tmp_dir
    test "creates marker file and prints marker to screen", %{tmp_dir: tmp_dir} do
      marker_path = Path.join([tmp_dir, ".local", "last_chat_marker.txt"])

      output = capture_io(fn -> AmendWithChat.init(marker_path) end)

      # Should print the marker to the screen
      assert Regex.match?(@marker_regex, String.trim(output))

      # Should write the marker to the file
      assert {:ok, marker} = AmendWithChat.read_marker(marker_path)
      assert Regex.match?(@marker_regex, marker)

      # Printed marker and saved marker should match
      assert String.trim(output) == marker
    end
  end
end
