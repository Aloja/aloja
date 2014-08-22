CUR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CUR_DIR/common.sh"

clusterConfigFilePath="$CUR_DIR/../conf"

[ ! -f "$clusterConfigFilePath/$clusterConfigFile" ] && { echo "$clusterConfigFilePath/$clusterConfigFile is not a file." ; exit 1;}

#load cluster or node config second
source "$clusterConfigFilePath/$clusterConfigFile"


get_node_names() {
  node_names=''
  for vm_id in $(seq -f "%02g" 0 "$numberOfNodes") ; do #pad the sequence with 0s
    node_names="${node_names}\n${clusterName}-${vm_id}"
  done
}

get_slaves_names() {
  node_names=''
  for vm_id in $(seq -f "%02g" 1 "$numberOfNodes") ; do #pad the sequence with 0s
    node_names="${node_names}\n${clusterName}-${vm_id}"
  done
}

get_master_name() {
  master_name=''
  for vm_id in $(seq -f "%02g" 0 "$numberOfNodes") ; do #pad the sequence with 0s
    master_name="${clusterName}-${vm_id}"
    break #just return one
  done
}

get_master_ssh_port() {
  master_ssh_port=''
  for vm_id in $(seq -f "%02g" 0 "$numberOfNodes") ; do #pad the sequence with 0s
    master_ssh_port="2${clusterID}${vm_id}"
    break #just return one
  done
}
