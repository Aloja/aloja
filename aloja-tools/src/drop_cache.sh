#!/usr/bin/env bash

# Script to drop the buffer cache
# More info: http://unix.stackexchange.com/questions/87908/how-do-you-empty-the-buffers-and-cache-on-a-linux-system

drop_interval="${1:-1}" # the number of seconds to repeat
drop_level="${2:-3}" # 3 To free pagecache, dentries and inodes
drop_free="${3:-1}" # if to call and print free command

if [[ ! "$drop_interval" || ! "$drop_level" ]] ; then
  echo "ERROR need to set the drop cache interval: $drop_interval or the level: $drop_level. Exiting..."
  exit 1
else
  echo "Starting to drop cache at interval: $drop_interval s. and level: $drop_level"
fi

while true; do
  [ "$drop_free" == "1" ] && free
  sudo sh -c "echo $drop_level >/proc/sys/vm/drop_caches"
  sleep "$drop_interval"
done