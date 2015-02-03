#!/bin/bash

usage() {
  echo "Usage: $0 [-n net <IB|ETH>] [-d disk <SSD|HDD>] [-b benchmark <_min|_10>] [-r replicaton <positive int>]\
   [-m max mappers and reducers <positive int>] [-i io factor <positive int>] [-p port prefix <3|4|5>]\
   [-I io.file <positive int>] [-l list of benchmarks <space separated string>] [-c compression <0 (dissabled)|1|2|3>]\
   [-z <block size in bytes>] [-s (save prepare)] -N (don't delete files)" 1>&2;
  echo "example: $0 -n IB -d SSD -r 1 -m 12 -i 10 -p 3 -b _min -I 4096 -l wordcount -c 1"
  exit 1;
}

output=""
NL=$'\n'

# Default values
VERBOSE=0
NET="IB"
DISK="SSD"
BENCH=""
REPLICATION=1
MAX_MAPS=12
IO_FACTOR=10
PORT_PREFIX=3
IO_FILE=65536
LIST_BENCHS="wordcount sort terasort kmeans pagerank bayes dfsioe" #nutchindexing hivebench

COMPRESS_GLOBAL=0
COMPRESS_TYPE=0

SAVE_BENCH=""

BLOCK_SIZE=67108864

DELETE_HDFS=1
DELETE=" "
#echo "starting"
line=0

Q_PATH="~/qsub/queue"
CONF_PATH="$Q_PATH/conf"


current_idx=$(cat "$CONF_PATH/counter")

#current_idx=0

if [[ ! $current_idx =~ ^-?[0-9]+$ ]] ; then
  current_idx=0
fi


for DISK in "HDD" "SSD"
do
  DELETE=" "
for NET in "IB " "ETH"
do
for REPLICATION in "1" #"3" #{1..3}
do
  #DELETE=" "
for MAX_MAPS in "12" #"24" # "4" "8" "16" "32"
do
for IO_FACTOR in "10" #"5" "10" "20" "50"
do
for IO_FILE in  "65536" #"32768" "131072" "4096"
do
for COMPRESS_TYPE in {0..3}
do
for BLOCK_SIZE in "67108864" "33554432" "67108864" "134217728" "268435456"
do
for LIST_BENCHS in  "kmeans" "wordcount" "sort"  "pagerank" "bayes" "dfsioe" # "terasort"
do

  CONF="conf_${NET}_${DISK}_b${BENCH}_m${MAX_MAPS}_i${IO_FACTOR}_r${REPLICATION}_I${IO_FILE}_c${COMPRESS_TYPE}_z$((BLOCK_SIZE / 1048576 ))"
  current_command="~/qsub/run.sh -n $NET -d $DISK -r $REPLICATION -m $MAX_MAPS -i $IO_FACTOR -p $PORT_PREFIX -I $IO_FILE -c $COMPRESS_TYPE -z $BLOCK_SIZE $DELETE -l \"$LIST_BENCHS\";"
  output="${output}${current_command}
  "

  #date_with_nano=$(date +%s%N | cut -b1-13)

  index=$(printf %08d $current_idx)


  #create the file for the queue
  echo "$current_command" > "$Q_PATH/${index}_${CONF// /_}_${LIST_BENCHS// /_}"

  #Set to dont delete HDFS to save time after first exec of disk group
  DELETE="-N"

  #increment indexes
  current_idx=$((current_idx + 1))
  line=$((line + 1))

  #just in case for the file name order
  #sleep 0.001

done
done
done
done
done
done
done
done
done

echo "$current_idx" > "$CONF_PATH/counter"

echo "Created $line files"
#echo "$output"
