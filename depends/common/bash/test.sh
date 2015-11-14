#!/usr/bin/env bash

# check bash version
version=4.2

if [[ $(set -- $(bash --version | head -1); echo "$4") < $version ]]; then
    echo >&2 "bash >= $version not found"
    false
fi

