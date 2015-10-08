Import order of run_benchmarks.sh script:

    ┌> shell/common/common.sh
    │
    │        ┌> shell/conf/node_defaults.conf
    │        │
    │     ┌> shell/conf/cluster_defaults.conf
    │     │
    │  ┌> shell/conf/${defaultProvider}_defaults.conf
    │  │
    ├> shell/conf/cluster_${clusterName}.conf
    ├> shell/conf/benchmarks_defaults.conf
    │
    │  ┌> shell/common/provider_functions.sh
    │  │
    ├> shell/common/cluster_functions.sh
    ├> aloja-deploy/providers/${defaultProvider}.sh
    ├> shell/common/common_benchmarks.sh
    ├> shell/common/benchmark_${BENCH}.sh
    │
 ┌> shell/common/include_benchmarks.sh
 │
aloja-bench/run_benchmarks.sh
