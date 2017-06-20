#!/bin/env bash

for file in $(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../../shell/conf/cluster_*.conf; do
  suffix=${file##*-};
  echo -e "${suffix%*.conf}\t$file";
done|sort -n