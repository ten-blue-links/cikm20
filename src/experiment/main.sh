#!/bin/bash

set -e

SPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $SPATH/init

run() {
  local checkpoint=$BUILDP/.exp.chk.$(basename $1)
  if [ ! -f $checkpoint ]; then
    $1 && touch $checkpoint
  fi
}

run $SPATH/prelude.sh
run $BASE/src/sh/trec-data.sh
run $SPATH/wt09-train.sh
run $SPATH/wt09-test.sh
run $SPATH/wt10-train.sh
run $SPATH/wt10-test.sh
run $SPATH/wt11-train.sh
run $SPATH/wt11-test.sh
run $SPATH/wt12-train.sh
run $SPATH/wt12-test.sh
