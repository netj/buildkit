#!/usr/bin/env bash
# install mongodb
set -eu

version=${DEPENDS_ON_MONGO_VERSION:-2.4.9}

self=$0
name=`basename "$0" .sh`

mkdir -p prefix

arch=$(uname -m)
os=$(uname -s)
case $os in
    Darwin) os=osx ;;
    Linux)  os=linux ;;
esac

# download and extract MongoDB binary distribution for the machine
fullname="mongodb-$os-$arch-${version}"
tarball="${fullname}.tgz"
[ -s "$tarball" ] ||
    curl -C- -RLO "http://fastdl.mongodb.org/$os/$tarball"
tar xf "$tarball" -C prefix

# place wrappers or symlinks for commands under $DEPENDS_PREFIX/bin/
wrappers-under-depends-prefix-with-libdirs prefix/"$fullname"/lib bin -x prefix/"$fullname"/bin/*
