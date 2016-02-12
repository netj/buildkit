#!/usr/bin/env bash
set -eu

name=graphviz
version=2.38.0
sha1sum=053c771278909160916ca5464a0a98ebf034c6ef
md5sum=5b6a829b2ac94efcd5fa3c223ed6d3ae

fetch-configure-build-install $name-$version <<END
#url=http://graphviz.org/pub/graphviz/stable/SOURCES/graphviz-${version}.tar.gz
url=http://pkgs.fedoraproject.org/repo/pkgs/graphviz/graphviz-${version}.tar.gz/${md5sum}/graphviz-${version}.tar.gz
sha1sum=$sha1sum
md5sum=$md5sum
custom-configure() {
    default-configure \
        --enable-silent-rules \
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
