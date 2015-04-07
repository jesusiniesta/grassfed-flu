#!/usr/bin/env python3
# encoding: utf-8

import json
import sys
from os import listdir
from os.path import isfile, join
import re

if len(sys.argv) != 2:
    print("tell me the dir containing the json file, please (be aware i will swallow every .json i find in there")
    exit()

inputdir = sys.argv[1]
#json_file_re = re.compile("^tweets.*\.json$")
json_file_re = re.compile("^.*\.json$")

# real: onlyfiles = [ join(inputdir,f) for f in listdir(inputdir) if (isfile(join(inputdir,f)) and json_file_re.match(f)) ]
onlyfiles = [ join(inputdir,f) for f in ["./example.json"] if (isfile(join(inputdir,f)) and json_file_re.match(f)) ]

def reformat (s):
    return s.replace('":true','":True').replace('":false','":False').replace('":null','":None')

def layout (t):
    # 'wtf1'| 'wtf2'| 'wtf3'|  'latitude' 'longitude' | 'username' | 'userid' | 'datetime' | 'msg'
    l = []
    l.append(str('0'))
    l.append(str('0'))
    l.append(str('0'))
    if not 'coordinates' in t: print("no coordinates")
    if not 'geo' in t: print("no geo")

    l.append(str(str(t["coordinates"]["coordinates"][1])+" "+str(t["coordinates"]["coordinates"][0])))
    l.append(str(t["user"]["screen_name"]))
    l.append(str(t["user"]["id"]))
    l.append(str(t["created_at"]))
    # l.append(str(t["text"]))
    l.append("LOL")
    return " | ".join(l)

for fn in onlyfiles:
    print(fn)

    for tweet in [eval(reformat(line)) for line in open(fn)]:
        print(layout(tweet))
