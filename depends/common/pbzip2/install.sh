#!/usr/bin/env bash
set -eu

name=pbzip2
version=1.1.13
sha1sum=f61e65a7616a3492815d18689c202d0685fe167d
md5sum=4cb87da2dba05540afce162f34b3a9a6
ext=.tar.gz

fetch-configure-build-install $name-$version <<END
url=https://launchpad.net/$name/${version%.*}/$version/+download/$name-$version$ext
sha1sum=$sha1sum
md5sum=$md5sum
custom-configure() { :; }
custom-install() {
    default-install PREFIX="\$prefix"
    install-shared-libraries-required-by "\$prefix"/lib "\$prefix"/bin/*
}
END
