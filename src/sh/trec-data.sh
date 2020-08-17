#!/bin/bash

set -e

SPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $SPATH/common

# MQ09 topics (filter out topics that are not judged)
# Some queries in the output contain `+` and `"`
awk '{print $1}' $TRECD/09.prels.mq | sort -nu > $SPATH/tmp.qry
awk -F\: 'FNR == NR {
  map[$1] = 1
  next
}
{
  if (map[$1]) {
    print $0
  }
}' $SPATH/tmp.qry $TRECD/09.mq.topics | sed -e 's/:[[:digit:]]:/;/' -e 's/+/ /g' -e 's/"//g' > $QRYD/09.mq.topics
rm $SPATH/tmp.qry

# Indri query file
indri_qry $QRYD/09.mq.topics
# kstem version (feature extraction tool does not apply stemming)
sed 's/;/ /' $QRYD/09.mq.topics | $BIN/kstem | sed 's/ /;/' > $QRYD/09.mq.topics.kstem

# WT09 topics
sed -e 's/^wt09\-//' -e 's/:/;/' $TRECD/09.wt.topics > $QRYD/09.topics
# Indri query file
indri_qry $QRYD/09.topics
# kstem version (feature extraction tool does not apply stemming)
sed 's/;/ /' $QRYD/09.topics | $BIN/kstem | sed 's/ /;/' > $QRYD/09.topics.kstem

# WT10-WT12 topics
for n in 10 11 12; do
  sed -e 's/:/;/' $TRECD/${n}.wt.topics > $QRYD/${n}.topics
  indri_qry $QRYD/${n}.topics
  sed 's/;/ /' $QRYD/${n}.topics | $BIN/kstem | sed 's/ /;/' > $QRYD/${n}.topics.kstem
done

# MQ09 Training queries >20050
awk '$1 > 20050 {print $1, "0", $2, $3}' $TRECD/09.prels.mq | sed 's/\-[[:digit:]]$/0/' > $QRELD/09.qrels.mq
# WT09 qrels where iprob = 1.
awk '$5 == 1 {print $1, "0", $2, $3}' $TRECD/09.prels.adhoc > $QRELD/09.qrels.adhoc
# Fold negative judgments to 0.
# WT10 qrels
awk '{print $1, $2, $3, $4}' $TRECD/10.qrels.adhoc | sed 's/\-[[:digit:]]$/0/' > $QRELD/10.qrels.adhoc
# WT11 qrels
awk '{print $1, $2, $3, $4}' $TRECD/11.qrels.adhoc | sed 's/\-[[:digit:]]$/0/' > $QRELD/11.qrels.adhoc
# WT12 qrels
awk '{print $1, $2, $3, $4}' $TRECD/12.qrels.adhoc | sed 's/\-[[:digit:]]$/0/' > $QRELD/12.qrels.adhoc
