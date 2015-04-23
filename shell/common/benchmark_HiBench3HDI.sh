CONF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Load hadoop defaults
source "$CONF_DIR/common_hadoop.sh"


benchmark_config() {
  : #Empty
}

format_nodes() {
   $DSH_MASTER "yes Y | hadoop namenode -format" 2>&1 |tee -a $LOG_PATH
   $DSH_MASTER "yes Y | hadoop datanode -format" 2>&1 |tee -a $LOG_PATH	
}

benchmark_run() {
  execute_HDI_HiBench
}

benchmark_teardown() {
  : # Empty
}

benchmark_save() {
  : # Empty
}

benchmark_cleanup() {
  : #Empty
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
  export DATASIZE=1000000000
}

benchmark_hibench_config_wordcount() {
  export COMPRESS_GLOBAL=1
  export COMPRESS_CODEC_GLOBAL=org.apache.hadoop.io.compress.DefaultCodec
}