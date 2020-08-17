#!/bin/bash

set -e

SPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $SPATH/init

rm -frv $BUILDP $QRELD $QRYD $BIN

# Fxt index
rm -frv $FXT_INDEX_PATH

# LightGBM creates build files outside of the `build` directory
if [ -d $BASE/src/lightgbm/build ];then
  pushd $BASE/src/lightgbm/build
  make clean
  popd
fi

# Compilation objects
rm -frv $BASE/src/alexarank/build \
  $BASE/src/alexarank/.gradle \
  $BASE/src/cpp-netlib/build \
  $BASE/src/fxt/build \
  $BASE/src/lightgbm/build \
  $BASE/src/hostdocno/hostdocno{,.o}
