#!/usr/bin/env python

import time
import math
import argparse
import logging
import pickle

from pathlib import Path

import numpy as np
import lightgbm as lgb
import joblib

from cache import SvmLightCache
from config import AttrDict


class Config(AttrDict):
    def __init__(self):
        self.stamp = time.strftime("%Y%m%d.%H%M%S")
        self.log_fmt = '%(asctime)s: %(levelname)s: %(message)s'
        self.log_dir = 'log'
        self.score_dir = 'score'
        self.name = 'default'
        self.cache_name = '.cache'


def prelude(config):
    Path(config.score_dir).mkdir(parents=True, exist_ok=True)
    logging.basicConfig(format=config.log_fmt, level=logging.INFO)
    log_path = Path(config.log_dir)
    log_path.mkdir(parents=True, exist_ok=True)
    fh = logging.FileHandler(log_path /
                             "score-{}-{}.log".format(config.name, config.stamp))
    fh.setLevel(logging.DEBUG)
    fh.setFormatter(logging.Formatter(config.log_fmt))
    logging.getLogger().addHandler(fh)


def main(args):
    config = Config.from_parseargs(args)
    prelude(config)
    logging.info("Start...")
    logging.info(config)
    cache = SvmLightCache(config.cache_name)

    logging.info("Loading data...")
    X, _, qid = cache.load_svmlight_file(args.test, query_id=True)

    model = joblib.load(args.model)
    logging.info(model)
    logging.info("Best iteration {}...".format(model.best_iteration_))
    logging.info("Best score {}...".format(model.best_score_))
    logging.info("Num features {}...".format(model.n_features_))

    result = model.predict(X)

    scorepath = str(Path(args.model).name).replace(".pkl", "")
    scorepath = Path(config.score_dir) / "{}.txt".format(scorepath)
    logging.info("Save scores to {}...".format(scorepath))
    np.savetxt(str(scorepath), result, fmt="%.9f")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("test", default=None)
    parser.add_argument("model", default=None)
    parser.add_argument("--log_dir", default='log')
    parser.add_argument("--score_dir", default='score')
    parser.add_argument("--cache_name", default='.cache')

    main(parser.parse_args())
