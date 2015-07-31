#!/usr/bin/env bash
set -eu

branch=${DEPENDS_ON_BATS_VERSION:-v0.4.0}

rm -rf bats
git clone https://github.com/sstephenson/bats.git --branch $branch
cd bats
./install.sh "$DEPENDS_PREFIX"
