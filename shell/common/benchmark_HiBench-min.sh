# All HiBench are the same
source "$ALOJA_REPO_PATH/shell/common/benchmark_HiBench.sh"

benchmark_hibench_config_bayes() {
  export COMPRESS_GLOBAL=0
  export COMPRESS_CODEC_GLOBAL=org.apache.hadoop.io.compress.DefaultCodec
  export PAGES=8000
  export CLASSES=10
  export NUM_MAPS=96
  export NUM_REDS=48
  export NGRAMS=3
}

benchmark_hibench_config_dfsioe() {
  export COMPRESS_GLOBAL=0
  export COMPRESS_CODEC_GLOBAL=org.apache.hadoop.io.compress.DefaultCodec
  export RD_NUM_OF_FILES=5
  export RD_FILE_SIZE=20
  export WT_NUM_OF_FILES=5
  export WT_FILE_SIZE=10
}

benchmark_hibench_config_kmeans() {
  export COMPRESS_GLOBAL=0
  export COMPRESS_CODEC_GLOBAL=org.apache.hadoop.io.compress.DefaultCodec
  export NUM_OF_CLUSTERS=3
  export NUM_OF_SAMPLES=30
  export SAMPLES_PER_INPUTFILE=60
  export DIMENSIONS=5
  export MAX_ITERATION=5
}

benchmark_hibench_config_pagerank() {
  export COMPRESS_GLOBAL=0
  export COMPRESS_CODEC_GLOBAL=org.apache.hadoop.io.compress.DefaultCodec
  export PAGES=50
  export NUM_MAPS=7
  export NUM_REDS=7
  export NUM_ITERATIONS=2
}

benchmark_hibench_config_sort() {
  export COMPRESS_GLOBAL=0
  export COMPRESS_CODEC_GLOBAL=org.apache.hadoop.io.compress.DefaultCodec
  export DATASIZE=240
  export NUM_MAPS=7
  export NUM_REDS=7
}

benchmark_hibench_config_terasort() {
  export COMPRESS_GLOBAL=0
  export COMPRESS_CODEC_GLOBAL=org.apache.hadoop.io.compress.DefaultCodec
  export DATASIZE=100
  export NUM_MAPS=10
  export NUM_REDS=10
}

benchmark_hibench_config_wordcount() {
  export COMPRESS_GLOBAL=0
  export COMPRESS_CODEC_GLOBAL=org.apache.hadoop.io.compress.DefaultCodec
  export DATASIZE=32
  export NUM_MAPS=16
  export NUM_REDS=48
}