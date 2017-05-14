CUR_DIR_TMP="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$CUR_DIR_TMP/on-premise.sh"

## Create needed directories
#vm_initial_bootstrap() {
#  local bootstrap_file="${FUNCNAME[0]}"
#  if check_bootstraped "$bootstrap_file" ""; then
#
#    # Create a user for aloja
#    vm_useradd
#
#    # Once the access is created, we don't need this anymore
#    requireRootFirst["$vm_name"]="" #disable root/admin user from this part on
#    needPasswordPre=
#
#    # Check if we should sync keys
#    local test_action="$(vm_execute "[ ! -f $homePrefixAloja/$userAloja/.ssh/id_rsa ] && echo '$testKey'")"
#    if [[ "$test_action" == *"$testKey"* ]] ; then
#      log_INFO "Setting SSH keys"
#      vm_set_ssh "use_password"
#    fi
#
#    # Add sudo permissions as hdfs user
#    vm_sudo_hdfs
#
#    logger "Creating necessary folders for $defaultProvider"
#    vm_execute "sudo mkdir -p /grid/{0..9}/aloja /hadoop/cache/aloja && sudo chown -R $userAloja: /grid/{0..9}/aloja /hadoop/cache/aloja"
#
#    local test_action="$(vm_execute "ls /grid/9/aloja && echo '$testKey'")"
#    if [[ "$test_action" == *"$testKey"* ]] ; then
#      #set the lock
#      #check_bootstraped "$bootstrap_file" "set"
#:
#    else
#      log_WARN "Could not create aloja directories on $vm_name. Test output: $test_action"
#    fi
#  fi
#}



##!/bin/bash
#
#CUR_DIR_TMP="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
#
#vmOSType="Fedora"
#vmOSTypeVersion="4.0"
#
#build_dir='$HOME/share/'"${clusterName}"'/build'
#bin_dir='$HOME/share/'"${clusterName}"'/sw/bin'
#sw_dir='$HOME/share/'"${clusterName}"'/sw'
#
#
## array to cache name to IP mappings
#declare -A nodeIP
#declare -A clusterIDs
#
##$1 cluster name
#create_emr_cluster() {
#
#  :
#
##  local output clusterId nodes
##
##  if [ -z "$CBDlocation" ]; then
##    CBDlocation="IAD"
##  fi
##
##  if [ -z "${CBDclusterStack}" ]; then
##    CBDclusterStack="HADOOP_HDP2_3"
##  fi
##
##  logger "Ensuring SSH credentials are in place for region ${CBDlocation}"
##  create_cbd_ssh_credentials
##
##  if [ "${CBDcloudFilesCredentials}" != "" ]; then
##    logger "Ensuring Cloud files credentials are in place for region ${CBDlocation}"
##    create_cbd_cloudfiles_credentials
##  fi
##
##  logger "Ensuring Ambari credentials are in place for region ${CBDlocation}"
##  create_cbd_ambari_credentials
##
##  logger "Checking whether cluster $1 already exists in region ${CBDlocation}"
##
##  clusterId=$(get_cluster_id "$1")
##
##  if [ "${clusterId}" = "" ]; then
##    logger "Creating Linux CBD cluster $1 in region ${CBDlocation}, this can take lots of time"
##    output=$(create_do_cbd_cluster "$1")
##
##    clusterId=$(awk '/ ID / && NR == 4 {print $4; exit}' <<< "${output}")
##
##    logger "clusterId is $clusterId"
##
##  else
##    logger "Cluster $1 exists, checking whether we should resize it"
##
##    output=$(lava clusters get "${clusterId}" -f --header --user "${OS_USERNAME}" --tenant "${OS_TENANT_NAME}" --region "${CBDlocation}" --api-key "${OS_PASSWORD}")
##    # get number of nodes
##
##    nodes=$(awk -v vmSize="${vmSize}" '$0 ~ "\\| *slave *\\| *" vmSize " *\\|" { print $6; exit }' <<< "${output}")
##
##    logger "Cluster $1 has $nodes nodes, we want $numberOfNodes"
##
##    if [ "${nodes}" != "${numberOfNodes}" ]; then
##      logger "Resizing cluster $1 in region ${CBDlocation} to $numberOfNodes nodes"
##      output=$(resize_do_cbd_cluster "${clusterId}")
##    else
##      logger "Nothing to do for cluster $1"
##    fi
##  fi
##
##  if ! wait_cbd_cluster "${clusterId}"; then
##    die "Error waiting for cluster $1 to be ready"
##  fi
#}
#
#node_delete() {
#    delete_emr_cluster "$1"
#}
#
##$1 cluster name
#delete_emr_cluster() {
#
#  :
#
##  local output clusterId nodes
##
##  if [ -z "$CBDlocation" ]; then
##    CBDlocation="IAD"
##  fi
##
##  logger "Checking whether cluster $1 exists in region ${CBDlocation}"
##  clusterId=$(get_cluster_id "$1")
##
##  if [ "${clusterId}" = "" ]; then
##    die "Cluster does not exist, terminating"
##  else
##    logger "Deleting cluster $1 in region ${CBDlocation}"
##    lava clusters delete --force "${clusterId}" --user "${OS_USERNAME}" --tenant "${OS_TENANT_NAME}" --region "${CBDlocation}" --api-key "${OS_PASSWORD}"
##    if [ $? -eq 0 ]; then
##      logger "Successfully deleted cluster $1 from region ${CBDlocation}"
##    else
##      logger "Error deleting cluster $1 from region ${CBDlocation}, check manually"
##    fi
##  fi
##
##  # invalidate cluster cache
#  local cacheFileName="amazonemr_clusters"
#  cache_delete "$cacheFileName"
#}
#
#
## actually creates the cluster
## $1=clusterName
#create_do_emr_cluster(){
#
#  :
#
##  local cloudFilesCred=
##
##  if [ "${CBDcloudFilesCredentials}" != "" ]; then
##    cloudFilesCred="--credential cloud_files=${CBDcloudFilesCredentials}"
##  fi
##
##  lava clusters create "$1" "${CBDclusterStack}" -f --header --node-groups "slave(flavor_id=${vmSize}, count=${numberOfNodes})" --username "${userAloja}" --ssh-key "${CBDsshKeyName}" --user "${OS_USERNAME}" --tenant "${OS_TENANT_NAME}" --region "${CBDlocation}" --api-key "${OS_PASSWORD}" ${cloudFilesCred}
#}
#
#resize_do_emr_cluster(){
#   :
##  lava clusters resize "$1" -f --header --node-groups "slave(flavor_id=${vmSize}, count=${numberOfNodes})" --user "${OS_USERNAME}" --tenant "${OS_TENANT_NAME}" --region "${CBDlocation}" --api-key "${OS_PASSWORD}"
#}
#
#get_cluster_id(){
#
#  local clusters count=0
#
#  if [ -z "${clusterIDs[$1]}" ]; then
#
#    # get clusters details
#    local cacheFileName="amazonemr_clusters"
#    local clusters="$(cache_get "$cacheFileName" "60")"
#
#    if [ ! "${clusters}" ] ; then
#      local clusters=$(lava clusters list -F --header --user "${OS_USERNAME}" --tenant "${OS_TENANT_NAME}" --region "${CBDlocation}" --api-key "${OS_PASSWORD}")
#      cache_put "$cacheFileName" "${clusters}"
#    fi
#
#    # populate clusterIDs array
#    while IFS=, read -r cID cName cState cStack cDate; do
#      ((count++))
#      [ $count -lt 2 ] && continue
#      clusterIDs["${cName}"]="${cID}"
#    done <<< "$clusters"
#  fi
#
#  echo "${clusterIDs[$clusterName]}"
#
#}
#
##create_cbd_ssh_credentials(){
##
##  local keys present
##
##  # check if key already present
##  keys=$(lava credentials list_ssh_keys -F --header --user "${OS_USERNAME}" --tenant "${OS_TENANT_NAME}" --region "${CBDlocation}" --api-key "${OS_PASSWORD}")
##
##  present=$(awk -v name="${CBDsshKeyName}" -F, 'NR>1 && $2 == name { found = 1; exit } END { print found + 0 }' <<< "${keys}")
##
##  if [ $present -eq 1 ]; then
##    # update
##    logger "Updating ssh key ${CBDsshKeyName}"
##    lava credentials update_ssh_key "${CBDsshKeyName}" "${CBDsshKey}" --user "${OS_USERNAME}" --tenant "${OS_TENANT_NAME}" --region "${CBDlocation}" --api-key "${OS_PASSWORD}"
##  else
##    # create
##    logger "Creating ssh key ${CBDsshKeyName}"
##    lava credentials create_ssh_key "${CBDsshKeyName}" "${CBDsshKey}" --user "${OS_USERNAME}" --tenant "${OS_TENANT_NAME}" --region "${CBDlocation}" --api-key "${OS_PASSWORD}"
##  fi
##
##}
#
##create_cbd_cloudfiles_credentials(){
##
##  local creds present
##
##  # check if key already present
##  creds=$(lava credentials list_cloud_files -F --header --user "${OS_USERNAME}" --tenant "${OS_TENANT_NAME}" --region "${CBDlocation}" --api-key "${OS_PASSWORD}")
##
##  present=$(awk -v name="${CBDcloudFilesCredentials}" -F, 'NR>1 && $2 == name { found = 1; exit } END { print found + 0 }' <<< "${creds}")
##
##  if [ $present -eq 1 ]; then
##    # update
##    logger "Updating cloud files credentials ${CBDcloudFilesCredentials}"
##    lava credentials update_cloud_files "${CBDcloudFilesCredentials}" "${OS_PASSWORD}" --user "${OS_USERNAME}" --tenant "${OS_TENANT_NAME}" --region "${CBDlocation}" --api-key "${OS_PASSWORD}"
##  else
##    # create
##    logger "Creating cloud files credentials ${CBDcloudFilesCredentials} using API key"
##    lava credentials create_cloud_files "${CBDcloudFilesCredentials}" "${OS_PASSWORD}" --user "${OS_USERNAME}" --tenant "${OS_TENANT_NAME}" --region "${CBDlocation}" --api-key "${OS_PASSWORD}"
##  fi
##
##}
#
##create_cbd_ambari_credentials(){
##
##  local creds present
##
##  # check if key already present
##  creds=$(lava credentials list_ambari -F --header --user "${OS_USERNAME}" --tenant "${OS_TENANT_NAME}" --region "${CBDlocation}" --api-key "${OS_PASSWORD}")
##
##  present=$(awk -v name="${CBDambariUser}" -F, 'NR>1 && $2 == name { found = 1; exit } END { print found + 0 }' <<< "${creds}")
##
##  if [ $present -eq 1 ]; then
##    # update
##    logger "Updating ambari credentials for ${CBDambariUser}"
##    lava credentials update_ambari "${CBDambariUser}" --ambari-password "${CBDambariPassword}" --user "${OS_USERNAME}" --tenant "${OS_TENANT_NAME}" --region "${CBDlocation}" --api-key "${OS_PASSWORD}"
##  else
##    # create
##    logger "Creating ambari credentials for ${CBDambariUser}"
##    lava credentials create_ambari "${CBDambariUser}" --ambari-password "${CBDambariPassword}" --user "${OS_USERNAME}" --tenant "${OS_TENANT_NAME}" --region "${CBDlocation}" --api-key "${OS_PASSWORD}"
##  fi
##
##}
#
## wait until the cluster is ready
## $1=clusterId
##wait_cbd_cluster(){
##
##  local clusterId=$1 output status progress count ok=1 num=10
##
##  while true; do
##    output=$(lava clusters get "${clusterId}" -f --header --user "${OS_USERNAME}" --tenant "${OS_TENANT_NAME}" --region "${CBDlocation}" --api-key "${OS_PASSWORD}")
##
##    status=$(awk '/ Status / && NR == 6 {print $4; exit}' <<< "${output}")
##    progress=$(awk '/ Progress / && NR == 11 {print $4; exit}' <<< "${output}")
##
##    logger "Status: $status, progress: $progress"
##
##    if [ "${status}" == "ACTIVE" ] && [ "${progress}" = "1.00" ]; then
##      logger "Cluster is ready"
##      ok=0
##      break
##    fi
##
##    ((count++))
##    if [ $count -gt 500 ]; then
##      logger "Timeout waiting for cluster to be ready, terminating"
##      break
##    fi
##
##    logger "Waiting ${num} seconds..."
##    sleep "${num}"
##
##  done
##
##  return $ok
##
##}
#
#
## vm_name is the name
## clusterName
#get_ssh_host() {
#
#  local -a nodes=( $nodeNames )
#
#  num=${vm_name##*-}
#  num=$(( 10#$num ))
#
#  echo "${nodes[$num]}"
#
#}
#
#
##$1 vm_name
#number_of_attached_disks() {
#  echo "$numberOfDisks"
#}
#
##azure special case for ssh ids
#get_vm_ssh_port() {
#  echo 22
#}
#
#get_master_name() {
#  echo "${clusterName}-00"
#
#}
#
##$1 cluster name $2 use password
#vm_final_bootstrap() {
#  logger "Configuring nodes..."
#
##yum install --enablerepo=epel fuse-sshfs
#
#  old_vm_name=$vm_name
#
#  # from here on we can use the normal vm_execute
#  logger "Installing necessary packages on all machines"
#  for vm_name in $(get_node_names); do
#    logger "${vm_name}..."
#    vm_execute "sudo yum install -y --enablerepo=epel git rsync fuse-sshfs gawk libxml2 wget curl unzip screen bwm-ng;"
#
#    vm_execute "
#sudo mkdir -p /mnt/aloja && sudo chown -R hadoop: /mnt/aloja;
#"
#
#    logger "Mounting disks on ${vm_name}"
#    vm_set_ssh
#    vm_set_dot_files
#    vm_mount_disks              # mounts ~/share on all machines
#
#    if [ "$vm_name" = "$(get_master_name)" ]; then
#
#      if ! vm_build_bwm_ng; then
#        logger "WARNING: Cannot install bwm-ng on $vm_name"
#      fi
#
#      if ! vm_check_install_perfmon; then
#        logger "WARNING: Performance monitor tools not installed and we were unable to install them on $vm_name"
#      fi
#    fi
#  done
#
#  wait
#
#  # restore whatever it was
#  vm_name="$old_vm_name"
#}
#
#
#vm_build_dsh(){
#
#  vm_execute "
#
## download and build dsh for local use (not included in CentOS/RHEL 7)
#
#mkdir -p \"${build_dir}\" || exit 1
#cd \"${build_dir}\" || exit 1
#
## target dir
#mkdir -p '${sw_dir}' || exit 1
#
#tarball1=libdshconfig-0.20.13.tar.gz
#tarball2=dsh-0.25.9.tar.gz
#dir1=\${tarball1%.tar.gz}
#dir2=\${tarball2%.tar.gz}
#
#wget -nv \"http://www.netfort.gr.jp/~dancer/software/downloads/\${tarball1}\" || exit 1
#wget -nv \"http://www.netfort.gr.jp/~dancer/software/downloads/\${tarball2}\" || exit 1
#
#rm -rf -- \"\${dir1}\" \"\${dir2}\" || exit 1
#
## first, build the library
#{ tar -xf \"\${tarball1}\" && rm \"\${tarball1}\"; } || exit 1
#
#cd \"\${dir1}\" || exit 1
#
#./configure --prefix=\"${sw_dir}\" || exit 1
#make || exit 1
#make install || exit 1
#
## now build dsh telling it where the library is
#
#cd \"${build_dir}\" || exit 1
#{ tar -xf \"\${tarball2}\" && rm \"\${tarball2}\"; } || exit 1
#cd \"\${dir2}\" || exit 1
#
#CFLAGS=\"-I${sw_dir}/include\" LDFLAGS=\"-L${sw_dir}/lib\" ./configure --prefix=\"${sw_dir}\" || exit 1
#CFLAGS=\"-I${sw_dir}/include\" LDFLAGS=\"-L${sw_dir}/lib\" make || exit 1
#make install || exit 1
#
## we know that \$HOME/sw/bin is in our path because the deployment configures it
#
#mv \"${bin_dir}\"/{dsh,dsh.bin}
#
## install wrapper to not depend on config file
#
#echo \"
##!/bin/bash
#
#${bin_dir}/dsh.bin -r ssh -F 5 \\\"\\\$@\\\"
#\" > \"${bin_dir}/dsh\" || exit 1
#
#chmod +x \"${bin_dir}/dsh\" || exit 1
#"
#
#}
#
#vm_build_sar(){
#
#  vm_execute "
#
## download and build sysstat for local use (included in CentOS/RHEL 7, but not the right version)
#
#mkdir -p \"${build_dir}\" || exit 1
#cd \"${build_dir}\" || exit 1
#
#tarball=sysstat-11.5.2.tar.bz2
#dir=\${tarball%.tar.bz2}
#
#wget -nv \"http://pagesperso-orange.fr/sebastien.godard/\${tarball}\" || exit 1
#
#rm -rf -- \"\${dir}\" || exit 1
#
#{ tar -xf \"\${tarball}\" && rm \"\${tarball}\"; } || exit 1
#cd \"\${dir}\" || exit 1
#
#./configure || exit 1
#make || exit 1
#
## we know that \$HOME/sw/bin is in our path because the deployment configures it
#
#mkdir -p \"${bin_dir}\" || exit 1
#cp sar \"${bin_dir}\" || exit 1
#
#"
#
#}
#
#vm_build_bwm_ng(){
#
#  if ! vm_is_available bwm-ng; then
#
#    vm_execute "
#
## download and build bwm-ng for local use (not included in CentOS/RHEL 7)
#
#mkdir -p \"${build_dir}\" || exit 1
#cd \"${build_dir}\" || exit 1
#
#tarball=bwm-ng-0.6.1.tar.gz
#dir=\${tarball%.tar.gz}
#
#wget -nv \"http://www.gropp.org/bwm-ng/\${tarball}\" || exit 1
#
#rm -rf -- \"\${dir}\" || exit 1
#
#{ tar -xf \"\${tarball}\" && rm \"\${tarball}\"; } || exit 1
#cd \"\${dir}\" || exit 1
#
#./configure || exit 1
#make || exit 1
#
#mkdir -p \"${bin_dir}\" || exit 1
#cp src/bwm-ng \"${bin_dir}\" || exit 1
#
#"
#  fi
#
#}
#
#
#benchmark_suite_cleanup() {
#  : #Empty
#}
#
## TODO should not be needed
#get_node_names() {
#  local -a nodes=( $nodeNames )
#  printf '%s\n' "${nodes[@]}"
#}
#
## TODO should not be needed
#get_slaves_names() {
#  local -a nodes=( $nodeNames )
#  printf '%s\n' "${nodes[@]:1}"
#}
#
##$1 node name
#get_vm_id() {
#   #nodename: slave-1
#   vmId="$(echo $1 | cut -d- -f2)"
#   #printf "%02d" $vmId
#   # here we get IPs, return last part
#   echo -e "${vmId##*\.}"
#}
