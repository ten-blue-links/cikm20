# CIKM 2020 Resource Track

> L. Gallagher, A. Mallia, J. S Culpepper, T. Suel, and B. Barla Cambazoglu.
> 2020. Feature Extraction for Large-Scale Text Collections. In Proc. CIKM.
> DOI: https://doi.org/10.1145/3340531.3412773

This repository contains scripts to build the dataset, and replicate the
experiments from the paper _Feature Extraction for Large-Scale Text
Collections_ from the CIKM 2020 Resource Track.

## Download the LTR Dataset

The dataset is available for download at the links below:

* Release 1.0.1 - [cikm20ltr-1.0.1][v1.0.1] (sha1 `cca713f3d331921f4d5d3093832d5f182da79c25`)

[v1.0.1]: https://cloudstor.aarnet.edu.au/plus/s/FsYRqqu8LeQDwZi/download

## Environment Setup

The following environment configuration was used to build the dataset and run
the experiments. We assume you have a working `conda` installation
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

The following details the prerequisites and steps to configure and run the
build scripts.

### Prerequisites

* Indri index of ClueWeb09B ([example config][clueindri])
* ~350GiB RAM
* ~300GiB disk space
* Webgraph data [ClueWeb09_WG_50m.graph-txt.gz][graph] and [ClueB-ID-DOCNO.txt.tar.gz][iddocno]. Once downloaded decompress the `ClueB-ID-DOCNO.txt.tar.gz`:
    - `ClueWeb09B_WG_50m.graph-txt.gz` leave this as is.
    - `ClueB-ID-DOCNO.txt.tar.gz` decompress to `ClueB-ID-DOCNO.txt`.
* The [gradle][gradleversion] build system was used for the AlexaRank data
* GCC 8.x (not tested with Clang)
* Boost (tested with 1.65.1)
* Cmake 3.x

### Configure and Run the Build Process

1. Copy configuration template: `cp config/dataset.dist config/dataset`
2. Edit `config/dataset` and configure the following variables:
    - `INDRI_INDEX_PATH` - path to existing ClueWeb09B Indri index ([example config][clueindri])
    - `FXT_INDEX_PATH` - path where the Fxt index will be created
    - `BOOST_INCLUDE_PATH` - path to Boost headers
    - `BOOST_LIBRARY_PATH` - path to Boost libraries
    - `INDRI_INCLUDE_PATH` - path to Indri headers
    - `INDRI_LIBRARY_PATH` - path to Indri libraries
    - `WEBGRAPH_PATH` - path to `ClueWeb09_WG_50m.graph-txt.gz` (gzipped)
    - `GRAPHPAIRS_PATH` - path to `ClueB-ID-DOCNO.txt` (decompressed)
3. Run `./src/dataset/main.sh` (build may take ~32 hours)
4. Dataset files `build/cikm20ltr`

[clueindri]: config/clueweb09b.xml
[graph]: http://boston.lti.cs.cmu.edu/clueweb09/WebGraph/ClueWeb09_WG_50m.graph-txt.gz
[iddocno]: http://boston.lti.cs.cmu.edu/clueweb09/pagerank/ClueB-ID-DOCNO.txt.tar.gz

### AlexaRank Notes

The snapshot for the AlexaRank data is from [2010][alexarank].
This was the temporally closest working snapshot to Jan-Feb 2009 for
ClueWeb09B.

[alexarank]: https://web.archive.org/web/20100623204449/http://s3.amazonaws.com/alexa-static/top-1m.csv.zip
[guava]: https://github.com/google/guava
[gradleversion]: https://services.gradle.org/distributions/gradle-5.6.3-bin.zip

## Replicate the LTR Experiments

The term _replicate_ is defined as per the [ACM artifacts policy][acmdefs].

[acmdefs]: https://www.acm.org/publications/policies/artifact-review-and-badging-current

1. Copy configuration template: `cp config/experiment.dist config/experiment`
    1. If the dataset files are in a different location than the default
       `build/cikm20ltr` edit `config/experiment` and set `DATASETD` to the
        correct path
2. Run `./src/experiment/main.sh`
3. `cat` the results: `for i in build/result/wt??/test/eval/*.txt; do echo $i; cat $i; done`
4. TREC run files `build/result/wt??/test/run`

### LambdaMART Effectiveness

The experiment scripts should be able to replicate the following results:

| Test Queries                    | RBP 0.9       | NDCG 5 | NDCG 20 | AP    |
|---------------------------------|---------------|--------|---------|-------|
| Web Track 2009 (Topics 1-50)    | 0.286+0.344   | 0.298  | 0.296   | 0.219 |
| Web Track 2010 (Topics 51-100)  | 0.187+0.295   | 0.224  | 0.245   | 0.131 |
| Web Track 2011 (Topics 101-150) | 0.132+0.139   | 0.235  | 0.199   | 0.117 |
| Web Track 2012 (Topics 151-200) | 0.193+0.185   | 0.193  | 0.189   | 0.164 |
