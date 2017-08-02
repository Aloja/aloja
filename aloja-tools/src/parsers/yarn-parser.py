#!/usr/bin/env python

import sys,os
import argparse
import re
import time
import datetime
import glob
import pprint
import csv

def get_id(line,type):
    for word in line.split():
        if (type == "application" and "application" in word):
            return word
        elif (type == "container" and "container_" in word):
            return word

def get_times(dict,division=1):

    start = sys.maxint
    stop = 0
    for key,value in dict.iteritems():
        if (value["start_time"] < start): start = value["start_time"]
        if (value["stop_time"] > stop) : stop = value["stop_time"]

    duration = float(stop) - float(start)
    steps = duration/division
    times = []
    for i in xrange (0, int(steps) + 2):
        times.append(start + (i*division))

    return times,start,stop,duration

def get_states(dict):

    states = ["timestamp","RUNNING"]
    for key,value in dict.iteritems():
        for key2 in value.keys():
            if (key2 not in states and key2 != "stop_time" and key2 != "start_time"): states.append(key2)

    return states

def check_timestamp(stop_time,start_time,timestamp,division):

    if (stop_time >= timestamp and stop_time <= (timestamp + division)): return True
    elif (start_time >= timestamp and start_time <= (timestamp + division)): return True
    elif (start_time <= timestamp and stop_time >= (timestamp + division)): return True
    else: return False

def get_app_resources(app_id,containers,time,division):

    total_mem = 0
    total_cores = 0

    for key,value in containers.iteritems():
        if (app_id in key):
            for key2,value2 in value.iteritems():
                if (key2 == "RUNNING"):
                    for k in xrange(0,len(value2)):

                        if (check_timestamp(value2[k]["stop_state"],value2[k]["start_state"],time,division)):
                            if ("cores" in value):
                                total_cores += value["cores"]
                                total_mem += value["memory"]

    return total_cores,total_mem


def update_dict(dict,id,states,new_state,timestamp):

    if (timestamp not in dict):
        dict[timestamp] = {}

    for state in states:
        if (state not in dict[timestamp]): dict[timestamp][state] = []
        elif (id in dict[timestamp][state]):
            dict[timestamp][state].remove(id)

    if (id not in dict[timestamp][new_state]): dict[timestamp][new_state].append(id)

def build_csv (dict,name,save_path,stats,start_time,stop_time,division=1):
    if (not os.path.exists(save_path)):
        os.makedirs(save_path)

    file = open (save_path + '/' + name+'.csv','wb')
    stats = ["timestamp"] + stats
    writer = csv.DictWriter(file,delimiter=',',fieldnames=stats)
    writer.writeheader()

    dict_status = {}
    row = {}
    for stat in stats:
        dict_status[stat] = []

    for t in range (int(start_time),int(stop_time)):

        if t in dict:
            for key,value in dict[t].iteritems():
                for k in xrange(0, len(value)):

                    for stat in stats:
                        if (value[k] in dict_status[stat]):
                            dict_status[stat].remove(value[k])

                    if (value[k] not in dict_status[key]):
                        dict_status[key].append(value[k])

        for stat in stats:
            row[stat] = len(dict_status[stat])

        else:
            for stat in stats:
                row[stat] = len(dict_status[stat])

        row["timestamp"] = t
        writer.writerow(row)



def build_data(path,save_path):

    containers = {}
    applications = {}

    application_stats=["RUNNING"]
    container_stats=["RUNNING"]

    start_time = sys.maxint
    stop_time = 0

    for file in os.listdir(path):
         file_path = os.path.join(path,file)
         if "log" in file_path:
            current_file = open (file_path,'r')
            print ("Parsing log: " , file_path)

            last_found_timestamp_apps=0
            last_found_timestamp_cont=0
            for line in current_file:
                if re.match('\d{4}-\d{2}-\d{2}', line):

                    date = line[0:19]
                    milis = line[20:23]
                    timestamp = time.mktime(datetime.datetime.strptime(date, "%Y-%m-%d %H:%M:%S").timetuple())
                    timestamp = float(timestamp)

                    if (timestamp < start_time): start_time = timestamp
                    if (timestamp > stop_time): stop_time = timestamp

                    if ("application" in line and "State change from" in line):

                        new_state =  line.split()[-1]
                        previous_state = line.split()[-3]
                        if (new_state not in application_stats) : application_stats.append(new_state)
                        if (previous_state not in application_stats) : application_stats.append(previous_state)
                        update_dict(applications,get_id(line,"application"),application_stats,new_state,timestamp,)

                    elif ("container_" in line and "Container Transitioned" in line):

                        new_state =  line.split()[-1]
                        previous_state = line.split()[-3]

                        if (new_state not in container_stats) : container_stats.append(new_state)
                        if (previous_state not in container_stats) : container_stats.append(previous_state)
                        update_dict(containers,get_id(line,"container"),container_stats,new_state,timestamp,)

    print("Finished parsing log....")
    print("Processing applications....")

    build_csv(applications,"applications",save_path,application_stats,start_time,stop_time)
    print ("Done, data sotored in: " + save_path + "/applications.csv")

    print("Processing containers....")
    build_csv(containers,"containers",save_path,container_stats,start_time,stop_time)
    print ("Done, data sotored in: " + save_path + "/containers.csv")

def main(argc, argv):
    parser = argparse.ArgumentParser(description='parse yarn log')
    parser.add_argument('source', help='path to the directory containing the logs')
    parser.add_argument('save_path', help='folder in which to save the resulting csv')
    args = parser.parse_args()## show values ##

    source_path = (os.path.normpath(args.source))
    save_path = (os.path.normpath(args.save_path))

    build_data(source_path,save_path)

    print ("END")
    sys.exit()

if __name__ == "__main__":
    exit(main(len(sys.argv), sys.argv))
