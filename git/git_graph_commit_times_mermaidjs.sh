#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-10-04 03:03:56 +0300 (Fri, 04 Oct 2024)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/git.sh"

repolist="$(readlink -f "$srcdir/../setup/repos.txt")"

image="git_commit_times.svg"
data="git_commit_times.dat"
code="git_commit_times.mmd"

# shellcheck disable=SC2034,SC2154
usage_description="
Graphs the Git commit times from all adjacent Git repos listed in:

    $repolist

Generates the MermaidJS code and then uses MermaidJS CLI to generate the image

    $code - Image

    $image - Code

The adjacent script ../github/github_graph_commit_times_mermaidjs.sh does a similar function but using GitHub API commit data

A GNUplot version of this script is adjacent at:

    git_graph_commit_times.sh

A Golang version of this program which uses the GitHub API can be found here:

    https://github.com/HariSekhon/GitHub-Graph-Commit-Times

Requires Git and MermaidJS CLI (mmdc) to be installed to generate the graphs
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

num_args 0 "$@"

check_bin mmdc

trap_cmd "rm -f '$data'"

if ! [ -f "$data" ]; then
    timestamp "Getting list of Git repo checkout directories from: $repolist"
    repo_dirs="$(sed 's/#.*//; s/.*://; /^[[:space:]]*$/d' "$repolist")"

    timestamp "Found repos: $(wc -l <<< "$repo_dirs" | sed 's/[[:space:]]/g')"
    echo

    while read -r repo_dir; do
        repo_dir="$(readlink -f "$srcdir/../../$repo_dir")"
        timestamp "Entering repo dir: $repo_dir"
        pushd "$repo_dir" &>/dev/null || die "Failed to pushd to: $repo_dir"
        timestamp "Fetching Hour of all commits from Git log"
        git log --date=format:'%H' --pretty=format:'%ad'
        popd &>/dev/null || die "Failed to popd from: $repo_dir"
        echo
    done <<< "$repo_dirs" |
    sort |
    uniq -c |
    awk '{print $2" "$1}' > "$data"
echo
fi

timestamp "Generating MermaidJS code for bar chart of commit times"
cat > "$code" <<EOF
xychart-beta
    title "Git Commits by Hour"
    x-axis [ $(awk '{print $1}' "$data" | tr '\n' ',' | sed 's/,/, /g; s/, $//') ]
    y-axis "Commits"
    bar    [ $(awk '{print $2}' "$data" | tr '\n' ',' | sed 's/,/, /g; s/, $//') ]
    %%line [ $(awk '{print $2}' "$data" | tr '\n' ',' | sed 's/,/, /g; s/, $//') ]
EOF
timestamp "Generated MermaidJS code"
echo

timestamp "Generating MermaidJS bar chart image: $image"
mmdc -i "$code" -o "$image" -t dark --quiet # -b transparent
timestamp "Generated MermaidJS image: $image"

rm "$data"
untrap

if is_CI; then
    exit 0
fi

timestamp "Opening generated bar chart"
"$srcdir/../bin/imageopen.sh" "$image"
