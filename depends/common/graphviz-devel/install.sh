#!/usr/bin/env bash
set -eu

: ${DEPENDS_TARGET_UNAME:=$(uname)}

name=graphviz-dev
# development snapshot
version=2.39.20160517.2040

fetch-configure-build-install $name-$version <<END
url=http://graphviz.org/pub/graphviz/development/SOURCES/graphviz-${version}.tar.gz
md5sum=\$url.md5

custom-configure() {
    default-configure \
        --enable-silent-rules \
        --disable-debug \
        --disable-dependency-tracking \
        --enable-fast-install \
        --without-x \
        --disable-swig --enable-swig=no \
        --disable-tcl \
        #
}
custom-install() {
    # don't install docs and data, just the executable binaries
    make install-exec
}
END

# XXX GraphViz plugin system works based on a config file whose absolute path is hardcoded at build time.
# To make it relocatable, we need to set the GVBINDIR environment, hence the following workaround.
# See: http://www.graphviz.org/content/can-dot-be-run-without-system-wide-installation
# See: http://www.graphviz.org/doc/info/command.html#d:GVBINDIR
shim=.GVBINDIR-shim
if ! [[ -x prefix/bin/"$shim" ]]; then
    mv -vf prefix/bin prefix/bin.actual
    mkdir -vp prefix/bin
    ( cd prefix/bin
    {
        echo '#!/bin/sh -e'
        echo 'here=`dirname "$0"`; here=`cd "$here" && pwd`'
        echo 'export GVBINDIR="$here"/../lib/graphviz'
        case $DEPENDS_TARGET_UNAME in
            Darwin) # OS X needs special care: https://gist.github.com/netj/d22146213111abcd386a
            # since DYLD_* vars seem to be dropped upon every exec, we need to
            # bring them back before hitting the executable binary
            echo 'export DYLD_LIBRARY_PATH="${_DYLD_LIBRARY_PATH:-}"'
            ;;
        esac
        echo 'exec "$here/../bin.actual/${0##*/}" "$@"'
    } >"$shim"
    chmod -v +x "$shim"
    )
    ( cd prefix/bin.actual
    for x in *; do
        ln -sfnv "$shim" ../bin/"$x"
    done
    )
fi
