#!/bin/bash

set -e

SPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $SPATH/init

run() {
  local checkpoint=$BUILDP/.chk.$(basename $1)
  if [ ! -f $checkpoint ]; then
    $1 && touch $checkpoint
  fi
}

run $SPATH/prelude.sh
run $BASE/src/sh/trec-data.sh
run $SPATH/fxt-index.sh
run $SPATH/linkstats.sh
run $SPATH/fxt-extract.sh
