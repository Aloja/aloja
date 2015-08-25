# File to handle the include files (sources) necessary for benchmarking

# 1.) Load base files
source "$ALOJA_REPO_PATH/shell/common/common.sh"
#Check if we can continue
if [ ! "$ALOJA_REPO_PATH" ] || [ -z "$testKey" ] ; then
  echo "ERROR: Cannot source files. Exiting...";
  exit 1
fi

logger "INFO: Loading $ALOJA_REPO_PATH/shell/common/common.sh" #actually already loaded it

#make sure we cleanup subprocesses on abnormal exit (ie ctrl+c)
trap 'echo "RUNNING TRAP "; sleep 1 && [ $(jobs -p) ] && kill $(jobs -p); exit 1;' SIGINT SIGTERM
PARENT_PID=$$ #for killing the process from subshells

logger "INFO: Loading $ALOJA_REPO_PATH/shell/common/common_benchmarks.sh"
source "$ALOJA_REPO_PATH/shell/common/common_benchmarks.sh"

# 2.) Load cluster configs

# Attempt first to load local cluster config if defined
if [[ -z "$clusterName" &&  -f ~/aloja_cluster.conf ]] ; then
  source ~/aloja_cluster.conf  #here we don't have globals loaded yet
fi

# Check command line options
get_options "$@"

# Test and load cluster config
if [ "${clusterName}" ] ; then
  clusterConfigFile="cluster_${clusterName}.conf"
else
  logger "ERROR: cluster not specified"
  usage #here it will exit
fi

if [ ! -f "$ALOJA_REPO_PATH/shell/conf/$clusterConfigFile" ] ; then
  logger "ERROR: cannot find clusterConfigFile at: $ALOJA_REPO_PATH/shell/conf/$clusterConfigFile"
  usage #here it will exit
fi

# Load cluster config
logger "INFO: loading $ALOJA_REPO_PATH/shell/conf/$clusterConfigFile"
source "$ALOJA_REPO_PATH/shell/conf/$clusterConfigFile"

# load defaultProvider
logger "INFO: attempting to load secured account configs if present"
securedProviderFile="$ALOJA_REPO_PATH/secure/${defaultProvider}_settings.conf"

if [ -f "$securedProviderFile" ] ; then
  logger "INFO: loading $securedProviderFile"
  source "$securedProviderFile"
else
  logger "INFO: no secured accounts file present"
fi

logger "INFO: loading benchmarks_defaults.conf"
source "$ALOJA_REPO_PATH/shell/conf/benchmarks_defaults.conf"


logger "Starting ALOJA benchmarking tools for Provider: $defaultProvider"

source "$ALOJA_REPO_PATH/shell/common/cluster_functions.sh"

if [ ! -z "defaultProvider" ] ; then
  providerFunctionsFile="$ALOJA_REPO_PATH/aloja-deploy/providers/${defaultProvider}.sh"
else
  providerFunctionsFile="$ALOJA_REPO_PATH/aloja-deploy/providers/${2}.sh"
fi

# Check if provider file exists
[ ! -f "$providerFunctionsFile" ] && die "ERROR: cannot find providers function file in $providerFunctionsFile"

logger "INFO: loading $providerFunctionsFile"
source "$providerFunctionsFile"

# Selected Bencmark specific sources and overrides

logger "INFO: loading $ALOJA_REPO_PATH/shell/common/benchmark_${BENCH}.sh"
source "$ALOJA_REPO_PATH/shell/common/benchmark_${BENCH}.sh"

# Re-load cluster or node config
logger "INFO: Re-loading $ALOJA_REPO_PATH/shell/conf/$clusterConfigFile for overrides"
source "$ALOJA_REPO_PATH/shell/conf/$clusterConfigFile"