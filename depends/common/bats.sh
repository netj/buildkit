#!/usr/bin/env bash
set -eu

git clone https://github.com/sstephenson/bats.git --branch v0.3.1
cd bats
./install.sh "$DEPENDS_PREFIX"
