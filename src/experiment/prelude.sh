#!/bin/bash

set -e

SPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $SPATH/init

pushd $SCRATCHD
tar xf $BASE/src/evaluation/lgrz.trec-web-2013.b60280f.tar
tar xf $BASE/src/evaluation/rbp_eval-0.2.tar.gz
tar xf $BASE/src/evaluation/trec_eval-9.0.7.tar.gz
ln -fs $SCRATCHD/lgrz.trec-web-2013.b60280f/src/eval/gdeval.pl $BIN/gdeval.pl
pushd rbp_eval-0.2
./configure && make
ln -fs $SCRATCHD/rbp_eval-0.2/rbp_eval/rbp_eval $BIN/rbp_eval
popd
make -C trec_eval-9.0.7
ln -fs $SCRATCHD/trec_eval-9.0.7/trec_eval $BIN/trec_eval
popd
