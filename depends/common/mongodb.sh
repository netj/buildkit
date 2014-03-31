#!/usr/bin/env bash
# install mongodb
set -eu

version=${DEPENDS_ON_MONGO_VERSION:-2.4.9}

self=$0
name=`basename "$0" .sh`

prefix="$(pwd -P)"/prefix
mkdir -p "$prefix"

arch=$(uname -m)
os=$(uname -s)
case $os in
    Darwin) os=osx ;;
    Linux)  os=linux ;;
esac

# download and extract MongoDB binary distribution for the machine
tarball="mongodb-$os-$arch-${version}.tgz"
[ -s "$tarball" ] ||
    curl -C- -RLO "http://fastdl.mongodb.org/$os/$tarball"
tar xf "$tarball" -C "$prefix"
cd "$prefix"/"${tarball%.tgz}"

# place symlinks for commands to $DEPENDS_PREFIX/bin/
mkdir -p "$DEPENDS_PREFIX"/bin
for x in bin/*; do
    [ -x "$x" ] || continue
    relsymlink "$x" "$DEPENDS_PREFIX"/bin/
done
