#!/usr/bin/python

import sys
import os
import collections
import json

## Script that modifies the original extracted Log from AOP4Hadoop.
## HDFS events are extracted and modified to build charts.

import time

def main(path,id_exec):
    positions = {}
    total = 0
    with open (path + "/hadoop.log", "r", 1) as f:
        for line in f:
            li = line.split(",")
            if li[3] not in positions:
                positions[li[3]] = 0
            if li[5] not in positions:
                positions[li[5]] = 0
            total += long(li[6])

    count = 0
    for key in positions.keys():
        positions[key] = count
        count += 1

    values = [0] * (len(positions) * len(positions))

    with open (path + "/hadoop.log", "r", 1) as f:
        for line in f:
            print (li[3], li[5], li[6])
            li = line.split(",")
            values[positions[li[3]]*len(positions) + positions[li[5]]] += long(li[6])

    print (values)
    print (total)


    for k in xrange(0,len(values)):
        values[k] = round((float(values[k])/float(total)) * 100, 100)

    fil = open(path + "/inserts.sql","w",1)
    count = 0
    for key1 in positions.keys():
        for key2 in positions.keys():
            insert = "INSERT INTO aloja_logs.AOP_nodes_perf(id_exec,node1,node2,data) VALUES (" + id_exec + \
                "," + '"' + key1 + '"'  + "," + '"' + key2 + '"' + "," + str(values[count]) + ")\n"
            fil.write(insert)
            count += 1


def usage():
    print("Usage: ./changeLog.py pathToLog")

if len(sys.argv) > 3: usage()
elif len(sys.argv) == 3: main(sys.argv[1], sys.argv[2])
else: main()
