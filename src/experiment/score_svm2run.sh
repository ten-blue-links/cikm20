#!/usr/bin/env bash

set -e

svmfile=$1
scores=$2

if [ $# -ne 2 ]; then
  echo "usage: score2run.sh <svmfile> <scorefile>" 1>&2
  exit 1
fi

paste -d' ' $scores $svmfile | awk '{print $3, "Q0", $NF, 0, $1, "foo"}' | sed -e 's/qid://' -e 's/docno://'
