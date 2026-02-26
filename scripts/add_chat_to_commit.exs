#!/usr/bin/env elixir

defmodule AddChatToCommit do
  @moduledoc """
  Adds chat transcript context to git commit messages.
  """

  import IO.ANSI

  def run(_opts) do
    IO.puts("Not yet implemented.")
  end

  def usage do
    IO.puts("""

    #{cyan() <> bright()}Add Chat to Commit#{reset()} #{faint()}—#{reset()} attach chat context to commit messages

    #{green() <> bright()}USAGE#{reset()}
      #{cyan()}./scripts/add_chat_to_commit.exs#{reset()} #{yellow()}--test#{reset()}    #{faint()}# run self-tests#{reset()}
      #{cyan()}./scripts/add_chat_to_commit.exs#{reset()} #{yellow()}--help#{reset()}    #{faint()}# show this help#{reset()}

    #{green() <> bright()}OPTIONS#{reset()}
      #{yellow()}--test#{reset()}    Run ExUnit tests
      #{yellow()}--help#{reset()}    Show this help message
    """)
  end
end

# --------------------------------------------------------------------------------------------------

{opts, _args, _invalid} =
  OptionParser.parse(System.argv(), switches: [test: :boolean, help: :boolean])

script_path = __ENV__.file
test_file = String.replace_trailing(script_path, ".exs", "_test.exs")

cond do
  opts[:test] ->
    if File.exists?(test_file) do
      Code.require_file(test_file)
    else
      IO.puts(IO.ANSI.red() <> "Error: test file not found at #{test_file}" <> IO.ANSI.reset())
      IO.puts("Expected sibling file: #{Path.basename(test_file)} in the same directory as this script.")
      System.halt(1)
    end

  opts[:help] ->
    AddChatToCommit.usage()

  true ->
    AddChatToCommit.usage()
end
