#!/bin/bash

CUR_DIR_TMP="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#$1 cluster name
create_cbd_cluster() {

  local output clusterId nodes

  if [ -z "$location" ]; then
    location="IAD"
  fi

  if [ -z "${clusterStack}" ]; then
    clusterStack="HADOOP_HDP2_3"
  fi

  logger "Ensuring SSH credentials are in place"
  create_cbd_credentials 

  logger "Checking whether cluster $1 already exists"
 
  clusterId=$(get_cluster_id "$1")
 
  if [ "${clusterId}" = "" ]; then
    logger "Creating Linux CBD cluster $1, this can take lots of time"
    output=$(create_do_cbd_cluster "$1")

    clusterId=$(awk '/ ID / && NR == 4 {print $4; exit}' <<< "${output}")

    logger "clusterId is $clusterId"

  else
    logger "Cluster $1 exists, checking whether we should resize it"

    output=$(lava clusters get "${clusterId}" -f --header --user "${rackspaceUser}" --tenant "${rackspaceTenant}" --region "${location}" --api-key "${rackspaceApiKey}")
    # get number of nodes

    nodes=$(awk -v vmSize="${vmSize}" '$0 ~ "\\| *slave *\\| *" vmSize " *\\|" { print $6; exit }' <<< "${output}")

    logger "Cluster $1 has $nodes nodes, we want $numberOfNodes"

    if [ "${nodes}" != "${numberOfNodes}" ]; then
      logger "Resizing cluster $1 to $numberOfNodes nodes"
      output=$(resize_do_cbd_cluster "${clusterId}")
    else
      logger "Nothing to do for cluster $1"
    fi
  fi

  if ! wait_cbd_cluster "${clusterId}"; then
    die "Error waiting for cluster $1 to be ready"
  fi
}

# actually creates the cluster
# $1=clusterName
create_do_cbd_cluster(){
  lava clusters create "$1" "${clusterStack}" -f --header --node-groups "slave(flavor_id=${vmSize}, count=${numberOfNodes})" --username "${userAloja}" --ssh-key "${rackspaceSshKeyName}" --user "${rackspaceUser}" --tenant "${rackspaceTenant}" --region "${location}" --api-key "${rackspaceApiKey}"
}

resize_do_cbd_cluster(){
  lava clusters resize "$1" -f --header --node-groups "slave(flavor_id=${vmSize}, count=${numberOfNodes})" --user "${rackspaceUser}" --tenant "${rackspaceTenant}" --region "${location}" --api-key "${rackspaceApiKey}"
}

get_cluster_id(){

  local output clusterId

  output=$(lava clusters list -F --header --user "${rackspaceUser}" --tenant "${rackspaceTenant}" --region "${location}" --api-key "${rackspaceApiKey}")
  clusterId=$(awk -v name="$1" -F, 'NR>1 && $2 == name { id = $1; exit } END { print id"" }' <<< "${output}")
  echo "${clusterId}"
}

create_cbd_credentials(){

  local keys present

  # check if key already present
  keys=$(lava credentials list_ssh_keys -F --header --user "${rackspaceUser}" --tenant "${rackspaceTenant}" --region "${location}" --api-key "${rackspaceApiKey}")

  present=$(awk -v name="${rackspaceSshKeyName}" -F, 'NR>1 && $2 == name { found = 1; exit } END { print found + 0 }' <<< "${keys}")

  if [ $present -eq 1 ]; then
    # update
    logger "Updating ssh key ${rackspaceSshKeyName}"
    lava credentials update_ssh_key "${rackspaceSshKeyName}" "${rackspaceSshKey}" --user "${rackspaceUser}" --tenant "${rackspaceTenant}" --region "${location}" --api-key "${rackspaceApiKey}"
  else
    # create
    logger "Creating ssh key ${rackspaceSshKeyName}"
    lava credentials create_ssh_key "${rackspaceSshKeyName}" "${rackspaceSshKey}" --user "${rackspaceUser}" --tenant "${rackspaceTenant}" --region "${location}" --api-key "${rackspaceApiKey}"
  fi

}

# wait until the cluster is ready
# $1=clusterId
wait_cbd_cluster(){

  local clusterId=$1 output status progress count ok=1 num=10

  while true; do
    output=$(lava clusters get "${clusterId}" -f --header --user "${rackspaceUser}" --tenant "${rackspaceTenant}" --region "${location}" --api-key "${rackspaceApiKey}")

    status=$(awk '/ Status / && NR == 6 {print $4; exit}' <<< "${output}")
    progress=$(awk '/ Progress / && NR == 11 {print $4; exit}' <<< "${output}")

    logger "Status: $status, progress: $progress"

    if [ "${status}" == "ACTIVE" ] && [ "${progress}" = "1.00" ]; then
      logger "Cluster is ready"
      ok=0
      break
    fi

    ((count++))
    if [ $count -gt 500 ]; then
      logger "Timeout waiting for cluster to be ready, terminating"
      break
    fi

    logger "Waiting ${num} seconds..."
    sleep "${num}"

  done

  return $ok

}


# vm_name is the name
# clusterName
get_ssh_host() {

  local clusterId

  clusterId=$(get_cluster_id "${clusterName}")

  # get node data (names, public IPs)
  while IFS=, read -r nodeId nodeName nodeRole nodeStatus nodePuIP nodePrIP; do
    if [ "${nodeName}" = "${vm_name}" ]; then
      echo "${nodePuIP}"
      break
    fi
  done < <(lava nodes list "${clusterId}" -F --header --user "${rackspaceUser}" --tenant "${rackspaceTenant}" --region "${location}" --api-key "${rackspaceApiKey}")
}

#$1 vm_name
number_of_attached_disks() {
  echo "$numberOfDisks"
}

#azure special case for ssh ids
get_vm_ssh_port() {
  echo 22
}

get_master_name() {
    echo "master-1"
}

#$1 cluster name $2 use password
vm_final_bootstrap() {
  logger "Configuring nodes..."
  install_packages "dsh git"
}

