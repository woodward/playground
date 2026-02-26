#!/usr/bin/env elixir

defmodule AmendWithChat do
  @moduledoc """
  Amends the last git commit with chat transcript context.
  """

  import IO.ANSI

  @marker_prefix "MARK"

  def generate_marker do
    now = DateTime.utc_now()
    formatted = Calendar.strftime(now, "%Y-%m-%d %H:%M")
    "#{@marker_prefix} - #{formatted}"
  end

  def write_marker(path, marker) do
    path |> Path.dirname() |> File.mkdir_p!()
    File.write!(path, marker)
  end

  def read_marker(path) do
    case File.read(path) do
      {:ok, content} -> {:ok, String.trim(content)}
      {:error, :enoent} -> {:error, :not_found}
    end
  end

  @annotation_marker "## Chat Transcript"

  def build_message(original, chat) do
    "#{original}\n\n---\n\n#{@annotation_marker}\n\n#{chat}"
  end

  def trim_transcript(content, marker) do
    if String.contains?(content, marker) do
      content
      |> String.split(marker, parts: 2)
      |> List.last()
      |> String.trim()
    else
      {:error, :marker_not_found}
    end
  end

  def run(_opts) do
    IO.puts("Not yet implemented.")
  end

  def usage do
    IO.puts("""

    #{cyan() <> bright()}Amend With Chat#{reset()} #{faint()}—#{reset()} amend last commit with chat transcript context

    #{green() <> bright()}USAGE#{reset()}
      #{cyan()}./scripts/amend_with_chat.exs#{reset()} #{yellow()}--test#{reset()}    #{faint()}# run self-tests#{reset()}
      #{cyan()}./scripts/amend_with_chat.exs#{reset()} #{yellow()}--help#{reset()}    #{faint()}# show this help#{reset()}

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
    AmendWithChat.usage()

  true ->
    AmendWithChat.usage()
end
