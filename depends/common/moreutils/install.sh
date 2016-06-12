#!/usr/bin/env bash
set -eu

name=moreutils
version=0.59
sha1sum=7731c862384e05243e4856b462185152f87d31ab
md5sum=718900463335f8a9405493c5db5cf4bb

fetch-configure-build-install $name-$version <<END
url=https://github.com/netj/moreutils/archive/$version.tar.gz
sha1sum=$sha1sum
md5sum=$md5sum
custom-configure() { :; }
custom-build() { make all MANS=; }
custom-install() { make install MANS=README PREFIX="\$2"; }
END
