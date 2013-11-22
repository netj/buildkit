#!/usr/bin/env bash
set -eu

#DocumentUpOptions+=(
#    google_analytics="UA-...."
#)

#insert-footer() {
#    echo '&copy; '"$(date +%Y)"' '"$(git config user.name)"'.'
#}

#insert-nav-extras() {
#    echo '<div class="extra"><a href="http://'"${GitHubRepo%/*}"'.github.io/'"${GitHubRepo#*/}"'">Home</a></div>'
#    echo '<div class="extra"><a href="https://github.com/'"$GitHubRepo"'"><i class="fa fa-github"></i> Source Code</a></div>'
#    echo '<div class="extra"><a href="https://github.com/'"$GitHubRepo"'/issues"><i class="fa fa-bug"></i> Issues</a></div>'
#}
#insert-nav-footer() {
#    echo '<a href="http://'"${GitHubRepo%/*}"'.github.io/'"${GitHubRepo#*/}"'">Home</a>'
#}

mirror-master .
compile-markdown . name="${GitHubRepo#*/}"
