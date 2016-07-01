#!/usr/bin/env bash

[ ! "$ALOJA_REPO_PATH" ] && ALOJA_REPO_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."

CUR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_DIR=$(pwd)

# Check if to update filters for the whole DB at the end
# this process can take up to 10 minutes on the full DB
# and vagrant VM does not have perf counters, so all would be marked as non-valid
if [ ! "$DONT_UPDATE_FILTERS" ] || [ -d  "/vagrant" ] ; then
  DONT_UPDATE_FILTERS="1"
else
  DONT_UPDATE_FILTERS=""
fi

source "$CUR_DIR/common/include_import.sh"
source "$CUR_DIR/common/import_functions.sh"

logger "Starting ALOJA DB create/update script"

logger "INFO: Creating tables, applying alters, updating data..."

logger "INFO: Creating/Updating DB aloja2"
source "$CUR_DIR/common/create_db.sh"
logger "INFO: Creating/Updating DB aloja_ml"
source "$CUR_DIR/common/create_mlschema.sh"
source "$CUR_DIR/common/update_mlschema.sh"
logger "INFO: Regenerating presets"
source "$CUR_DIR/common/create_presets_schema.sh"

logger "INFO: Updating aloja2.clusters and hosts"

for clusterConfigFile in $configFolderPath/cluster_* ; do
  if [[ ! "$clusterConfigFile" = *"defaults.conf" ]] ; then
    id_cluster="$(get_id_cluster "$clusterConfigFile")"
    logger "DEBUG: Loading $clusterConfigFile with ID $id_cluster"

    #TODO this check wont work for old folders with numeric values at the end, need another strategy
    #line to fix update execs set id_cluster=1 where id_cluster IN (28,32,56,64);
    if [ -f "$clusterConfigFile" ] && [[ $id_cluster =~ ^-?[0-9]+$ ]] ; then
      sql_tmp="$(get_insert_cluster_sql "$id_cluster" "$clusterConfigFile")"
      $MYSQL "$sql_tmp"
    else
      logger "DEBUG: Invalid config file $clusterConfigFile with ID $id_cluster"
    fi
  fi
done

#update filters in the whole DB (slow)
if [ "$DONT_UPDATE_FILTERS" ] ; then
  logger "INFO: Skipping updating filters for the whole DB to save time or for vagrant VM"
else
  logger "INFO: Updating VALID and FILTER fields (probably will take a while...)"
  $MYSQL "$(get_filter_sql)"
fi

