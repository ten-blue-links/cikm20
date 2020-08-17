# CIKM 2020 Resource Track

> L. Gallagher, A. Mallia, J. S Culpepper, T. Suel, and B. Barla Cambazoglu.
> 2020. Feature Extraction for Large-Scale Text Collections. In Proc. CIKM.
> DOI: https://doi.org/10.1145/3340531.3412773

This repository contains scripts to build the dataset, and scripts to
run the experiments from the paper _Feature Extraction for Large-Scale Text
Collections_ from the CIKM 2020 Resource Track.

## Prerequisites for Building the Dataset

* Indri index of ClueWeb09B (example [config provided][clueindri])
* ~350GiB RAM
* ~300GiB disk space
* Webgraph data: [ClueWeb09_WG_50m.graph-txt.gz][graph] and [ClueB-ID-DOCNO.txt.tar.gz][iddocno]
* The [gradle][gradleversion] build system was used for the AlexaRank data
* gcc 8 (not tested with clang)

[clueindri]: config/clueweb09b.xml
[graph]: http://boston.lti.cs.cmu.edu/clueweb09/WebGraph/ClueWeb09_WG_50m.graph-txt.gz
[iddocno]: http://boston.lti.cs.cmu.edu/clueweb09/pagerank/ClueB-ID-DOCNO.txt.tar.gz

## Environment Setup

The following dataset and experiment instructions assume the use of `conda`
(recommended).

Clone this repo and setup Conda environment:

```sh
git clone https://github.com/ten-blue-links/cikm20
cd cikm20
git submodule update --init --recursive --depth 1
conda env create -f env.yml
conda activate cikm20fxt
./src/sh/lgbm.sh
pip install -r requirements.txt
```

## Build the Dataset

1. Copy configuration template: `cp config/dataset.dist config/dataset`
2. Edit `config/dataset`
3. Run `./src/dataset/main.sh`
4. Come back in a day or so...

## Reproduce Experiments

* Run `./src/experiment/main.sh`
* Come back in ~10 minutes...
* `cat` the results: `for i in build/result/wt??/test/eval/*.txt; do echo $i; cat $i; done`

## AlexaRank Data (Notes)

The snapshot for the AlexaRank data is from [2010][alexarank].
This was the temporally closest working snapshot to Jan-Feb 2009 for
ClueWeb09B.

[alexarank]: https://web.archive.org/web/20100623204449/http://s3.amazonaws.com/alexa-static/top-1m.csv.zip
[guava]: https://github.com/google/guava
[gradleversion]: https://services.gradle.org/distributions/gradle-5.6.3-bin.zip
