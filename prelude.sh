#!/bin/bash

set -ex

SPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() {
    echo $1 1>&2
}

compile() {
  mkdir -p $1
  pushd $1
  cmake ..
  make -j$JOBS VERBOSE=1
  popd
}

# Number of jobs for `make`
JOBS=2
if [ ! -z $1 ]; then
    JOBS=$1
fi

# Compile LightGBM
compile $SPATH/src/lightgbm/build

# Compile Fxt
compile $SPATH/src/fxt/build

# Symlinks
mkdir -p $SPATH/bin
for i in $SPATH/src/fxt/build/bin/*; do
  ln -vfs $i $SPATH/bin/$(basename $i)
done
