#!/usr/bin/env bash
set -eu

rm -rf bats
git clone https://github.com/sstephenson/bats.git --branch v0.3.1
cd bats
./install.sh "$DEPENDS_PREFIX"
