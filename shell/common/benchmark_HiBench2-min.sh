# All HiBench are the same
source "$ALOJA_REPO_PATH/shell/common/benchmark_HiBench2.sh"

benchmark_hibench_config_bayes() {
  export COMPRESS_GLOBAL=0
  export COMPRESS_CODEC_GLOBAL=org.apache.hadoop.io.compress.DefaultCodec
  export PAGES=12000
  export CLASSES=1
  export NUM_MAPS=2
  export NUM_REDS=2
  export NGRAMS=1
}

benchmark_hibench_config_dfsioe() {
  export COMPRESS_GLOBAL=0
  export COMPRESS_CODEC_GLOBAL=org.apache.hadoop.io.compress.DefaultCodec
  export RD_NUM_OF_FILES=5
  export RD_FILE_SIZE=1
  export WT_NUM_OF_FILES=5
  export WT_FILE_SIZE=1
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
  export PAGES=500
  export NUM_MAPS=1
  export NUM_REDS=1
  export NUM_ITERATIONS=2
}

benchmark_hibench_config_sort() {
  export COMPRESS_GLOBAL=0
  export COMPRESS_CODEC_GLOBAL=org.apache.hadoop.io.compress.DefaultCodec
  export DATASIZE=10
  export NUM_MAPS=1
  export NUM_REDS=1
}

benchmark_hibench_config_terasort() {
  export COMPRESS_GLOBAL=0
  export COMPRESS_CODEC_GLOBAL=org.apache.hadoop.io.compress.DefaultCodec
  export DATASIZE=1
  export NUM_MAPS=1
  export NUM_REDS=1
}

benchmark_hibench_config_wordcount() {
  export COMPRESS_GLOBAL=0
  export COMPRESS_CODEC_GLOBAL=org.apache.hadoop.io.compress.DefaultCodec
  export DATASIZE=4 #very small will say 0 mappers
  export NUM_MAPS=1
  export NUM_REDS=1
}

benchmark_hibench_config_hivebench() {
  export COMPRESS_GLOBAL=1
  export COMPRESS_CODEC_GLOBAL=org.apache.hadoop.io.compress.DefaultCodec
  export USERVISITS=1000
  export PAGES=120
  export NUM_MAPS=1
  export NUM_REDS=1
}