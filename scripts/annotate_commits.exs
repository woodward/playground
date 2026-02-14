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
    file = opts[:file] || "TRANSCRIPT.md"
    IO.puts(yellow() <> "CommitAnnotator: not yet implemented (file: #{file})" <> reset())
  end
end

{opts, _args, _invalid} =
  OptionParser.parse(System.argv(), switches: [test: :boolean, file: :string])

if opts[:test] do
  Code.require_file("annotate_commits_test.exs", __DIR__)
else
  CommitAnnotator.run(opts)
end
