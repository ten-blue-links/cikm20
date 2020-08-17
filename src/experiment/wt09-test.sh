#!/bin/bash

set -e

SPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $SPATH/init

MODELP="${RESULTD}/wt09/model"

LOGP="${RESULTD}/wt09/test/log"
SCOREP="${RESULTD}/wt09/test/score"
RUNP="${RESULTD}/wt09/test/run"
EVALP="${RESULTD}/wt09/test/eval"
CACHEP="${SCRATCHD}/.cache"
QRELSF=${QRELD}/09.qrels.adhoc

mkdir -p $LOGP $SCOREP $RUNP $EVALP

name=ndcg@10.20.lambdarank.gbdt.lr0.07.le64.colsamp1.0.estop40.maxpos30.mdleaf20.sigmoid1.0
te=$DATASETD/09.test.svm

$SPATH/lgb_evaluate.py \
  --log_dir $LOGP \
  --score_dir $SCOREP \
  --cache_name $CACHEP \
  $te \
  $MODELP/${name}.pkl

$SPATH/score_svm2run.sh $te $SCOREP/${name}.txt > $RUNP/${name}.run
$SPATH/eval.sh $QRELSF $RUNP/${name}.run > $EVALP/${name}.txt
echo $name
cat $EVALP/${name}.txt
