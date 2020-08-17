#!/bin/bash

set -e

SPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $SPATH/init

MODELP="${RESULTD}/wt10/model"

LOGP="${RESULTD}/wt10/log"
SCOREP="${RESULTD}/wt10/score"
RUNP="${RESULTD}/wt10/run"
EVALP="${RESULTD}/wt10/eval"
CACHEP="${SCRATCHD}/.cache"
QRELSF=${DATASETD}/10.val.qrel

mkdir -p $LOGP $MODELP $SCOREP $RUNP $EVALP

tr=$DATASETD/10.train.svm
v=$DATASETD/10.val.svm

objective="lambdarank"
boosting_type="gbdt"
learning_rate="0.1"
trees="2000"
leaves="16"
estop=40
colsample_bytree="1.0"
max_position="30"
subsample_for_bin="200000"
min_data_in_leaf="100"
sigmoid="1.0"

name="ndcg@10.20.${objective}.${boosting_type}.lr${learning_rate}.le${leaves}.colsamp${colsample_bytree}.estop${estop}.maxpos${max_position}.mdleaf${min_data_in_leaf}.sigmoid${sigmoid}"

$SPATH/lgb_train.py \
  --log_dir $LOGP \
  --model_dir $MODELP \
  --cache_name $CACHEP \
  --name $name \
  --objective $objective \
  --boosting_type $boosting_type \
  --learning_rate $learning_rate \
  --trees $trees \
  --leaves $leaves \
  --colsample_bytree $colsample_bytree \
  --early_stopping_rounds $estop \
  --max_position $max_position \
  --subsample_for_bin $subsample_for_bin \
  --min_data_in_leaf $min_data_in_leaf \
  --sigmoid $sigmoid \
  --eval_metric 'ndcg' \
  --eval_at '[5,10,20,50]' \
  $tr $v

$SPATH/lgb_evaluate.py \
  --log_dir $LOGP \
  --score_dir $SCOREP \
  --cache_name $CACHEP \
  $v \
  $MODELP/${name}.pkl

$SPATH/score_svm2run.sh $v $SCOREP/${name}.txt > $RUNP/${name}.run
$SPATH/eval.sh $QRELSF $RUNP/${name}.run > $EVALP/${name}.txt
echo $name
cat $EVALP/${name}.txt
