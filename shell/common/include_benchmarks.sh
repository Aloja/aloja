# File to handle the include files (sources) necessary for benchmarking

# 1.) Load base files
source "$ALOJA_REPO_PATH/shell/common/common.sh"
#Check if we can continue
if [ ! "$ALOJA_REPO_PATH" ] || [ -z "$testKey" ] ; then
  echo "ERROR: Cannot source files. Exiting...";
  exit 1
fi

#GLOBAL ASSOCIATIVE ARRAYS declared globally here due to multi bash version issues
# Arrays for times and errors
declare -A EXEC_TIME
declare -A EXEC_START
declare -A EXEC_START_DATE
declare -A EXEC_END
declare -A EXEC_STATUS #for exit status

# Associative array for downloading apps and configs
# Format $BENCH_REQUIRED_FILES["Folder Name after uncompress"]="URL to download tarball"
declare -A BENCH_REQUIRED_FILES

# Associative array for default disk paths
declare -A BENCH_DISKS

#make sure we cleanup subprocesses on abnormal exit (ie ctrl+c)
setup_traps

source_file "$ALOJA_REPO_PATH/shell/common/common_benchmarks.sh"

logger "DEBUG: CMD ${BASH_SOURCE[0]} ${*}"

# 2.) Load cluster configs

# Attempt first to load local cluster config if defined
if [[ -z "$clusterName" &&  -f ~/aloja_cluster.conf ]] ; then
  source_file ~/aloja_cluster.conf  #here we don't have globals loaded yet
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
source_file "$ALOJA_REPO_PATH/shell/conf/$clusterConfigFile"

# Load instrumentation functions if requested
if [ "$INSTRUMENTATION" ] ; then
  source_file "$ALOJA_REPO_PATH/shell/common/common_instrumentation.sh"
fi

# Load defaultProvider
logger "DEBUG: attempting to load secured account configs if present"
securedProviderFile="$ALOJA_REPO_PATH/secure/${defaultProvider}_settings.conf"

if [ -f "$securedProviderFile" ] ; then
  source_file "$securedProviderFile"
elif [ -f "$ALOJA_REPO_PATH/secure/provider_defaults.conf" ] ; then
  source_file "$ALOJA_REPO_PATH/secure/provider_defaults.conf"
else
  die "No provider and accounts defaults present.  Check your secure directory"
fi

source_file "$ALOJA_REPO_PATH/shell/conf/benchmarks_defaults.conf"


logger "Starting ALOJA benchmarking tools for Provider: $defaultProvider"

source_file "$ALOJA_REPO_PATH/shell/common/cluster_functions.sh"

if [ ! -z "defaultProvider" ] ; then
  providerFunctionsFile="$ALOJA_REPO_PATH/aloja-deploy/providers/${defaultProvider}.sh"
else
  providerFunctionsFile="$ALOJA_REPO_PATH/aloja-deploy/providers/${2}.sh"
fi

# Check if provider file exists
[ ! -f "$providerFunctionsFile" ] && die "ERROR: cannot find providers function file in $providerFunctionsFile"

source_file "$providerFunctionsFile"

# Selected Bencmark specific source_files and overrides

source_file "$ALOJA_REPO_PATH/shell/common/benchmark_${BENCH_SUITE}.sh"

# Re-load cluster or node config
logger "DEBUG: Re-loading $ALOJA_REPO_PATH/shell/conf/$clusterConfigFile for overrides"
source_file "$ALOJA_REPO_PATH/shell/conf/$clusterConfigFile"