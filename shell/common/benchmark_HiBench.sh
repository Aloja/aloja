CONF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Load hadoop defaults
source "$CONF_DIR/common_hadoop.sh"


benchmark_config() {
  prepare_hadoop_config ${NET} ${DISK} ${BENCH}
}

benchmark_run() {
  execute_HiBench
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


benchmark_hibench_config_bayes() {
  export COMPRESS_GLOBAL=1
  export COMPRESS_CODEC_GLOBAL=org.apache.hadoop.io.compress.DefaultCodec
}

benchmark_hibench_config_dfsioe() {
  export COMPRESS_GLOBAL=1
  export COMPRESS_CODEC_GLOBAL=org.apache.hadoop.io.compress.DefaultCodec
}

benchmark_hibench_config_kmeans() {
  export COMPRESS_GLOBAL=1
  export COMPRESS_CODEC_GLOBAL=org.apache.hadoop.io.compress.DefaultCodec
}

benchmark_hibench_config_pagerank() {
  export COMPRESS_GLOBAL=1
  export COMPRESS_CODEC_GLOBAL=org.apache.hadoop.io.compress.DefaultCodec
}

benchmark_hibench_config_sort() {
  export COMPRESS_GLOBAL=1
  export COMPRESS_CODEC_GLOBAL=org.apache.hadoop.io.compress.DefaultCodec
}

benchmark_hibench_config_terasort() {
  export COMPRESS_GLOBAL=1
  export COMPRESS_CODEC_GLOBAL=org.apache.hadoop.io.compress.DefaultCodec
}

benchmark_hibench_config_wordcount() {
  export COMPRESS_GLOBAL=1
  export COMPRESS_CODEC_GLOBAL=org.apache.hadoop.io.compress.DefaultCodec
}