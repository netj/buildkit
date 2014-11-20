#!/usr/bin/env bash
set -eu

# the version we're looking for
version=${DEPENDS_ON_NODE_VERSION:-v0.10.26}

# check if nodejs is here
type node npm &>/dev/null || {
    echo >&2 "nodejs not found"
    false
}

# compare versions
versionHere=$(node --version)
vTail=${version#v}           vTailHere=${versionHere#v}
while [[ -n "$vTail" && -n "$vTailHere" ]]; do
    vHead=${vTail%%.*}    vHeadHere=${vTailHere%%.*}
    vTail=${vTail#$vHead} vTailHere=${vTailHere#$vHeadHere}
    vTail=${vTail#.}      vTailHere=${vTailHere#.}
    [[ $vHead -ge $vHeadHere ]] || {
        echo >&2 "nodejs >= $version not found"
        false
    }
done

true
