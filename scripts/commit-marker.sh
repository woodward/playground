#!/bin/sh
# Prints the last commit in the format expected by annotate_commits.exs
sha=$(git log -1 --format='%h')
timestamp=$(git log -1 --format='%ci' | cut -c1-19)
subject=$(git log -1 --format='%s')

echo "Committed: \`${sha}\` at ${timestamp} — ${subject}"
