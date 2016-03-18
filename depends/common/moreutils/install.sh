#!/usr/bin/env bash
set -eu

name=moreutils
version=0.58
sha1sum= #1b53b6669a414f50ea2ec708f4e9d72ad703c784
md5sum= #2fd82a15dea059506a6f43ce717dbfad

fetch-configure-build-install $name-$version <<END
url=https://mirrorservice.org/sites/ftp.debian.org/debian/pool/main/m/moreutils/moreutils_$version.orig.tar.gz
sha1sum=$sha1sum
md5sum=$md5sum
custom-configure() { :; }
custom-build() { make all MANS=; }
custom-install() { make install MANS=README PREFIX="\$2"; }
END
