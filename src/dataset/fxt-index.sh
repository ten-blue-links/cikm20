#!/bin/bash

set -e

SPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $SPATH/init

$BIN/indexer $INDRI_INDEX_PATH $FXT_INDEX_PATH
$BIN/generate_static_doc_features $INDRI_INDEX_PATH $FXT_INDEX_PATH/statdoc
