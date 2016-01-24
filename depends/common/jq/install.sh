#!/usr/bin/env bash
# install jq
# See: http://stedolan.github.io/jq/download/
set -eu

version=1.5

self=$0
name=`basename "$0" .sh`

fullname=jq-${version}

# download prebuilt executable
case $(uname) in
    Linux)
        fetch-verify jq \
            https://github.com/stedolan/jq/releases/download/$fullname/jq-linux64 \
            sha1sum=d8e36831c3c94bb58be34dd544f44a6c6cb88568 \
            md5sum=6a342dbb17b2f2ea4ec0e64d2157614d \
            #
        ;;

    Darwin)
        fetch-verify jq \
            https://github.com/stedolan/jq/releases/download/$fullname/jq-osx-amd64 \
            sha1sum=51ed5abdd7dfe778850c9d86521c53fe23ee89f1 \
            md5sum=81ff0e3ddd999d2f5bd151b882ce7e18 \
            #
        ;;

    *)
        echo >&2 "$(uname): prebuilt jq executable not available"
        # TODO build from source
        false
esac

# install it to the usual place
chmod +x jq
mkdir -p prefix/"$fullname"/bin
install jq prefix/"$fullname"/bin/

# place symlinks for commands under $DEPENDS_PREFIX/bin/
symlink-under-depends-prefix bin -x prefix/"$fullname"/bin/*
