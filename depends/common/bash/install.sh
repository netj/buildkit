#!/usr/bin/env bash
# install Bash
set -eu

name=bash
version=4.3
sha256sum=afc687a28e0e24dc21b988fa159ff9dbcf6b7caa92ade8645cc6d5605cd024d4
sha1sum=45ac3c5727e7262334f4dfadecdf601b39434e84
md5sum=81348932d5da294953e15d4814c74dd1
ext=.tar.gz

patchesURL=https://gist.githubusercontent.com/dunn/a8986687991b57eb3b25/raw/76dd864812e821816f4b1c18e3333c8fced3919b/bash-4.3.42.diff
patches_sha256sum=2eeb9b3ed71f1e13292c2212b6b8036bc258c58ec9c82eec7a86a091b05b15d2
patches_sha1sum=982e8ff0cca3c4e92a59336a4eb22cee4a5b4100
patches_md5sum=749f45b46057f18111f0422da34ca0dc

fetch-configure-build-install $name-$version <<END
url=http://ftpmirror.gnu.org/$name/$name-$version$ext
sha1sum=$sha1sum
md5sum=$md5sum
custom-fetch() {
    default-fetch
    # patch after fetching source tree
    patchesName=${patchesURL##*/}
    fetch-verify "\$patchesName" "$patchesURL" \
        sha1sum=$patches_sha1sum md5sum=$patches_md5sum
    cd "$name-$version"
    patch -f -p1 <../"\$patchesName"
}
custom-install() { make install-strip; }
END
