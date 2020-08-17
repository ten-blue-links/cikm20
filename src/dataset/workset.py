#!/usr/bin/env python

import argparse
from collections import defaultdict

def main(args):
    qry = {}
    qrel = defaultdict(list)
    with open(args.query) as f:
        for line in f:
            qid, text = line.strip().split(';')
            qry[qid] = text
    with open(args.qrel) as f:
        for line in f:
            qid, _, docno, _ = line.strip().split()
            qrel[qid].append(docno)
    print('<parameters>')
    for qid, text in qry.items():
        print(f'<query><number>{qid}</number><text>{text}</text>')
        for docno in qrel[qid]:
            print(f'<workingSetDocno>{docno}</workingSetDocno>')
        print('</query>')
    print('</parameters>')


if '__main__' == __name__:
    parser = argparse.ArgumentParser()
    parser.add_argument("query", default=None)
    parser.add_argument("qrel", default=None)
    main(parser.parse_args())
