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
end
