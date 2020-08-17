#!/bin/bash

set -e

SPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $SPATH/init

QRELS=$1
TMP5=$(mktemp -p .)
TMP20=$(mktemp -p .)
MAXJ=$(awk '{print $4}' $QRELS | sort -nu | tail -1)
($BIN/gdeval.pl -k 5 -j $MAXJ $QRELS $2 | tail -1 > $TMP5)&
($BIN/gdeval.pl -k 20 -j $MAXJ $QRELS $2 | tail -1 > $TMP20)&
wait
echo -n "NDCG_5 "
awk -F, '{printf "%.4f\n", $3}' $TMP5
echo -n "NDCG_20 "
awk -F, '{printf "%.4f\n", $3}' $TMP20
rm $TMP5 $TMP20
$BIN/rbp_eval -d 1000 -HW -f $(echo "scale=2; 1 / $MAXJ" | bc) -p 0.9 $QRELS $2 | awk '{print "RBP_090", $8 $9}'
$BIN/trec_eval -m map_cut.1000 $QRELS $2 | awk '{print "AP", $3}'
