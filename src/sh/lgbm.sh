#!/bin/bash

set -e

SPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $SPATH/common

# Compile LightGBM
compile $BASE/src/lightgbm/build
