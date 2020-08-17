import logging
from pathlib import Path

import sklearn.datasets
import joblib

class SvmLightCache:
    def __init__(self, basedir='.cache'):
        if not basedir:
            raise ValueError('`basedir` is empty')
        location = str(Path(__file__).resolve().parent.parent / basedir)
        mem = joblib.Memory(location=location, verbose=logging.DEBUG)
        self.load_svmlight_file = mem.cache(sklearn.datasets.load_svmlight_file)
