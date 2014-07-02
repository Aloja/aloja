#!/usr/bin/python2.7
#
# Originally from https://github.com/lila/hadoop-jobanalyzer

#TODO CHECK BOUNDARIES ERROR

import re
import sys
import argparse
import collections
import datetime

parser = argparse.ArgumentParser(description='Parse Hadoop Job History')
parser.add_argument("-t", metavar='tasks_file', help="Output tasks (mappers and reducers)", nargs='?', const=True)
parser.add_argument("-j", metavar='job_file',  help="Output job details", nargs='?', const=True)
parser.add_argument("-d", metavar='status_file', help="Output mappers or reducers", nargs='?', const=True)
parser.add_argument('-i', metavar='input_file', help='Hadoop Job history file', required=True)

args = parser.parse_args()

pat = re.compile('(?P<name>[^=]+)="(?P<value>[^"]*)" *')
groupPat = re.compile(r'{\((?P<key>[^)]+)\)\((?P<name>[^)]+)\)(?P<counters>[^}]+)}')
counterPat = re.compile(r'\[\((?P<key>[^)]+)\)\((?P<name>[^)]+)\)\((?P<value>[^)]+)\)\]')


def parseCounters(str):
  result = {}
  for k, n, c in re.findall(groupPat, str):
    group = {}
    result[n] = group
    for sk, sn, sv in re.findall(counterPat, c):
      group[sn] = int(sv)
  return result

def parse(tail):
  result = {}
  for n, v in re.findall(pat, tail):
    result[n] = v
  return result

def MySQL_date(timestamp):
  return datetime.datetime.utcfromtimestamp(timestamp).strftime('%Y-%m-%d %H:%M:%S')

def writeOrPrint(option, contents):
  if isinstance(option, bool) and option:
    print contents
  else:
    writeFile(option, contents)

def writeFile(filename, contents):
  file = open(filename, 'w')
  file.write(contents)
  file.close()

mapStartTime = {}
mapEndTime = {}
reduceStartTime = {}
reduceShuffleTime = {}
reduceSortTime = {}
reduceEndTime = {}
reduceBytes = {}
remainder = ""
finalAttempt = {}

wastedAttempts = []
submitTime = None
finishTime = None
scale = 1000

jobDetails = collections.OrderedDict()
tasksDetails = collections.OrderedDict()

jobKeys = ([('JOBID', None),
            ('JOBNAME', None),
            ('SUBMIT_TIME', None),
            ('LAUNCH_TIME', None),
            ('FINISH_TIME', None),
            ('JOB_PRIORITY', None),
            ('USER', None),
           ('TOTAL_MAPS', None),
           ('FAILED_MAPS', None),
           ('FINISHED_MAPS', None),
           ('TOTAL_REDUCES', None),
           ('FAILED_REDUCES', None),])

#'COUNTERS', 'MAP_COUNTERS', 'REDUCE_COUNTERS'

counterKeys = ([ ('Launched map tasks', None), #Job Counters
                 ('Rack-local map tasks', None),
                 ('Launched reduce tasks', None),
                 ('SLOTS_MILLIS_MAPS', None),
                 ('SLOTS_MILLIS_REDUCES', None),
                 ('Data-local map tasks', None),

                 ('FILE_BYTES_WRITTEN', None), #FileSystem
                 ('FILE_BYTES_READ', None),
                 ('HDFS_BYTES_WRITTEN', None),
                 ('HDFS_BYTES_READ', None),

                 ('Bytes Read', None),  ('Bytes Written', None), #File Input/Output Format

                 ('Spilled Records', None),  #MR framework
                 ('SPLIT_RAW_BYTES', None),
                 ('Map input records', None),
                 ('Map output records', None),
                 ('Map input bytes', None),
                 ('Map output bytes', None),
                 ('Map output materialized bytes', None),
                 ('Reduce input groups', None),
                 ('Reduce input records', None),
                 ('Reduce output records', None),
                 ('Reduce shuffle bytes', None),
                 ('Combine input records', None),
                 ('Combine output records', None), ])

#initialize in order
for key_name, value in jobKeys:
  jobDetails[key_name] = value
for key_name, value in counterKeys:
  jobDetails[key_name] = value

countersAndTypes = collections.OrderedDict()

#iterate the file
for line in open(args.i):
  if len(line) < 3 or line[-3:] != " .\n":
    remainder += line
    continue
  line = remainder + line
  remainder = ""
  words = line.split(" ", 1)
  event = words[0]
  attrs = parse(words[1])
  if event == 'Job':
    #add job details
    for key_name in attrs.keys():
      if jobDetails.has_key(key_name):
        if key_name.find('_TIME') > -1:
          #convert to MySQL date format
          jobDetails[key_name] = MySQL_date(int(attrs[key_name])/1000)
        else:
          jobDetails[key_name] = attrs[key_name]
      elif key_name.find('COUNTERS') > -1:
        counters = parseCounters(attrs[key_name])
        test = jobDetails.keys()
        for key_counter in counters:
          for value_counter in counters[key_counter]:
            if jobDetails.has_key(value_counter):
              jobDetails[value_counter] = counters[key_counter][value_counter]
            else:
              sys.stderr.write('COUNTER NOT IN LIST: ' + value_counter + ' From: ' + key_counter + "\n")
            #to get a list of counters
            if not countersAndTypes.has_key(key_counter):
              countersAndTypes[key_counter] = set()
            countersAndTypes[key_counter].add(value_counter)

    if attrs.has_key("SUBMIT_TIME"):
      submitTime = int(attrs["SUBMIT_TIME"]) / scale
    elif attrs.has_key("FINISH_TIME"):
      finishTime = int(attrs["FINISH_TIME"]) / scale
  elif event == 'MapAttempt':
    if attrs.has_key("START_TIME"):
      time = int(attrs["START_TIME"]) / scale
      if time != 0:
        mapStartTime[attrs["TASK_ATTEMPT_ID"]] = time
    elif attrs.has_key("FINISH_TIME"):
      mapEndTime[attrs["TASK_ATTEMPT_ID"]] = int(attrs["FINISH_TIME"]) / scale
      if attrs.get("TASK_STATUS", "") == "SUCCESS":
        task = attrs["TASKID"]
        if finalAttempt.has_key(task):
          wastedAttempts.append(finalAttempt[task])
        finalAttempt[task] = attrs["TASK_ATTEMPT_ID"]
      else:
        wastedAttempts.append(attrs["TASK_ATTEMPT_ID"])
  elif event == 'ReduceAttempt':
    if attrs.has_key("START_TIME"):
      time = int(attrs["START_TIME"]) / scale
      if time != 0:
        reduceStartTime[attrs["TASK_ATTEMPT_ID"]] = time
    elif attrs.has_key("FINISH_TIME"):
      task = attrs["TASKID"]
      if attrs.get("TASK_STATUS", "") == "SUCCESS":
        if finalAttempt.has_key(task):
          wastedAttempts.append(finalAttempt[task])
        finalAttempt[task] = attrs["TASK_ATTEMPT_ID"]
      else:
        wastedAttempts.append(attrs["TASK_ATTEMPT_ID"])
      reduceEndTime[attrs["TASK_ATTEMPT_ID"]] = int(attrs["FINISH_TIME"]) / scale
      if attrs.has_key("SHUFFLE_FINISHED"):
        reduceShuffleTime[attrs["TASK_ATTEMPT_ID"]] = int(attrs["SHUFFLE_FINISHED"]) / scale
      if attrs.has_key("SORT_FINISHED"):
        reduceSortTime[attrs["TASK_ATTEMPT_ID"]] = int(attrs["SORT_FINISHED"]) / scale
  elif event == 'Task' and attrs.has_key("COUNTERS"):
    counters = parseCounters(attrs["COUNTERS"])
    #to save some mem in case it was not requested
    if args.t:
      tasksDetails[attrs['TASKID']] = collections.OrderedDict([
        ('TASK_TYPE', attrs['TASK_TYPE']),
        ('TASK_STATUS', attrs['TASK_STATUS']),
        ('START_TIME', None),
        ('FINISH_TIME', int(attrs['FINISH_TIME'])/1000),
        ('SHUFFLE_TIME', None),
        ('SORT_TIME', None),

        ('Bytes Read', None), #FS
        ('Bytes Written', None),

        ('FILE_BYTES_WRITTEN', None), #FS
        ('FILE_BYTES_READ', None),
        ('HDFS_BYTES_WRITTEN', None),
        ('HDFS_BYTES_READ', None),

        ('Spilled Records', None), #MR Framework
        ('SPLIT_RAW_BYTES', None),
        ('Map input records', None),
        ('Map output records', None),
        ('Map input bytes', None),
        ('Map output bytes', None),
        ('Map output materialized bytes', None),
        ('Reduce input groups', None),
        ('Reduce input records', None),
        ('Reduce output records', None),
        ('Reduce shuffle bytes', None),
        ('Combine input records', None),
        ('Combine output records', None), ])

      attemptName = finalAttempt[attrs['TASKID']]

      if attrs["TASK_TYPE"] == "REDUCE":
        tasksDetails[attrs['TASKID']]['START_TIME'] = str(reduceStartTime[attemptName]) + '000'
        tasksDetails[attrs['TASKID']]['SHUFFLE_TIME'] = str(reduceShuffleTime[attemptName]) + '000'
        tasksDetails[attrs['TASKID']]['SORT_TIME'] = str(reduceSortTime[attemptName]) + '000'
      else:
        tasksDetails[attrs['TASKID']]['START_TIME'] = str(mapStartTime[attemptName]) + '000'

      for key_counter in counters:
        for value_counter in counters[key_counter]:
          #to get a list of all counters
          if not countersAndTypes.has_key(key_counter):
            countersAndTypes[key_counter] = set()
          countersAndTypes[key_counter].add(value_counter)
          #add to taskDetails
          if tasksDetails[attrs['TASKID']].has_key(value_counter):
            tasksDetails[attrs['TASKID']][value_counter] = counters[key_counter][value_counter]

      for key_attrs in attrs:
        if tasksDetails[attrs['TASKID']].has_key(key_attrs):
          tasksDetails[attrs['TASKID']][key_attrs] = attrs[key_attrs]

    if attrs["TASK_TYPE"] == "REDUCE":
      reduceBytes[attrs["TASKID"]] = int(counters.get('FileSystemCounters', {}).get('HDFS_BYTES_WRITTEN', 0))

reduces = reduceBytes.keys()
reduces.sort()

#job details
if args.j:
  outputJobDetails = ''
  for key_name in jobDetails.keys():
    outputJobDetails += key_name + ','
  outputJobDetails = outputJobDetails[:-1] + "\n"
  for value in jobDetails.values():
    if not value:
      outputJobDetails += 'NULL,'
    else:
      outputJobDetails += '"' + str(value) + '",'
  outputJobDetails = outputJobDetails[:-1] + "\n"

#task details
if args.t:
  outputTaskDetails = 'JOBID,TASKID,'
  #header
  for taskDetail in tasksDetails:
    for key_detail in tasksDetails[taskDetail]:
      outputTaskDetails += key_detail + ','
    outputTaskDetails = outputTaskDetails[:-1] + "\n"
    break
  #values
  for taskDetail in tasksDetails:
    outputTaskDetails += jobDetails['JOBID'] + ',' + taskDetail + ','
    for key_detail in tasksDetails[taskDetail]:
      value = tasksDetails[taskDetail][key_detail]
      if value and key_detail.find('_TIME') > -1:
        value = MySQL_date(int(value)/1000)
      elif not value:
        value = 'NULL'
      outputTaskDetails += str(value) + ','
    outputTaskDetails = outputTaskDetails[:-1] + "\n"

if args.d:
  runningMaps = []
  shufflingReduces = []
  sortingReduces = []
  runningReduces = []
  waste = []
  runningTime = []
  final = {}

  for t in finalAttempt.values():
    final[t] = None

  for t in range(submitTime, finishTime):
    runningMaps.append(0)
    shufflingReduces.append(0)
    sortingReduces.append(0)
    runningReduces.append(0)
    waste.append(0)
    runningTime.append(t)

  for map in mapEndTime.keys():
    isFinal = final.has_key(map)
    if mapStartTime.has_key(map):
      for t in range(mapStartTime[map] - submitTime, mapEndTime[map] - submitTime):
        # while t >= len(runningMaps):
        #   runningMaps.append(0)
        #   shufflingReduces.append(0)
        #   sortingReduces.append(0)
        #   runningReduces.append(0)
        #   waste.append(0)
        if t < len(runningMaps):
          if final:
            runningMaps[t] += 1
          else:
            waste[t] += 1

  for reduce in reduceEndTime.keys():
    if reduceStartTime.has_key(reduce):
      if final.has_key(reduce):
        for t in range(reduceStartTime[reduce] - submitTime, reduceShuffleTime[reduce] - submitTime):
          if t < len(shufflingReduces):
            shufflingReduces[t] += 1
        for t in range(reduceShuffleTime[reduce] - submitTime, reduceSortTime[reduce] - submitTime):
          if t < len(shufflingReduces):
            sortingReduces[t] += 1
        for t in range(reduceSortTime[reduce] - submitTime, reduceEndTime[reduce] - submitTime):
          if t < len(shufflingReduces):
            runningReduces[t] += 1
      else:
        for t in range(reduceStartTime[reduce] - submitTime, reduceEndTime[reduce] - submitTime):
          if t < len(shufflingReduces):
            waste[t] += 1

  outputStatus = "JOBID,date,maps,shuffle,merge,reduce,waste\n"
  for t in range(len(runningMaps)):
    #print t, ",", runningMaps[t], ",", shufflingReduces[t], ",", sortingReduces[t], ",", runningReduces[t], ",", waste[t]
    outputStatus += "%s%s%s%s%s%s%s%s%s%s%s%s%s" % (
      jobDetails['JOBID'], ',', MySQL_date(runningTime[t]), ",", runningMaps[t], ",", shufflingReduces[t], ",", sortingReduces[t], ",", runningReduces[t], ",", waste[t])
    outputStatus += "\n"
  outputStatus = outputStatus[:-1] + "\n"

if args.j:
  writeOrPrint(args.j, outputJobDetails)
if args.t:
  writeOrPrint(args.t, outputTaskDetails)
if args.d:
  writeOrPrint(args.d, outputStatus)
