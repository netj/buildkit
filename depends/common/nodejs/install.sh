#!/usr/bin/env bash
# install node and npm
set -eu

version=${DEPENDS_ON_NODE_VERSION:-v0.10.26}

self=$0
name=`basename "$0" .sh`

download() {
    local url=$1; shift
    local file=$1; shift
    [ -s "$file" ] || curl -C- -RLO "$url"
    # TODO sha1sum/md5sum/md5/shasum based on url
}

# determine os and arch for downloading
os=$(uname -s)
case $os in
    Darwin) os=darwin ;;
    Linux)  os=linux  ;;
    SunOS)  os=sunos  ;;
    *)
        echo >&2 "$os: Unsupported operating system"
        os=
esac
if [ -z "$os" ]; then
    arch=
else
    arch=$(uname -m)
    case $arch in
        x86_64|amd64)
            arch=x64 ;;
        i686|i386|i86pc)
            arch=x86 ;;
        *)
            echo >&2 "$arch: Unsupported architecture"
            os= arch=
    esac
fi

if [ -n "$os" -a -n "$arch" ]; then
    # download binary distribution
    fullname="node-${version}-${os}-${arch}"
    tarball="${fullname}.tar.gz"
    download "http://nodejs.org/dist/${version}/$tarball" "$tarball"
    mkdir -p prefix
    tar xf "$tarball" -C prefix
else
    # download source and build
    # first, look for the latest version of python
    for python in python2.7 python2.6; do
        ! type $python &>/dev/null || break
        python=
    done
    if [ -z "$python" ]; then
        echo "Python >= 2.6 is required to build nodejs" >&2
        exit 2
    fi
    # download the source
    fullname="node-${version}"
    tarball="${fullname}.tar.gz"
    download "http://nodejs.org/dist/${version}/$tarball" "$tarball"
    tar xf "$tarball"
    cd "./${tarball%.tar.gz}"
    # configure and build
    $python ./configure --prefix="$prefix"
    make -j $(nproc 2>/dev/null) install PORTABLE=1
fi

# place wrappers or symlinks for commands under $DEPENDS_PREFIX/bin/
wrappers-under-depends-prefix-with-libdirs prefix/"$fullname"/lib bin -x prefix/"$fullname"/bin/*
