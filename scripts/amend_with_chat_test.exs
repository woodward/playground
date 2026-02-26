ExUnit.start()

defmodule AmendWithChatTest do
  use ExUnit.Case, async: true

  test "placeholder — script loads and module is defined" do
    assert Code.ensure_loaded?(AmendWithChat)
  end
end
