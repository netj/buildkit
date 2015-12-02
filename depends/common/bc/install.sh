#!/usr/bin/env bash
set -eu

name=bc
version=1.06
sha1sum=c8f258a7355b40a485007c40865480349c157292
md5sum=d44b5dddebd8a7a7309aea6c36fda117
ext=.tar.gz

fetch-configure-build-install $name-$version <<END
url=http://ftpmirror.gnu.org/$name/$name-$version$ext
sha1sum=$sha1sum
md5sum=$md5sum
custom-install() { make install-exec; }
END
