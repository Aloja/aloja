CONF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# All HiBench are the same
source "$CONF_DIR/benchmark_HiBench.sh"


benchmark_hibench_config_bayes() {
  export COMPRESS_GLOBAL=1
  export COMPRESS_CODEC_GLOBAL=org.apache.hadoop.io.compress.DefaultCodec
  export PAGES=8000
  export CLASSES=100
  export NUM_MAPS=96
  export NUM_REDS=48
  export NGRAMS=3
}

benchmark_hibench_config_dfsioe() {
  export COMPRESS_GLOBAL=1
  export COMPRESS_CODEC_GLOBAL=org.apache.hadoop.io.compress.DefaultCodec
  export RD_NUM_OF_FILES=256
  export RD_FILE_SIZE=200
  export WT_NUM_OF_FILES=256
  export WT_FILE_SIZE=100
}

benchmark_hibench_config_kmeans() {
  export COMPRESS_GLOBAL=1
  export COMPRESS_CODEC_GLOBAL=org.apache.hadoop.io.compress.DefaultCodec
  export NUM_OF_CLUSTERS=20
  export NUM_OF_SAMPLES=3000000
  export SAMPLES_PER_INPUTFILE=6000000
  export DIMENSIONS=20
  export MAX_ITERATION=5
}

benchmark_hibench_config_pagerank() {
  export COMPRESS_GLOBAL=1
  export COMPRESS_CODEC_GLOBAL=org.apache.hadoop.io.compress.DefaultCodec
  export PAGES=5000000
  export NUM_MAPS=96
  export NUM_REDS=48
  export NUM_ITERATIONS=3
}

benchmark_hibench_config_sort() {
  export COMPRESS_GLOBAL=1
  export COMPRESS_CODEC_GLOBAL=org.apache.hadoop.io.compress.DefaultCodec
  export DATASIZE=2400000000
  export NUM_MAPS=16
  export NUM_REDS=48
}

benchmark_hibench_config_terasort() {
  export COMPRESS_GLOBAL=1
  export COMPRESS_CODEC_GLOBAL=org.apache.hadoop.io.compress.DefaultCodec
  export DATASIZE=100000000
  export NUM_MAPS=96
  export NUM_REDS=48
}

benchmark_hibench_config_wordcount() {
  export COMPRESS_GLOBAL=1
  export COMPRESS_CODEC_GLOBAL=org.apache.hadoop.io.compress.DefaultCodec
  export DATASIZE=3200000000
  export NUM_MAPS=16
  export NUM_REDS=48
}