#!/usr/bin/env bash
# install redis
set -eu

version=${DEPENDS_ON_REDIS_VERSION:-2.8.13}

self=$0
name=`basename "$0" .sh`

prefix="$(pwd -P)"/prefix
mkdir -p "$prefix"

# download and extract MongoDB binary distribution for the machine
tarball="redis-${version}.tar.gz"
[ -s "$tarball" ] ||
    curl -C- -RLO "http://download.redis.io/releases/$tarball"
echo "extrating..."
tar xf "$tarball" -C "$prefix"
cd "$prefix"/"${tarball%.tar.gz}"
echo "making..."
make

# place symlinks for commands to $DEPENDS_PREFIX/bin/
echo "copying executables"
mkdir -p "$DEPENDS_PREFIX"/bin
for x in src/*; do
    [ -x "$x" ] || continue
    relsymlink "$x" "$DEPENDS_PREFIX"/bin/
done
