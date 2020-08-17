#!/bin/bash

set -e

SPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $SPATH/init

$BIN/hostdocno $INDRI_INDEX_PATH > $SCRATCHD/hostdocno.csv
xz -dcv $AUXDAT/alexa-top-1m/20100623-top-1m.csv.xz > $SCRATCHD/20100623-top-1m.csv

gradle run -p $BASE/src/alexarank \
  --args "$SCRATCHD/20100623-top-1m.csv $SCRATCHD/hostdocno.csv" \
  | grep ^clue > $SCRATCHD/alexarank.txt

zcat $WEBGRAPH_PATH | $BIN/inlink_count $GRAPHPAIRS_PATH > $INLINK
zcat $WEBGRAPH_PATH | $BIN/outlink_count $GRAPHPAIRS_PATH > $OUTLINK
