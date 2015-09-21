# All HiBench2 are the same
source "$ALOJA_REPO_PATH/shell/common/benchmark_HiBench2.sh"

# Only terasort is enabled
[ ! "$BENCH_LIST" ] && BENCH_LIST="terasort"

if [ "$JAVA_XMX" ] ; then
  if (( "${JAVA_XMX//[!0-9]/}" < 2048 )) ; then
    logger "WARNING: setting JAVA_XMX to 4048m to run 1TB was ${JAVA_XMX//[!0-9]/}m "
    JAVA_XMS="-Xms4048m" #START
    JAVA_XMX="-Xmx4048m" #MAX
  fi
fi

benchmark_hibench_config_terasort() {
  export COMPRESS_GLOBAL=0
  export COMPRESS_CODEC_GLOBAL=org.apache.hadoop.io.compress.DefaultCodec
  export DATASIZE=10000000000
  export NUM_MAPS=10
  export NUM_REDS=10
}