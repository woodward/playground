#!/usr/bin/env elixir

defmodule CommitAnnotator do
  @moduledoc """
  Annotates unpushed git commits with their corresponding chat transcript
  from TRANSCRIPT.md.
  """

  import IO.ANSI

  @commit_marker_regex ~r/Committed: `([a-f0-9]+)` at (\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) — (.+)/

  @doc """
  Parses a transcript string into a list of segments, each associated with a commit.

  Returns a list of maps:
    %{sha: "abc1234", timestamp: "2026-02-14 13:15:32", subject: "commit subject", conversation: "..."}
  """
  def parse_transcript(content) do
    parts = Regex.split(@commit_marker_regex, content, include_captures: true)

    parts
    |> Enum.chunk_every(2)
    |> Enum.flat_map(fn
      [conversation, marker] ->
        case Regex.run(@commit_marker_regex, marker) do
          [_, sha, timestamp, subject] ->
            [%{sha: sha, timestamp: timestamp, subject: subject, conversation: String.trim(conversation)}]

          _ ->
            []
        end

      [_trailing] ->
        []
    end)
  end

  def run(opts) do
    file = opts[:file]
    IO.puts(yellow() <> "CommitAnnotator: not yet implemented (file: #{file})" <> reset())
  end

  def usage do
    IO.puts("""

    #{cyan() <> bright()}Annotate Commits#{reset()} #{faint()}—#{reset()} append chat transcripts to unpushed commit messages

    #{green() <> bright()}USAGE#{reset()}
      #{cyan()}./scripts/annotate_commits.exs#{reset()} #{yellow()}--file#{reset()} TRANSCRIPT.md   #{faint()}# annotate commits#{reset()}
      #{cyan()}./scripts/annotate_commits.exs#{reset()} #{yellow()}--test#{reset()}                  #{faint()}# run self-tests#{reset()}
      #{cyan()}./scripts/annotate_commits.exs#{reset()} #{yellow()}--help#{reset()}                  #{faint()}# show this help#{reset()}

    #{green() <> bright()}OPTIONS#{reset()}
      #{yellow()}--file#{reset()} FILE   Path to the transcript markdown file #{red()}(required)#{reset()}
      #{yellow()}--test#{reset()}        Run embedded ExUnit tests
      #{yellow()}--help#{reset()}        Show this help message
    """)
  end
end

{opts, _args, _invalid} =
  OptionParser.parse(System.argv(), switches: [test: :boolean, file: :string, help: :boolean])

cond do
  opts[:test] ->
    Code.require_file("annotate_commits_test.exs", __DIR__)

  opts[:file] ->
    CommitAnnotator.run(opts)

  true ->
    CommitAnnotator.usage()
end
