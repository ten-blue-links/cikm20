#!/bin/bash

set -e

SPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $SPATH/init

SRCQREL=$SCRATCHD/qrel.txt
CSV=$SCRATCHD/all.stage0.csv
QRELRUN=$SCRATCHD/qrel.bm25.k1-0.9.b-0.4.run
SDM=$AUXDAT/precomp/sdm.run.xz

# Collect all QRELS
#
# QRELS from the Web Tracks
cat $QRELD/{09,10,11,12}.qrels.adhoc > $SRCQREL
# All prels that are not in 09 adhoc. The same judgments are used for both MQ09
# 20001-20050, and WT09 1-50.
cat $TRECD/09.prels.mq | awk '$1 > 20050 {print $1, "0", $2, $3}' >> $SRCQREL

# Get BM25 score for all qrel docs
OKAPI="-baseline=okapi,k1:0.9,b:0.4,k3:0"
awk -F\; '$1 > 20050' $QRYD/09.mq.topics.kstem > $SCRATCHD/all.topics.kstem
cat $QRYD/??.topics.kstem >> $SCRATCHD/all.topics.kstem
$SPATH/workset.py $SCRATCHD/all.topics.kstem $SRCQREL > $SCRATCHD/qrel.indri
IndriRunQuery \
  $OKAPI \
  -index=$INDRI_INDEX_PATH \
  -trecFormat=1 \
  -stemmer.name=krovetz \
  -threads=$INDRI_THREADS \
  $SCRATCHD/qrel.indri > $QRELRUN
# Add relevance labels to the run file to label instances later on
$BASE/src/fxt/script/label.awk $SRCQREL $QRELRUN > $SCRATCHD/qrel.stage0.run

indri_qry $SCRATCHD/all.topics.kstem
OKAPI="-baseline=okapi,k1:0.9,b:0.4,k3:0"
# `count` is required if your working set is greater than the default count of 1000
IndriRunQuery \
  $OKAPI \
  -index=$INDRI_INDEX_PATH \
  -trecFormat=1 \
  -count=2000 \
  -stemmer.name=krovetz \
  -threads=$INDRI_THREADS \
  $SCRATCHD/all.topics.kstem.indri > $SCRATCHD/all.topics.bm25.k1-0.9.b-0.4.run
# Add relevance labels to the run file to label instances later on
$BASE/src/fxt/script/label.awk $SRCQREL $SCRATCHD/all.topics.bm25.k1-0.9.b-0.4.run > $SCRATCHD/bm25.stage0.run

# Remove dupes
awk '{
  if (map[$1 $3]) {
    next
  }
  print $0
  map[$1 $3] = 1
}' $SCRATCHD/qrel.stage0.run $SCRATCHD/bm25.stage0.run > $SCRATCHD/all.stage0.run
# Sorting is required otherwise `extractor` does not work properly
sort -k1n -k5nr $SCRATCHD/all.stage0.run > $SCRATCHD/all.stage0.run.sort

# Check we have enough memory to proceed
MEM=$(free -t -g | grep -i '^mem' | awk '{print $2}')
if ((MEM < 350)); then
  err "Not enough memory, ~350G is required."
fi
$BIN/extractor \
  --indri_index $INDRI_INDEX_PATH \
  --forward_index $FXT_INDEX_PATH/forward_index \
  --inverted_index $FXT_INDEX_PATH/inverted_index \
  --lexicon $FXT_INDEX_PATH/lexicon \
  --static_doc_file $FXT_INDEX_PATH/statdoc \
  -c $CONFIGD/fxt-cw09.ini \
  $SCRATCHD/all.topics.kstem $SCRATCHD/all.stage0.run.sort $CSV

# strip NaN values
sed -Ei 's/,\-?nan/,0.0/g' $CSV

# Append inlink count
awk 'FNR == NR {
  map[$1] = $2
  next
}
{
  FS = ","
  OFS = ","
  d = $3
  inlinks = 0
  if (map[d]) {
    inlinks = map[d]
  }
  print $0, inlinks
}' $INLINK $CSV > $SCRATCHD/inlink.tmp
mv -v $SCRATCHD/inlink.tmp $CSV

# Append outlink count
awk 'FNR == NR {
  map[$1] = $2
  next
}
{
  FS = ","
  OFS = ","
  d = $3
  outlinks = 0
  if (map[d]) {
    outlinks = map[d]
  }
  print $0, outlinks
}' $OUTLINK $CSV > $SCRATCHD/outlink.tmp
mv -v $SCRATCHD/outlink.tmp $CSV

# Append AlexaRank score
awk 'FNR == NR {
  map[$1] = $2
  next
}
{
  FS = ","
  OFS = ","
  d = $3
  alexarank = 0
  if (map[d]) {
    alexarank = map[d]
  }
  print $0, alexarank
}' $ALEXARANK $CSV > $SCRATCHD/alexarank.tmp
mv -v $SCRATCHD/alexarank.tmp $CSV

# Insert pre-computed SDM. This is broken the SDM scores and query-doc pairs
# were mismatched, but it is required to reproduce the results.
cut -d, -f1-24 $CSV > $SCRATCHD/tmp.before
cut -d, -f26- $CSV > $SCRATCHD/tmp.after
xzcat $SDM | awk '{printf "%.5f\n", $5}' > $SCRATCHD/tmp.sdm
paste -d',' $SCRATCHD/tmp.before $SCRATCHD/tmp.sdm > $SCRATCHD/tmp.pack
paste -d',' $SCRATCHD/tmp.pack $SCRATCHD/tmp.after > $SCRATCHD/tmp.pack1
cp $SCRATCHD/tmp.pack1 $CSV

# Collect test sets
awk '$1 > 20050' $SCRATCHD/bm25.stage0.run > $SCRATCHD/09.mq.bm25.run
awk '$1 >= 1 && $1 <= 50' $SCRATCHD/bm25.stage0.run > $SCRATCHD/09.test.bm25.run
awk '$1 >= 51 && $1 <= 100' $SCRATCHD/bm25.stage0.run > $SCRATCHD/10.test.bm25.run
awk '$1 >= 101 && $1 <= 150' $SCRATCHD/bm25.stage0.run > $SCRATCHD/11.test.bm25.run
awk '$1 >= 151 && $1 <= 200' $SCRATCHD/bm25.stage0.run > $SCRATCHD/12.test.bm25.run

# Save query-docno pairs to help with filtering
awk '{print $1 "," $3}' $SCRATCHD/09.mq.bm25.run > $SCRATCHD/tmp.09.mq.key
awk '{print $1 "," $3}' $SCRATCHD/09.test.bm25.run > $SCRATCHD/tmp.09.test.key
awk '{print $1 "," $3}' $SCRATCHD/10.test.bm25.run > $SCRATCHD/tmp.10.test.key
awk '{print $1 "," $3}' $SCRATCHD/11.test.bm25.run > $SCRATCHD/tmp.11.test.key
awk '{print $1 "," $3}' $SCRATCHD/12.test.bm25.run > $SCRATCHD/tmp.12.test.key

# MQ09 is only used for training of WT topics 1-50
awk -F, 'NR == FNR {
map[$1 $2]=1
next
}
{
  if (map[$2 $3]) {
    print $0
  }
}' $SCRATCHD/tmp.09.mq.key $SCRATCHD/all.stage0.csv > $SCRATCHD/09.mq.csv

# WT09 test set
awk -F, 'NR == FNR {
map[$1 $2]=1
next
}
{
  if (map[$2 $3]) {
    print $0
  }
}' $SCRATCHD/tmp.09.test.key $SCRATCHD/all.stage0.csv > $SCRATCHD/09.test.csv

# WT10 test set
awk -F, 'NR == FNR {
map[$1 $2]=1
next
}
{
  if (map[$2 $3]) {
    print $0
  }
}' $SCRATCHD/tmp.10.test.key $SCRATCHD/all.stage0.csv > $SCRATCHD/10.test.csv

# WT11 test set
awk -F, 'NR == FNR {
map[$1 $2]=1
next
}
{
  if (map[$2 $3]) {
    print $0
  }
}' $SCRATCHD/tmp.11.test.key $SCRATCHD/all.stage0.csv > $SCRATCHD/11.test.csv

# WT12 test set
awk -F, 'NR == FNR {
map[$1 $2]=1
next
}
{
  if (map[$2 $3]) {
    print $0
  }
}' $SCRATCHD/tmp.12.test.key $SCRATCHD/all.stage0.csv > $SCRATCHD/12.test.csv

# Collect the training sets
awk '$1 > 20050' $QRELRUN > $SCRATCHD/09.mq.train.qrel.run
awk '$1 >= 1 && $1 <= 50' $QRELRUN > $SCRATCHD/09.wt.train.qrel.run
awk '$1 >= 51 && $1 <= 100' $QRELRUN > $SCRATCHD/10.wt.train.qrel.run
awk '$1 >= 101 && $1 <= 150' $QRELRUN > $SCRATCHD/11.wt.train.qrel.run
awk '$1 >= 151 && $1 <= 200' $QRELRUN > $SCRATCHD/12.wt.train.qrel.run

# Instance key (query-docno pairs) from judgments
awk '{print $1 "," $3}' $SCRATCHD/09.mq.train.qrel.run > $SCRATCHD/tmp.09.mq.train.qrel.key
awk '{print $1 "," $3}' $SCRATCHD/09.wt.train.qrel.run > $SCRATCHD/tmp.09.wt.train.qrel.key
awk '{print $1 "," $3}' $SCRATCHD/10.wt.train.qrel.run > $SCRATCHD/tmp.10.wt.train.qrel.key
awk '{print $1 "," $3}' $SCRATCHD/11.wt.train.qrel.run > $SCRATCHD/tmp.11.wt.train.qrel.key
awk '{print $1 "," $3}' $SCRATCHD/12.wt.train.qrel.run > $SCRATCHD/tmp.12.wt.train.qrel.key

# Instance key (query-docno pairs) from BM25
awk 'NR == FNR {
key = $0
sub(/,/, "", key)
map[key] = 1
next
}
{
  FS=" "
  if (map[$1 $3]) {
    next
  }
  print $1 "," $3
}' $SCRATCHD/tmp.09.mq.train.qrel.key $SCRATCHD/09.mq.bm25.run > $SCRATCHD/tmp.09.mq.train.bm25.key

awk 'NR == FNR {
key = $0
sub(/,/, "", key)
map[key] = 1
next
}
{
  FS=" "
  if (map[$1 $3]) {
    next
  }
  print $1 "," $3
}' $SCRATCHD/tmp.09.wt.train.qrel.key $SCRATCHD/09.test.bm25.run > $SCRATCHD/tmp.09.wt.train.bm25.key

awk 'NR == FNR {
key = $0
sub(/,/, "", key)
map[key] = 1
next
}
{
  FS=" "
  if (map[$1 $3]) {
    next
  }
  print $1 "," $3
}' $SCRATCHD/tmp.10.wt.train.qrel.key $SCRATCHD/10.test.bm25.run > $SCRATCHD/tmp.10.wt.train.bm25.key

awk 'NR == FNR {
key = $0
sub(/,/, "", key)
map[key] = 1
next
}
{
  FS=" "
  if (map[$1 $3]) {
    next
  }
  print $1 "," $3
}' $SCRATCHD/tmp.11.wt.train.qrel.key $SCRATCHD/11.test.bm25.run > $SCRATCHD/tmp.11.wt.train.bm25.key

awk 'NR == FNR {
key = $0
sub(/,/, "", key)
map[key] = 1
next
}
{
  FS=" "
  if (map[$1 $3]) {
    next
  }
  print $1 "," $3
}' $SCRATCHD/tmp.12.wt.train.qrel.key $SCRATCHD/12.test.bm25.run > $SCRATCHD/tmp.12.wt.train.bm25.key

# Make list of training instances to include
cat $SCRATCHD/tmp.09.mq.train.bm25.key $SCRATCHD/tmp.09.mq.train.qrel.key > $SCRATCHD/tmp.09.mq.train.sample.key
cat $SCRATCHD/tmp.09.wt.train.bm25.key $SCRATCHD/tmp.09.wt.train.qrel.key > $SCRATCHD/tmp.09.wt.train.sample.key
cat $SCRATCHD/tmp.10.wt.train.bm25.key $SCRATCHD/tmp.10.wt.train.qrel.key > $SCRATCHD/tmp.10.wt.train.sample.key
cat $SCRATCHD/tmp.11.wt.train.bm25.key $SCRATCHD/tmp.11.wt.train.qrel.key > $SCRATCHD/tmp.11.wt.train.sample.key
cat $SCRATCHD/tmp.12.wt.train.bm25.key $SCRATCHD/tmp.12.wt.train.qrel.key > $SCRATCHD/tmp.12.wt.train.sample.key

# Make seperate CSV files of the combined qrel and bm25 instance keys
awk -F, 'NR == FNR {
map[$1 $2]=1
next
}
{
  if (map[$2 $3]) {
    print $0
  }
}' $SCRATCHD/tmp.09.mq.train.sample.key $SCRATCHD/all.stage0.csv > $SCRATCHD/09.mq.csv

awk -F, 'NR == FNR {
map[$1 $2]=1
next
}
{
  if (map[$2 $3]) {
    print $0
  }
}' $SCRATCHD/tmp.09.wt.train.sample.key $SCRATCHD/all.stage0.csv > $SCRATCHD/09.wt.csv

awk -F, 'NR == FNR {
map[$1 $2]=1
next
}
{
  if (map[$2 $3]) {
    print $0
  }
}' $SCRATCHD/tmp.10.wt.train.sample.key $SCRATCHD/all.stage0.csv > $SCRATCHD/10.wt.csv

awk -F, 'NR == FNR {
map[$1 $2]=1
next
}
{
  if (map[$2 $3]) {
    print $0
  }
}' $SCRATCHD/tmp.11.wt.train.sample.key $SCRATCHD/all.stage0.csv > $SCRATCHD/11.wt.csv

awk -F, 'NR == FNR {
map[$1 $2]=1
next
}
{
  if (map[$2 $3]) {
    print $0
  }
}' $SCRATCHD/tmp.12.wt.train.sample.key $SCRATCHD/all.stage0.csv > $SCRATCHD/12.wt.csv

# Collect training queries for each year
cat $SCRATCHD/09.mq.csv > $TRAIND/09.train.csv
cat $SCRATCHD/{09,11,12}.wt.csv > $TRAIND/10.train.csv
# Remove topic 70 from training
cat $SCRATCHD/{09,10,12}.wt.csv | sed '/^.,70,/d' > $TRAIND/11.train.csv
cat $SCRATCHD/{09,10,11}.wt.csv | sed '/^.,70,/d' > $TRAIND/12.train.csv

mkdir -p $SCRATCHD/split.{09,10,11,12}
awk -F, -v path="$SCRATCHD/split.09/" '{print $0 > path $2}' $TRAIND/09.train.csv
awk -F, -v path="$SCRATCHD/split.10/" '{print $0 > path $2}' $TRAIND/10.train.csv
awk -F, -v path="$SCRATCHD/split.11/" '{print $0 > path $2}' $TRAIND/11.train.csv
awk -F, -v path="$SCRATCHD/split.12/" '{print $0 > path $2}' $TRAIND/12.train.csv

ls -1 $SCRATCHD/split.09 | shuf --random-source=$AUXDAT/seed.bin > $SCRATCHD/shuf.09
ls -1 $SCRATCHD/split.10 | shuf --random-source=$AUXDAT/seed.bin > $SCRATCHD/shuf.10
ls -1 $SCRATCHD/split.11 | shuf --random-source=$AUXDAT/seed.bin > $SCRATCHD/shuf.11
ls -1 $SCRATCHD/split.12 | shuf --random-source=$AUXDAT/seed.bin > $SCRATCHD/shuf.12

# Make train / val sets
split -d -l 572 $SCRATCHD/shuf.09
mv x00 $TRVALD/qid.09.train
mv x01 $TRVALD/qid.09.val
>$TRVALD/09.train.csv
for i in $(cat $TRVALD/qid.09.train); do
  cat $SCRATCHD/split.09/$i >> $TRVALD/09.train.csv
done
>$TRVALD/09.val.csv
for i in $(cat $TRVALD/qid.09.val); do
  cat $SCRATCHD/split.09/$i >> $TRVALD/09.val.csv
done

split -d -l 120 $SCRATCHD/shuf.10
mv x00 $TRVALD/qid.10.train
mv x01 $TRVALD/qid.10.val
>$TRVALD/10.train.csv
for i in $(cat $TRVALD/qid.10.train); do
  cat $SCRATCHD/split.10/$i >> $TRVALD/10.train.csv
done
>$TRVALD/10.val.csv
for i in $(cat $TRVALD/qid.10.val); do
  cat $SCRATCHD/split.10/$i >> $TRVALD/10.val.csv
done

split -d -l 120 $SCRATCHD/shuf.11
mv x00 $TRVALD/qid.11.train
mv x01 $TRVALD/qid.11.val
>$TRVALD/11.train.csv
for i in $(cat $TRVALD/qid.11.train); do
  cat $SCRATCHD/split.11/$i >> $TRVALD/11.train.csv
done
>$TRVALD/11.val.csv
for i in $(cat $TRVALD/qid.11.val); do
  cat $SCRATCHD/split.11/$i >> $TRVALD/11.val.csv
done

split -d -l 120 $SCRATCHD/shuf.12
mv x00 $TRVALD/qid.12.train
mv x01 $TRVALD/qid.12.val
>$TRVALD/12.train.csv
for i in $(cat $TRVALD/qid.12.train); do
  cat $SCRATCHD/split.12/$i >> $TRVALD/12.train.csv
done
>$TRVALD/12.val.csv
for i in $(cat $TRVALD/qid.12.val); do
  cat $SCRATCHD/split.12/$i >> $TRVALD/12.val.csv
done

# SVM files
$BASE/src/fxt/script/csv2svm.awk $TRVALD/09.train.csv > $TRVALD/09.train.svm
$BASE/src/fxt/script/csv2svm.awk $TRVALD/09.val.csv > $TRVALD/09.val.svm
$BASE/src/fxt/script/csv2svm.awk $TRVALD/10.train.csv > $TRVALD/10.train.svm
$BASE/src/fxt/script/csv2svm.awk $TRVALD/10.val.csv > $TRVALD/10.val.svm
$BASE/src/fxt/script/csv2svm.awk $TRVALD/11.train.csv > $TRVALD/11.train.svm
$BASE/src/fxt/script/csv2svm.awk $TRVALD/11.val.csv > $TRVALD/11.val.svm
$BASE/src/fxt/script/csv2svm.awk $TRVALD/12.train.csv > $TRVALD/12.train.svm
$BASE/src/fxt/script/csv2svm.awk $TRVALD/12.val.csv > $TRVALD/12.val.svm
$BASE/src/fxt/script/csv2svm.awk $SCRATCHD/09.test.csv > $TRVALD/09.test.svm
$BASE/src/fxt/script/csv2svm.awk $SCRATCHD/10.test.csv > $TRVALD/10.test.svm
$BASE/src/fxt/script/csv2svm.awk $SCRATCHD/11.test.csv > $TRVALD/11.test.svm
$BASE/src/fxt/script/csv2svm.awk $SCRATCHD/12.test.csv > $TRVALD/12.test.svm

# Valid qrels
awk '{print $2, "0", $NF, $1}' $TRVALD/09.val.svm \
  | sed -e 's/qid://' -e 's/docno://' > $TRVALD/09.val.qrel
awk '{print $2, "0", $NF, $1}' $TRVALD/10.val.svm \
  | sed -e 's/qid://' -e 's/docno://' > $TRVALD/10.val.qrel
awk '{print $2, "0", $NF, $1}' $TRVALD/11.val.svm \
  | sed -e 's/qid://' -e 's/docno://' > $TRVALD/11.val.qrel
awk '{print $2, "0", $NF, $1}' $TRVALD/12.val.svm \
  | sed -e 's/qid://' -e 's/docno://' > $TRVALD/12.val.qrel

mv $TRVALD/*.{svm,qrel} $DATASETD
