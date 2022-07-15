#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-07-15 11:16:44 +0100 (Fri, 15 Jul 2022)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
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

# shellcheck disable=SC1090
. "$srcdir/lib/github.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Pushes the current branch to GitHub origin, sets upstream branch, then raises a Pull Request to the given or default branch
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<target_base_branch> <title> <description>]"

help_usage "$@"

#min_args 1 "$@"
max_args 3 "$@"

check_github_origin

base_branch="${1:-$(default_branch)}"
export GITHUB_PULL_REQUEST_TITLE="${2:-}"
export GITHUB_PULL_REQUEST_BODY="${3:-}"

current_branch="$(current_branch)"

git push --set-upstream origin "$(current_branch)"

output="$("$srcdir/github_pull_request_create.sh" "$current_branch" "$base_branch" 2>&1)"

echo "$output"

# defined in lib/github.sh
# shellcheck disable=SC2154
url="$(grep -Eom1 "$github_pull_request_url_regex" <<< "$output" || :)"

if [ -z "$url" ]; then
    die "Failed to parse Pull Request URL from output"
fi

echo
if is_mac; then
    echo "Opening Pull Request"
    open "$url"
elif [ -n "${BROWSER:-}" ]; then
    echo "Opening Pull Request using \$BROWSER"
    "$BROWSER" "$url"
else
    echo "\$BROWSER environment variable not set and not on Mac to use default browser, not opening browser"
fi