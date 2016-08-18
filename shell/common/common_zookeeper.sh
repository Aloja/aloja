#!/usr/bin/env bash#!/usr/bin/env bash
#SETUP ZOOKEEPER SPECIFIC FUNCTIONS NOT OPTIMAL, TEST ONLY
source_file "$ALOJA_REPO_PATH/shell/common/common_hadoop.sh"
set_hadoop_requires


#source_file "$ALOJA_REPO_PATH/shell/common/common_zookeeper.sh"
#set_zookeeper_requires

# Sets the required files to download/copy
set_zookeeper_requires() {
  [ ! "$ZOOKEEPER_VERSION" ] && die "No DRILL_VERSION specified"

  BENCH_REQUIRED_FILES["$ZOOKEEPER_VERSION"]="http://mirror.serversupportforum.de/apache/zookeeper/$ZOOKEEPER_VERSION/$ZOOKEEPER_VERSION.tar.gz"

  #also set the config here
  BENCH_CONFIG_FOLDERS="$BENCH_CONFIG_FOLDERS zookeeper_conf"

}

# Helper to print a line with requiered exports
get_zookeeper_exports() {
  local to_export

  to_export="$(get_hadoop_exports)
export ZOOKEEPER_VERSION='$ZOOKEEPER_VERSION';
export ZOOKEEPER_HOME='$(get_local_apps_path)/${ZOOKEEPER_VERSION}';
export ZOOKEEPER_CONF_DIR=$(get_local_apps_path)/${ZOOKEEPER_VERSION}/conf;
"


  echo -e "$to_export\n"
}


# start zookeeper
start_zookeeper(){
  local zookeeper_exports
  local zk_home="$(get_local_apps_path)/${ZOOKEEPER_VERSION}"
  export PATH=$PATH:zk_home
  export JAVA_HOME="$(get_java_home)"



  local exports="$(get_zookeeper_exports) $zookeeper_exports"
  logger "DEBUG: zk:\n$exports"

  cp $(get_base_configs_path)/zookeeper_conf/zoo.cfg $zk_home/conf/zoo.cfg
  $zk_home/bin/zkServer.sh restart
  #$zk_home/bin/zkCli.sh -server 127.0.0.1:2181
  #$zk_home/bin/zkServer.sh status
  #echo stat | nc 127.0.0.1 2181
  #echo mntr | nc 127.0.0.1 2181
  #echo isro  | nc 127.0.0.1 2181


}


# $1 bench name
save_zookeeper() {
  logger "WARNING: missing to implement a proper save_zookeeper()"
  $(get_local_apps_path)/${ZOOKEEPER_VERSION}/bin/zkServer.sh stop
  save_hadoop "$bench_name"
  }