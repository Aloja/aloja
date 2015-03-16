CONF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# All HiBench are the same
source "$CONF_DIR/benchmark_HiBench3.sh"


benchmark_hibench_config_bayes() {
  export PAGES=24500
  export CLASSES=5
  export NUM_MAPS=2
  export NUM_REDS=2
  export NGRAMS=3
}

benchmark_hibench_config_dfsioe() {
  export RD_NUM_OF_FILES=2
  export RD_FILE_SIZE=20
  export WT_NUM_OF_FILES=2
  export WT_FILE_SIZE=10
}

benchmark_hibench_config_kmeans() {
  export NUM_OF_CLUSTERS=3
  export NUM_OF_SAMPLES=15
  export SAMPLES_PER_INPUTFILE=5
  export DIMENSIONS=2
  export MAX_ITERATION=1
}

benchmark_hibench_config_pagerank() {
  export PAGES=500
  export NUM_MAPS=4
  export NUM_REDS=4
  export NUM_ITERATIONS=1
}

benchmark_hibench_config_sort() {
  export DATASIZE=1000
  export NUM_MAPS=4
  export NUM_REDS=4
}

benchmark_hibench_config_terasort() {
  export DATASIZE=1000
  export NUM_MAPS=4
  export NUM_REDS=4
}

benchmark_hibench_config_wordcount() {
  export DATASIZE=1000
  export NUM_MAPS=4
  export NUM_REDS=4
}