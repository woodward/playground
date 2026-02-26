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
end
