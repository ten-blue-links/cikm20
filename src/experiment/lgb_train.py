#!/usr/bin/env python

import ast
import time
import math
import argparse
import logging
import pickle

from pathlib import Path

import numpy as np
import lightgbm as lgb
import joblib

from sklearn import preprocessing
from cache import SvmLightCache
from config import AttrDict
from util import group_counts

class Config(AttrDict):
    def __init__(self):
        self.stamp = time.strftime("%Y%m%d.%H%M%S")
        self.log_fmt = '%(asctime)s: %(levelname)s: %(message)s'
        self.name = 'default-name'
        self.log_dir = 'log'
        self.model_dir = 'model'
        self.boosting_type = 'gbdt'
        self.trees = 100
        self.leaves = 31
        self.learning_rate = 0.05
        self.colsample_bytree = 1.0
        self.early_stopping_rounds = None
        self.max_position = 20
        self.subsample_for_bin = 200000
        self.min_data_in_leaf = 20
        self.min_sum_hessian_in_leaf = 1e-3
        self.sigmoid = 1.0
        self.silent = False
        self.eval_metric = ''
        self.eval_at = '[1,2,3,4,5]'
        self.cache_name = '.cache'
        self.subsample = 1.0
        self.subsample_freq = 0
        self.objective = 'lambdarank'
        self.normalize = None

    @classmethod
    def from_parseargs(cls, args):
        config = cls()
        config.merge_parseargs(args)

        config.eval_at = ast.literal_eval(config.eval_at)
        assert type(config.eval_at) == list

        return config

    @classmethod
    def from_config(cls, other):
        config = cls()
        for key, val in other.items():
            setattr(config, key, val)

        return config

    def merge_parseargs(self, args):
        for key, val in vars(args).items():
            # this class is a `dict` so use `in` instead of `hasattr`
            if key in self.keys() and val is not None:
                setattr(self, key, val)


def prelude(config):
    Path(config.model_dir).mkdir(parents=True, exist_ok=True)
    logging.basicConfig(format=config.log_fmt, level=logging.INFO)
    log_path = Path(config.log_dir)
    log_path.mkdir(parents=True, exist_ok=True)
    fh = logging.FileHandler(log_path /
                             "{}-{}.log".format(config.name, config.stamp))
    fh.setLevel(logging.DEBUG)
    fh.setFormatter(logging.Formatter(config.log_fmt))
    logging.getLogger().addHandler(fh)


def get_scaler(scale_str):
    if scale_str == 'std':
        # can't be used on sparse data
        cls = preprocessing.StandardScaler
    elif scale_str == 'maxabs':
        cls = preprocessing.MaxAbsScaler
    elif scale_str == 'minmax':
        cls = preprocessing.MinMaxScaler
    elif scale_str == 'robust':
        # can't be used on sparse data
        cls = preprocessing.RobustScaler
    else:
        raise ValueError(f"`scale_str = {scale_str}` but must be one of std|maxabs|minmax|robust")
    return cls()


def normalize(scaler, arr, is_train=False):
    """Apply feature normalization to the training set, and apply the same
       normalization to the validation set.
    """
    if is_train:
        arr = scaler.fit_transform(arr)
    else:
        arr = scaler.transform(arr)

def main(args):
    config = Config.from_parseargs(args)
    prelude(config)
    logging.info("Start...")
    logging.info(config)
    cache = SvmLightCache(config.cache_name)

    logging.info("Loading data...")
    X, y, qid = cache.load_svmlight_file(args.train, query_id=True)
    X_val, y_val, qid_val = cache.load_svmlight_file(args.valid, query_id=True)

    scaler = None
    if config.normalize:
        scaler = get_scaler(config.normalize)
        normalize(scaler, X, is_train=True)
        normalize(scaler, X_val, is_train=False)

    model = lgb.LGBMRanker(objective=config.objective,
                           boosting_type=config.boosting_type,
                           n_estimators=config.trees,
                           num_leaves=config.leaves,
                           learning_rate=config.learning_rate,
                           colsample_bytree=config.colsample_bytree,
                           max_position=config.max_position,
                           subsample_for_bin=config.subsample_for_bin,
                           min_data_in_leaf=config.min_data_in_leaf,
                           min_sum_hessian_in_leaf=config.min_sum_hessian_in_leaf,
                           sigmoid=config.sigmoid,
                           subsample=config.subsample,
                           subsample_freq=config.subsample_freq,
                           lambda_l1=0.,
                           lambda_l2=0.,
                           lambdamart_norm=False,
                           max_depth=-1,
                           n_jobs=44,
                           silent=config.silent)
    logging.info(model)
    record_evals = {}
    record_cb = lgb.record_evaluation(record_evals)
    model.fit(X,
              y,
              group=group_counts(qid),
              eval_names=['train', 'valid'],
              eval_set=[(X, y), (X_val, y_val)],
              eval_group=[group_counts(qid), group_counts(qid_val)],
              eval_metric=config.eval_metric,
              eval_at=config.eval_at,
              early_stopping_rounds=config.early_stopping_rounds,
              callbacks=[record_cb])
    model._scaler = scaler
    model._record_evals = record_evals
    logging.info("Best iteration {}...".format(model.best_iteration_))
    logging.info("Best score {}...".format(model.best_score_))
    logging.info("Num features {}...".format(model.n_features_))
    modelpath = Path(config.model_dir) / "{}.pkl".format(config.name)
    logging.info("Save model to {}...".format(modelpath))
    joblib.dump(model, modelpath)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("train", default=None)
    parser.add_argument("valid", default=None)
    parser.add_argument("--name", default='default')
    parser.add_argument("--log_dir", default='log')
    parser.add_argument("--model_dir", default='model')
    parser.add_argument("--boosting_type", default='gbdt')
    parser.add_argument("--trees", default=100, type=int)
    parser.add_argument("--leaves", default=31, type=int)
    parser.add_argument("--learning_rate", default=0.05, type=float)
    parser.add_argument("--colsample_bytree", default=1.0, type=float)
    parser.add_argument("--early_stopping_rounds", default=None, type=int)
    parser.add_argument("--max_position", default=20, type=int)
    parser.add_argument("--subsample_for_bin", default=200000, type=int)
    parser.add_argument("--min_data_in_leaf", default=20, type=int)
    parser.add_argument("--min_sum_hessian_in_leaf", default=1e-3, type=float)
    parser.add_argument("--sigmoid", default=1.0, type=float)
    parser.add_argument("--silent", action='store_true')
    parser.add_argument("--eval_metric", default='')
    parser.add_argument("--eval_at", default='[1,2,3,4,5]')
    parser.add_argument("--cache_name", default='.cache')
    parser.add_argument("--subsample", default=1.0, type=float)
    parser.add_argument("--subsample_freq", default=0, type=int)
    parser.add_argument("--objective", default='lambdarank')
    parser.add_argument("--normalize", default=None)

    main(parser.parse_args())
