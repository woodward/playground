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

  def already_amended?(message) do
    String.contains?(message, @annotation_marker)
  end

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

  def init(marker_path) do
    marker = generate_marker()
    write_marker(marker_path, marker)
    IO.puts(marker)
  end

  def run(opts) do
    file = Keyword.fetch!(opts, :file)
    marker_path = Keyword.fetch!(opts, :marker_path)
    work_dir = Keyword.get(opts, :work_dir, ".")
    dry_run = Keyword.get(opts, :dry_run, false)
    force = Keyword.get(opts, :force, false)

    with {:ok, marker} <- read_marker(marker_path),
         {:ok, transcript} <- File.read(file),
         chat when is_binary(chat) <- trim_transcript(transcript, marker) do
      {original_msg, 0} =
        System.cmd("git", ["log", "-1", "--format=%B"], cd: work_dir, stderr_to_stdout: true)

      original_msg = String.trim(original_msg)

      cond do
        already_amended?(original_msg) ->
          IO.puts(yellow() <> "Already amended — skipping." <> reset())

        !force and head_pushed?(work_dir) ->
          IO.puts(yellow() <> "HEAD is already pushed to remote. Use --force to amend anyway." <> reset())

        dry_run ->
          print_dry_run_preview(original_msg, chat)

        true ->
          if force, do: IO.puts(yellow() <> "Warning: amending a pushed commit." <> reset())
          amend_commit(original_msg, chat, work_dir, marker_path)
      end
    else
      {:error, :not_found} ->
        IO.puts(red() <> "Error: marker file not found. Run with --init first." <> reset())

      {:error, :marker_not_found} ->
        IO.puts(red() <> "Error: marker not found in transcript." <> reset())

      {:error, reason} ->
        IO.puts(red() <> "Error reading transcript: #{inspect(reason)}" <> reset())
    end
  end

  defp head_pushed?(work_dir) do
    case System.cmd("git", ["rev-parse", "--abbrev-ref", "@{u}"], cd: work_dir, stderr_to_stdout: true) do
      {_upstream, 0} ->
        {output, _} = System.cmd("git", ["log", "@{u}..HEAD", "--oneline"], cd: work_dir, stderr_to_stdout: true)
        String.trim(output) == ""

      _ ->
        false
    end
  end

  defp amend_commit(original_msg, chat, work_dir, marker_path) do
    new_msg = build_message(original_msg, chat)

    {_output, 0} =
      System.cmd("git", ["commit", "--amend", "-m", new_msg],
        cd: work_dir,
        stderr_to_stdout: true
      )

    new_marker = generate_marker()
    write_marker(marker_path, new_marker)

    IO.puts(green() <> "Amended commit with chat transcript." <> reset())
    IO.puts("New marker: #{new_marker}")
  end

  defp print_dry_run_preview(original_msg, chat) do
    desc_lines = String.split(original_msg, "\n")
    chat_lines = String.split(chat, "\n")
    chat_count = length(chat_lines)

    IO.puts(cyan() <> bright() <> "dry run preview:" <> reset())
    IO.puts("")

    # Description bookend: first 3 lines
    desc_lines
    |> Enum.take(3)
    |> Enum.each(&IO.puts(faint() <> "  " <> &1 <> reset()))

    if length(desc_lines) > 3, do: IO.puts(faint() <> "  ..." <> reset())

    IO.puts("")
    IO.puts("  ---")
    IO.puts("  " <> bright() <> "## Chat Transcript" <> reset())
    IO.puts("")

    # Chat bookend: first 3 lines
    chat_lines
    |> Enum.take(3)
    |> Enum.each(&IO.puts(faint() <> "  " <> &1 <> reset()))

    if chat_count > 6 do
      IO.puts(faint() <> "  ..." <> reset())

      chat_lines
      |> Enum.take(-3)
      |> Enum.each(&IO.puts(faint() <> "  " <> &1 <> reset()))
    end

    IO.puts("")
    IO.puts(yellow() <> "#{chat_count} chat lines" <> reset() <> " would be appended.")
  end

  @default_marker_path ".local/last_chat_marker.txt"

  def default_marker_path, do: @default_marker_path

  def usage do
    IO.puts("""

    #{cyan() <> bright()}Amend With Chat#{reset()} #{faint()}—#{reset()} amend last commit with chat transcript context

    #{green() <> bright()}USAGE#{reset()}
      #{cyan()}./scripts/amend_with_chat.exs#{reset()} #{yellow()}--file#{reset()} TRANSCRIPT.md              #{faint()}# amend HEAD#{reset()}
      #{cyan()}./scripts/amend_with_chat.exs#{reset()} #{yellow()}--file#{reset()} TRANSCRIPT.md #{yellow()}--dry-run#{reset()}    #{faint()}# preview only#{reset()}
      #{cyan()}./scripts/amend_with_chat.exs#{reset()} #{yellow()}--file#{reset()} TRANSCRIPT.md #{yellow()}--force#{reset()}      #{faint()}# amend even if pushed#{reset()}
      #{cyan()}./scripts/amend_with_chat.exs#{reset()} #{yellow()}--init#{reset()}                             #{faint()}# bootstrap marker file#{reset()}
      #{cyan()}./scripts/amend_with_chat.exs#{reset()} #{yellow()}--test#{reset()}                             #{faint()}# run self-tests#{reset()}
      #{cyan()}./scripts/amend_with_chat.exs#{reset()} #{yellow()}--help#{reset()}                             #{faint()}# show this help#{reset()}

    #{green() <> bright()}OPTIONS#{reset()}
      #{yellow()}--file#{reset()} FILE    Path to the exported chat transcript #{red()}(required for amend)#{reset()}
      #{yellow()}--dry-run#{reset()}      Preview the amended message without modifying the commit
      #{yellow()}--force#{reset()}        Allow amending commits already pushed to remote
      #{yellow()}--init#{reset()}         Generate a new marker and save to #{faint()}#{@default_marker_path}#{reset()}
      #{yellow()}--test#{reset()}         Run ExUnit tests
      #{yellow()}--help#{reset()}         Show this help message
    """)
  end
end

# --------------------------------------------------------------------------------------------------

{opts, _args, _invalid} =
  OptionParser.parse(System.argv(),
    switches: [
      test: :boolean,
      help: :boolean,
      init: :boolean,
      file: :string,
      dry_run: :boolean,
      force: :boolean
    ]
  )

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

  opts[:init] ->
    AmendWithChat.init(AmendWithChat.default_marker_path())

  opts[:file] ->
    AmendWithChat.run(
      file: opts[:file],
      marker_path: AmendWithChat.default_marker_path(),
      dry_run: opts[:dry_run] || false,
      force: opts[:force] || false
    )

  true ->
    AmendWithChat.usage()
end
