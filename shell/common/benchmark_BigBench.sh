CONF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Load hadoop defaults
source "$CONF_DIR/common_hadoop.sh"


benchmark_config() {
  prepare_hadoop_config ${NET} ${DISK} ${BENCH}
}

benchmark_run() {
  restart_hadoop
  sleep 120
}

benchmark_teardown() {
  : # Empty
}

benchmark_save() {
  : # Empty
}

benchmark_cleanup() {
  stop_hadoop
}