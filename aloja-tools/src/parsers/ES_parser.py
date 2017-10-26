#!/usr/bin/env python

import sys,os
import argparse
import re
import time
import datetime
import glob
import pprint
import csv
import random
import pprint
import json

def get_pattern():
    return re.compile("(?:startTime"
                      "|numberOfNodes"
                      "|defaultProvider"
                      "|clusterName"
                      "|JOB_NAME"
                      "|BENCH_DATA_SIZE"
                      "|EXEC_END"
                      "|EXEC_START"
                      "|EXEC_TIME"
                      "|EXEC_STATUS"
                      "|BENCH_LIST"
                      "|BENCH_SUITE"
                      "|HIVE_ML_FRAMEWORK"
                      "|(?<![a-zA-Z]_)+ENGINE)"
                      "=.+")

def parse_job_variables(path):
    config = os.path.join(path, "config.sh")
    options_dic={}
    if (os.path.isfile(config)):
        config_file = open(config,'r').read()
        options = get_pattern().findall(config_file)
        for option in options:
            splitted=option.split('=')
            if (len(splitted) > 2):
                options_dic[splitted[0]]={}
                for sub_bench in re.findall('\[.+?\]="[^"]*"',option):
                    sub_bench_splitted=sub_bench.split('=')
                    options_dic[splitted[0]][sub_bench_splitted[0].strip('[').strip(']')] = sub_bench_splitted[1].strip('"')
            else: options_dic[splitted[0]] = splitted[1].strip("'")
    return options_dic

def create_test_JSON(variables,bench):
    test_JSON={}
    test_index={}
    test_JSON["experimentID"]=variables["JOB_NAME"]
    test_index["index"]={}
    test_index["index"]["_index"]="tests"
    test_index["index"]["_type"]="aloja"

    for key in variables["EXEC_END"].keys():
        regex="(^" + re.escape(bench) + ")|(-" + re.escape(bench) + "$)"
        if re.findall(regex,str(key),re.IGNORECASE):
            test_JSON["name"]=key
            test_JSON["startTime"]=int(variables["EXEC_START"][key])
            test_JSON["endTime"]=int(variables["EXEC_END"][key])
            test_JSON["execTime"]=int(test_JSON["endTime"]) - int(test_JSON["startTime"])
            if (variables["EXEC_STATUS"][key] == "0 0"):
                test_JSON["execStatus"]="SUCCESS"
            else:
                test_JSON["execStatus"]="FAILED"

    return test_index,test_JSON

def create_experiment_JSON(variables,benchmark,execSatus):
    experiment_JSON={}
    experiment_index={}
    experiment_index["index"]={}
    experiment_index["index"]["_id"]=variables["JOB_NAME"]
    experiment_index["index"]["_index"]="experiments"
    experiment_index["index"]["_type"]="aloja"
    experiment_JSON["bencmarkSuite"]=benchmark
    experiment_JSON["benchList"]=variables["BENCH_LIST"]
    experiment_JSON["execStatus"]=execSatus
    experiment_JSON["status"]="finished"
    experiment_JSON["dataSize"]=variables["BENCH_DATA_SIZE"]
    experiment_JSON["provider"]=variables["defaultProvider"]
    experiment_JSON["clusterName"]=variables["clusterName"]
    experiment_JSON["numberOfNodes"]=variables["numberOfNodes"]

    end_time=0
    start_time=sys.maxint
    for key,value in variables["EXEC_END"].iteritems():
        if (int(value) > end_time): end_time = int(value)

    for key,value in variables["EXEC_START"].iteritems():
        if (int(value) < start_time):
            start_time = int(value)

    experiment_JSON["startTime"]=start_time
    experiment_JSON["endTime"]=end_time
    experiment_JSON["execTime"]=end_time - start_time

    if (benchmark == "BigBench" or "D2F" in benchmark):
        experiment_JSON["engine"]=variables["ENGINE"]
        experiment_JSON["MLFramework"]=variables["HIVE_ML_FRAMEWORK"]

    return experiment_index, experiment_JSON

def concatenate_JSON_string(index,body):
    return (json.dumps(index) + '\n' + json.dumps(body)+ '\n')


def dumb_JSON(index,body,name,job_name):
    path=os.path.join('./',job_name)
    if (not os.path.exists(path)): os.makedirs(path)
    with open(path + '/' + name + '.json', 'w') as dumb_file:
        json.dump(index,dumb_file)
        dumb_file.write('\n')
        json.dump(body,dumb_file)
        dumb_file.write('\n')

def parse_benchmark(job_path,to_string):
    string=" "
    variables = parse_job_variables(job_path)
    experiment_success="SUCCESS"

    for bench in variables["EXEC_END"].keys():
        test_index, test_JSON=create_test_JSON(variables,bench)
        if (test_JSON["execStatus"] == "FAILED"): experiment_success="FAILED"
        if (not to_string): dumb_JSON(test_index,test_JSON,bench,variables["JOB_NAME"])
        else: string+=concatenate_JSON_string(test_index, test_JSON)

    experiment_index, experiment_JSON = create_experiment_JSON(variables,variables["BENCH_SUITE"],experiment_success)
    if (not to_string): dumb_JSON(experiment_index, experiment_JSON,variables["BENCH_SUITE"],variables["JOB_NAME"])
    else: string += concatenate_JSON_string(experiment_index, experiment_JSON)

    return string

def is_boolean(bool):
    if (bool == "True"):
        return True
    elif (bool == "False"):
        return False
    else:
        msg = "%r is not [True|False]" %bool
        raise argparse.ArgumentTypeError(msg)


def main(argc, argv):
    parser = argparse.ArgumentParser(description='parse log files of a benchmark')
    parser.add_argument('path', help='Path to the benchmark')
    parser.add_argument('--string', type=is_boolean, help='Return a string with the experiment and tests in JSON format',default="True")
    args = parser.parse_args()## show values ##

    print(parse_benchmark(os.path.abspath(args.path),args.string))

    sys.exit()

if __name__ == "__main__":
    exit(main(len(sys.argv), sys.argv))