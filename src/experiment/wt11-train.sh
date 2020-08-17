#!/bin/bash

set -e

SPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $SPATH/init

MODELP="${RESULTD}/wt11/model"

LOGP="${RESULTD}/wt11/log"
SCOREP="${RESULTD}/wt11/score"
RUNP="${RESULTD}/wt11/run"
EVALP="${RESULTD}/wt11/eval"
CACHEP="${SCRATCHD}/.cache"
QRELSF=${DATASETD}/11.val.qrel

mkdir -p $LOGP $MODELP $SCOREP $RUNP $EVALP

tr=$DATASETD/11.train.svm
v=$DATASETD/11.val.svm

objective="lambdarank"
boosting_type="gbdt"
learning_rate="0.08"
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
