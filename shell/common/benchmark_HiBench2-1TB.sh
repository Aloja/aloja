CONF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# All HiBench are the same
source "$CONF_DIR/benchmark_HiBench2.sh"


benchmark_hibench_config_terasort() {
  export COMPRESS_GLOBAL=0
  export COMPRESS_CODEC_GLOBAL=org.apache.hadoop.io.compress.DefaultCodec
  export DATASIZE=10000000000
  export NUM_MAPS=10
  export NUM_REDS=10
}