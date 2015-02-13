#!/bin/bash

CUR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_DIR=$(pwd)

source "$CUR_DIR/common/include_import.sh"
source "$CUR_DIR/common/import_functions.sh"

logger "Starting ALOJA DB create/update script"

logger "Creating tables, applying alters, updating data..."

source "$CUR_DIR/common/create_db.sh"

logger "Updating clusters and hosts"

for clusterConfigFile in $configFolderPath/cluster_* ; do

  id_cluster="${clusterConfigFile:(-7):2}"
  logger "INFO: loading $clusterConfigFile with ID $id_cluster"

  #TODO this check wont work for old folders with numeric values at the end, need another strategy
  #line to fix update execs set id_cluster=1 where id_cluster IN (28,32,56,64);
  if [ -f "$clusterConfigFile" ] && [[ $id_cluster =~ ^-?[0-9]+$ ]] ; then
    sql_tmp="$(get_insert_cluster_sql "$id_cluster" "$clusterConfigFile")"
    echo "Executing $sql_tmp"
    $MYSQL "$sql_tmp"
  fi

done
