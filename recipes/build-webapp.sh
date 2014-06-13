#!/usr/bin/env bash
# build-webapp.sh -- BuildKit recipe for web application modules
#                    that need to compile .{js,css,coffee,less} and more
# 
# USAGE
#   . build-webapp.sh
#   # define your rule
# 
# EXAMPLES
#   # Some typical compilation rules for a module using CoffeeScript and LESS are:
#   dest=.build/webapp
#   mkdir -p $dest/{coffee,css,less,js}
#   compile from=.coffee to=.js     with=compile-coffee        src=$dest/coffee/ out=$dest/js/         coffee/*.coffee
#   compile from=.less   to=.css    with=compile-less          src=$dest/less/   out=$dest/css/        less/*.less
# 
#   # If you use requirejs, you might want to convert some code to AMD first
#   compile from=.coffee to=.coffee with=convert-AMD-coffee src=              out=$dest/coffee/ **/!(main).coffee
#   compile from=.coffee to=.js     with=compile-coffee     src=              out=$dest/js/     $dest/coffee/!(main).coffee
#   compile from=.coffee to=.js     with=compile-coffee     src=$dest/coffee/ out=$dest/js/     coffee/main.coffee
#
# Author: Jaeho Shin <netj@sparcs.org>
# Created: 2014-06-12
set -eu
. buildkit.sh

# how to compile CoffeeScript to JavaScript
compile-coffee() {
    local src=$1 out=$2
    local outDir=${3:-$(dirname "$out")}
    [[ "$src" -nt "$out" ]] || return 0
    echo >&2 "Compiling $out from $src..."
    coffee -m -o "$outDir" -c "$src"
}

# how to compile LESS to CSS
compile-less() {
    local src=$1 out=$2
    local outDir=${3:-$(dirname "$out")}
    [[ "$src" -nt "$out" ]] || return 0
    echo >&2 "Compiling $out from $src..."
    lessc "$src" "$out"
}

# how to convert plain JS/CS codes to AMD modules
convert-AMD-js() {
    local src=$1 out=$2
    case $out in */) out+=$(basename "$src") ;; esac
    local outDir=${3:-$(dirname "$out")} prologue=${4:-} epilogue=${5:-}
    [[ "$src" -nt "$out" ]] || return 0
    echo >&2 "Converting to AMD $out from $src..."
    rm -f "$out"
    {
        echo -n 'define(function(require, exports, module) { return (function(){ '"$prologue"
        cat "$src"
        echo "$epilogue"'}); });'
    } >"$out"
}
convert-AMD-coffee() {
    local src=$1 out=$2
    case $out in */) out+=$(basename "$src") ;; esac
    local outDir=${3:-$(dirname "$out")}
    [[ "$src" -nt "$out" ]] || return 0
    echo >&2 "Converting to AMD $out from $src..."
    rm -f "$out"
    {
        echo -n 'define (require) -> ("use strict"; '
        cat "$src"
        echo ')'
    } >"$out"
}

minify-js() {
    local src=$1 out=$2
    local outDir=${3:-$(dirname "$out")}
    [[ "$src" -nt "$out" ]] || return 0
    echo >&2 "Minifying $out from $src..."
    uglifyjs "$src" -o "$out" -m -c
}
