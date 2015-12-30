#!/usr/bin/env bash
set -eu

name=graphviz
version=2.38.0
sha1sum=
md5sum=

fetch-configure-build-install $name-$version <<END
url=http://graphviz.org/pub/graphviz/stable/SOURCES/graphviz-${version}.tar.gz
sha1sum=$sha1sum
md5sum=$md5sum
custom-configure() {
    default-configure --disable-tcl --without-x
}
custom-install() {
    # don't install docs and data, just the executable binaries
    make install-exec
}
END
