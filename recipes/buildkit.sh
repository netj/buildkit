#!/usr/bin/env bash
# buildkit.sh -- basis for defining BuildKit module recipes (compilation rules)
#
# Author: Jaeho Shin <netj@sparcs.org>
# Created: 2014-06-12
set -eu

# the compile command for smart compilation
shopt -s extglob globstar
compile() {
    local from= to= with= src= out=
    while [[ $# -gt 0 ]]; do
        ! [[ -e "$1" ]] || break
        case $1 in
            @(from|to|with|src|out)=*)
                declare "$1"
                shift
                ;;
            *=*)
                echo >&2 "$1: Unrecognized argument for compile rules"
                false
                ;;
            *)
                break
        esac
    done
    local s=
    for s; do
        [[ -e "$s" ]] || continue
        local sDir=$(dirname "$s")
        local outDir=$(printf "${out:-%s}" "$sDir")
        mkdir -p "$outDir"
        if [ -n "$src" ]; then
            local srcDir=$(printf "$src" "$sDir")
            mkdir -p "$srcDir"
            relsymlink "$s" "$srcDir"/
        else
            # skip empty $outDir and/or $srcDir
            local srcDir=$sDir
        fi
        local srcDirFromOutDir=$(relpath "$outDir" "$srcDir")
        local name=$(basename "$s")
        local srcFile="$srcDirFromOutDir"/"$name"
        local outFile="${name%$from}$to"
        [[ ! "$outDir"/"$outFile" -nt "$outDir"/"$srcFile" ]] || continue
        ( cd "$outDir"
          "$with" "$srcFile" "$outFile" .
        )
    done
}
