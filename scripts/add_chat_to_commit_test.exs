ExUnit.start()

defmodule AddChatToCommitTest do
  use ExUnit.Case, async: true

  test "placeholder — script loads and module is defined" do
    assert Code.ensure_loaded?(AddChatToCommit)
  end
end
