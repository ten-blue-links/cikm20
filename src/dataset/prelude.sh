#!/bin/bash

set -e

SPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $SPATH/init

# Number of jobs for `make`
JOBS=2
if [ ! -z $1 ]; then
  JOBS=$1
fi

# Local `make` variables for `hostdocno`
>$BASE/local.mk
echo "BOOST_INCLUDE_PATH = $BOOST_INCLUDE_PATH" >> $BASE/local.mk
echo "BOOST_LIBRARY_PATH = $BOOST_LIBRARY_PATH" >> $BASE/local.mk
echo "INDRI_INCLUDE_PATH = $INDRI_INCLUDE_PATH" >> $BASE/local.mk
echo "INDRI_LIBRARY_PATH = $INDRI_LIBRARY_PATH" >> $BASE/local.mk

# Compile Fxt
compile $BASE/src/fxt/build

# Compile cpp-netlib
compile $BASE/src/cpp-netlib/build \
  "-DCPP-NETLIB_BUILD_TESTS=OFF" \
  "-DCPP-NETLIB_BUILD_EXAMPLES=OFF" \
  "-DBoost_NO_SYSTEM_PATHS=True" \
  "-DBoost_NO_BOOST_CMAKE=True" \
  "-DBoost_INCLUDE_DIR=$BOOST_INCLUDE_PATH" \
  "-DBoost_LIBRARY_DIR=$BOOST_LIBRARY_PATH"

# Compile hostdocno
make -C $BASE/src/hostdocno

# Symlinks
for i in $BASE/src/fxt/build/bin/*; do
  ln -vfs $i $BIN/$(basename $i)
done
ln -fs $BASE/src/hostdocno/hostdocno $BIN/hostdocno
