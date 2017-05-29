# Common functions for cluster and VM management

# Check that $ALOJA_REPO_PATH is correctly set before starting
[ ! "$ALOJA_REPO_PATH" ] && ALOJA_REPO_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../.."

#source includes
#logger "DEBUG: loading $ALOJA_REPO_PATH/shell/common/provider_functions.sh"
source "$ALOJA_REPO_PATH/shell/common/provider_functions.sh"
#logger "DEBUG: loading $ALOJA_REPO_PATH/shell/common/install_functions.sh"
source "$ALOJA_REPO_PATH/shell/common/install_functions.sh"
#logger "DEBUG: loading $ALOJA_REPO_PATH/shell/common/config_functions.sh"
source "$ALOJA_REPO_PATH/shell/common/config_functions.sh"

#test variables
[ -z "$testKey" ] && { logger "testKey not set! Exiting"; exit 1; }

#global variables
declare -A requireRootFirst

#####################################################################################
# Start functions

#$1 vm_name $2 ssh_port

vm_check_create() {
  #create VM
  if ! vm_exists "$1"  ; then
    vm_create "$1" "$2"
  else
    logger "VM $1 already exists. Skipping creation..."
    logger "Starting VM $1 in case needed"
    vm_start "$1"
  fi
}

#requires $vm_name and $type to be set
vm_create_node() {

  local needSshPw=$1

  # Providers with special create "needs"
  if [ "$defaultProvider" == "hdinsight" ]; then
    vm_name="$clusterName"
    status=$(hdi_cluster_check_create "$clusterName")

    if [ $status -eq 0 ]; then
      create_hdi_cluster "$clusterName"
    fi
    vm_provision
    vm_final_bootstrap "$clusterName"
  elif [ "$defaultProvider" == "rackspacecbd" ]; then
    vm_name="$clusterName"
    create_cbd_cluster "$clusterName"
    vm_final_bootstrap "$clusterName"
#  elif [ "$defaultProvider" == "amazonemr" ]; then
#    vm_name="$clusterName"
#    #create_cbd_cluster "$clusterName"
#    vm_final_bootstrap "$clusterName"
  # Normal Linux case
  elif [ "$vmType" != 'windows' ] ; then
    requireRootFirst["$vm_name"]="true" #for some providers that need root user first it is disabled further on

    #check if machine has been already created or creates it
    vm_create_connect "$vm_name"
    #boostrap and provision VM with base packages in parallel

    if [ -z "$noParallelProvision" ] && [ "$type" != "node" ] ; then
      vm_provision $needSshPw & #in parallel
    else
      vm_provision $needSshPw
    fi
  # Windows
  elif [ "$vmType" == 'windows' ] ; then
    vm_check_create "$vm_name" "$vm_ssh_port"
    wait_vm_ready "$vm_name"
    vm_check_attach_disks "$vm_name"
    [ ! -z "$endpoints" ] && vm_endpoints_create

  else
    logger "ERROR: Invalid VM OS type. Type $type"
    exit 1
  fi
}

#$1 vm_name
vm_create_connect() {

  #test first if machines are accessible via SSH to save time
  if ! vm_exists "${1}" || ! wait_vm_ssh_ready "1" ; then
    vm_check_create "$1" "$vm_ssh_port"
    wait_vm_ready "$1"
    vm_check_attach_disks "$1"

    #wait for ssh to be ready
    wait_vm_ssh_ready

  #make sure the correct number of disks is initialized
  elif (( attachedVolumes > 0 )) && ! vm_test_initiallize_disks ; then
    vm_check_attach_disks "$1"
  fi

  [ ! -z "$endpoints" ] && vm_endpoints_create

}

# by default we install ganglia
must_install_ganglia(){
  echo 1
}

#requires $vm_name and $type to be set
#$1 use password
vm_provision() {
  vm_initial_bootstrap

  requireRootFirst["$vm_name"]="" #disable root/admin user from this part on
  needPasswordPre=

  if [ ! -z $1 ]; then
    vm_set_ssh $1
  else
    vm_set_ssh
  fi

  if [ -z "$noSudo" ] ; then

    vm_install_base_packages

    if [ "$type" == "cluster" ] ; then
      if [ "$(must_install_ganglia)" == "1" ] ; then
        install_ganglia_gmond
        config_ganglia_gmond "$clusterName"
      fi
    fi

    # On PaaS don't touch the disks... at least here
    if [ "$clusterType" != "PaaS" ]; then
      vm_initialize_disks # cluster is in parallel later
    fi

    vm_create_share_master # checks if we need to setup the shared dir on the master first
    vm_mount_disks
    vm_build_required
  else
    logger "WARNING: Skipping package installation and disk mount due to sudo not being present or disabled for VM $vm_name"

    # if running on master node, check if performance monitors are available
    # and if not, install them under ~/share
    if [ "$type" = "cluster" ] && [ "$vm_name" = "$(get_master_name)" ]; then
      if ! vm_check_install_perfmon; then
        logger "WARNING: Performance monitor tools not installed and we were unable to install them on $vm_name"
      fi
    fi
  fi

  vm_set_dot_files &

  [ "$type" == "cluster" ] && vm_set_dsh &

  vm_final_bootstrap

  #logger "Waiting for VM $vm_name deployment"
  #wait $! #wait for the provisioning to be ready

  logger "Provisioning for VM $vm_name ready, finalizing deployment"
  #check if extra commands are specified once VMs are provisioned
  vm_finalize
}

vm_finalize() {
  if [ "$type" == "cluster" ] ; then
      cluster_create_local_conf
  fi

  #extra commands to exectute (if defined)
  [ ! -z "$extraLocalCommands" ] && eval $extraLocalCommands #eval is to support multiple commands
  [ ! -z "$extraRemoteCommands" ] && vm_execute "$extraRemoteCommands"
  [ ! -z "$extraPackages" ] && vm_install_extra_packages

  [ ! -z "$puppet" ] && vm_puppet_apply
}


# Here we have no root access; check whether performance monitor tools
# are available and if not, try to download and build them

vm_check_install_perfmon(){
  logger "Checking whether performance monitor tools are available on $vm_name"

  local ret=0

  # add new tools here
  for tool in dsh sar; do
    if ! vm_is_available "$tool"; then
      logger "WARNING: Trying to build tool '$tool' on $vm_name"
      vm_build_${tool}
      ok=$?
      if [ $ok -ne 0 ] || ! vm_is_available "$tool"; then
        logger "WARNING: cannot build tool $tool on $vm_name"
        ret=1
      fi
    fi
  done

  return ${ret}
}

vm_is_available(){
  local cmd
  local tool=$1
  cmd=$(vm_execute "command -v '${tool}'")
  if [[ "${cmd}" =~ /${tool}$  ]]; then
    return 0
  else
    return 1
  fi
}

# Builds a current version of BASH
vm_build_bash() {
  log_INFO "Building an updated user version of BASH"

  vm_execute "
targetdir=\$HOME/share/$clusterName

mkdir -p \${targetdir}/build || exit 1
cd \${targetdir}/build || exit 1

# target dir
mkdir -p \${targetdir}/sw/bin || exit 1

tarball1='bash-4.4.tar.gz'
dir1=\${tarball1%.tar.gz}

#wget -nv \"http://ftp.gnu.org/gnu/bash/\${tarball1}\" || exit 1
#rm -rf -- \"\${dir1}\" || exit 1

# first, build the library
#{ tar -xf \"\${tarball1}\" && rm \"\${tarball1}\"; } || exit 1

cd \"\${dir1}\" || exit 1

./configure --prefix=\${targetdir}/sw || exit 1
make -j4 || exit 1
make install || exit 1

# we know that \${targetdir}/sw/bin is in our path because the deployment configures it

#mv \${targetdir}/sw/bin/{dsh,dsh.bin}

# install wrapper to not depend on config file

chmod +x \${targetdir}/sw/bin/bash || exit 1
"
}

vm_build_dsh(){
  log_INFO "Building DSH"
  vm_execute "

# download and build dsh for local use

targetdir=\$HOME/share/$clusterName

mkdir -p \${targetdir}/build || exit 1
cd \${targetdir}/build || exit 1

# target dir
mkdir -p \${targetdir}/sw/bin || exit 1

tarball1=libdshconfig-0.20.13.tar.gz
tarball2=dsh-0.25.9.tar.gz
dir1=\${tarball1%.tar.gz}
dir2=\${tarball2%.tar.gz}

wget -nv \"http://www.netfort.gr.jp/~dancer/software/downloads/\${tarball1}\" || exit 1
wget -nv \"http://www.netfort.gr.jp/~dancer/software/downloads/\${tarball2}\" || exit 1

rm -rf -- \"\${dir1}\" \"\${dir2}\" || exit 1

# first, build the library
{ tar -xf \"\${tarball1}\" && rm \"\${tarball1}\"; } || exit 1

cd \"\${dir1}\" || exit 1

./configure --prefix=\${targetdir}/sw || exit 1
make || exit 1
make install || exit 1

# now build dsh telling it where the library is

cd \${targetdir}/build || exit 1
{ tar -xf \"\${tarball2}\" && rm \"\${tarball2}\"; } || exit 1
cd \"\${dir2}\" || exit 1

CFLAGS=\"-I\${targetdir}/sw/include\" LDFLAGS=\"-L\${targetdir}/sw/lib\" ./configure --prefix=\${targetdir}/sw || exit 1
CFLAGS=\"-I\${targetdir}/sw/include\" LDFLAGS=\"-L\${targetdir}/sw/lib\" make || exit 1
make install || exit 1

# we know that \${targetdir}/sw/bin is in our path because the deployment configures it

mv \${targetdir}/sw/bin/{dsh,dsh.bin}

# install wrapper to not depend on config file

echo \"
#!/bin/bash

\${targetdir}/sw/bin/dsh.bin -r ssh -F 5 \\\"\\\$@\\\"
\" > \${targetdir}/sw/bin/dsh || exit 1

chmod +x \${targetdir}/sw/bin/dsh || exit 1
"

}

# Builds specified sysstat version and copies it to bin dir
# $1 path to copy the compiled binaries to (optional)
# $2 sysstat version (optional)
vm_build_sar(){
  local bin_path="${1:-\$HOME/share/sw/bin}"
  local sysstat_version="${2:-11.4.2}"

  log_INFO "Building sysstat version $sysstat_version"
  vm_execute "

targetdir=\$HOME/share/$clusterName

mkdir -p \${targetdir}/build || exit 1
cd \${targetdir}/build || exit 1

tarball=sysstat-$sysstat_version.tar.xz
dir=\${tarball%.tar.xz}

wget -nv \"http://pagesperso-orange.fr/sebastien.godard/\${tarball}\" || exit 1

rm -rf -- \"\${dir}\" || exit 1

{ tar -xf \"\${tarball}\" && rm \"\${tarball}\"; } || exit 1
cd \"\${dir}\" || exit 1

./configure --disable-nls || exit 1
make clean && make || exit 1

# we know that \$targetdir/sw/bin is in our path because the deployment configures it

mkdir -p \${targetdir}/sw/bin || exit 1
cp sar sadc iostat pidstat \${targetdir}/sw/bin || exit 1
"
}

get_node_names() {
  local node_names=''
  if [ ! -z "$nodeNames" ] ; then
    for node in $nodeNames ; do
      node_names+="$node\n"
    done
    node_names="${node_names:0:(-2)}" # strip the last \n
  else #generate them from standard naming
    for vm_id in $(seq -f "%02g" 0 "$numberOfNodes") ; do #pad the sequence with 0s
      if [ ! -z "$node_names" ] ; then
        local node_names="${node_names}\n${clusterName}-${vm_id}"
      else
        local node_names="${clusterName}-${vm_id}"
      fi
    done
  fi

  echo -e "$node_names"
}

#for Infiniband on clusters that support it
get_node_names_IB() {
  #logger "WARN: Special hosts for InfiniBand not defined, using regular hostsnames"
  echo -e "$(get_node_names)"
}

get_slaves_names() {
  local node_names=""
  if [ ! -z "$nodeNames" ] ; then #remove the master
    local node_number=""
    for node_name in $nodeNames ; do
      [[ "$node_number" -gt "1" ]] && node_names+="\n" #add new line, but no to the first or last one
      [[ "$node_number" -gt "0" ]] && node_names+="$node_name"
      local node_number="$((node_number+1))"
    done
  else #generate them from standard naming
    for vm_id in $(seq -f "%02g" 1 "$numberOfNodes") ; do #pad the sequence with 0s
      if [ ! -z "$node_names" ] ; then
        node_names="${node_names}\n${clusterName}-${vm_id}"
      else
        node_names="${clusterName}-${vm_id}"
      fi
    done
  fi
  echo -e "$node_names"
}

get_first_slave() {
  local node_names=""
  local node_number=""

  if [ "$nodeNames" ] ; then #remove the master
    for node_name in $nodeNames ; do
      if (( node_number > 0 )); then
        node_names="$node_name"
        break # only first slave
      fi
      ((node_number++))
    done
  else #generate them from standard naming
    for vm_id in $(seq -f "%02g" 1 "$numberOfNodes") ; do #pad the sequence with 0s
      if (( node_number > 0 )); then
        node_names="$node_name"
        break # only first slave
      fi
      ((node_number++))
    done
  fi
  echo -e "$node_names"
}

# Gets the list of extra nodes to instrument if necessary
get_extra_node_names() {
  local node_names=''
  if [ ! -z "$extraNodeNames" ] ; then
    for extra_node in $extraNodeNames ; do
      node_names+="${extra_node}\n"
    done

    node_names="${node_names:0:(-2)}" #remove trailing \n
  fi

  echo -e "$node_names"
}

# Gets the folder where to store files in the extra servers
get_extra_node_folder() {
  echo -e "$BENCH_EXTRA_LOCAL_DIR/$(get_aloja_dir "$PORT_PREFIX")"
}


#the default SSH host override if necessary i.e. in Azure, Openstack
get_ssh_host() {
 echo "$vm_name"
}

#the default key override if necessary i.e. in Azure
get_ssh_key() {
 echo "$ALOJA_SSH_KEY"
}

#default port, override to change i.e. in Azure
get_ssh_port() {
  local vm_ssh_port_tmp=""

  if [ ! -z "$vm_ssh_port" ] ; then
    local vm_ssh_port_tmp="$vm_ssh_port"
  else
    if [ "$type" == "node" ] ; then
      local vm_ssh_port_tmp="22" #default port when empty or not overwriten
    #for clusters
    else
      local vm_ssh_port_tmp="$(get_vm_ssh_port)" #default port when empty or not overwriten
    fi
  fi

  if [ "$vm_ssh_port_tmp" ] ; then
    echo "$vm_ssh_port_tmp"
  else
    die "ERROR: cannot get SSH port for VM $vm_name"
  fi
}

get_ssh_user() {
  #check if we can change from root user
  if [[ "${requireRootFirst[$vm_name]}" && "${userAlojaPre}" ]] ; then
    #"WARNING: connecting as root"
    echo "${userAlojaPre}"
  else
    echo "${userAloja}"
  fi
}

get_ssh_pass() {
  #check if we can change from root user
  if [[ "${requireRootFirst[$vm_name]}" && "${userAlojaPre}" ]] ; then
    #"WARNING: connecting as root"
    echo "${passwordAlojaPre}"
  else
    echo "${passwordAloja}"
  fi

}

vm_initial_bootstrap() {
  : #not necessary by default
}

check_sudo() {

#  test_action="$(vm_execute " sudo test && echo '$testKey'" 2> /dev/null)"
#  #in case SSH is not yet configured, a welcome message will be appended
#
#  test_action="$(echo "$test_action"|grep "$testKey")"

  if [ -z "$noSudo" ] ; then
    #logger "sudo permission OK"
    return 0
  else
    logger "WARNING: cannot sudo or disabled"
    return 1
  fi
}

#$1 commands to execute $2 set in parallel (&) $3 use password
#$vm_ssh_port must be set before
vm_execute() {

  local sshpass=files/sshpass.sh

  set_shh_proxy

  local sshOptions="-q -o connectTimeout=5 -o StrictHostKeyChecking=no -o ControlMaster=auto -o ControlPath=~/.ssh/%r@%h-%p -o ControlPersist=600 -o GSSAPIAuthentication=no  -o ServerAliveInterval=30 -o ServerAliveCountMax=3"
  local result

  #logger "DEBUG: vm_execute: ssh -i $(get_ssh_key) $(eval echo $sshOptions) -o PasswordAuthentication=no -o $proxyDetails $(get_ssh_user)@$(get_ssh_host) -p $(get_ssh_port)" "" "log to file"

  #Use SSH keys
  if [ -z "$3" ] && [ "${needPasswordPre}" != "1" ]; then
    chmod 0600 $(get_ssh_key)
    #echo to print special chars;
    if [ -z "$2" ] ; then
      echo -e "$1" |ssh -i "$(get_ssh_key)" $(eval echo "$sshOptions") -o PasswordAuthentication=no -o "$proxyDetails" "$(get_ssh_user)"@"$(get_ssh_host)" -p "$(get_ssh_port)"
      result=$?
    else
      echo -e "$1" |ssh -i "$(get_ssh_key)" $(eval echo "$sshOptions") -o PasswordAuthentication=no -o "$proxyDetails" "$(get_ssh_user)"@"$(get_ssh_host)" -p "$(get_ssh_port)" &
      result=$?
    fi
    #chmod 0644 $(get_ssh_key)
  #Use password
  else
    if [ -z "$2" ] ; then
      echo "$1" | "$sshpass" "$(get_ssh_pass)" ssh $(eval echo "$sshOptions") -o "$proxyDetails" "$(get_ssh_user)"@"$(get_ssh_host)" -p "$(get_ssh_port)"
      result=$?
    else
      echo "$1" | "$sshpass" "$(get_ssh_pass)" ssh $(eval echo "$sshOptions") -o "$proxyDetails" "$(get_ssh_user)"@"$(get_ssh_host)" -p "$(get_ssh_port)" &
      result=$?
    fi
  fi
  return ${result}
}

set_shh_proxy() {
  if [ ! -z "$useProxy" ] ; then
    proxyDetails="ProxyCommand=$useProxy"
  else
    proxyDetails="ProxyCommand=none"
  fi

}

#interactive ssh, $1 use password
vm_connect() {

  local sshpass=files/sshpass.sh
  set_shh_proxy

  local sshOptions="-o StrictHostKeyChecking=no -o ControlMaster=auto -o ControlPath=~/.ssh/%r@%h-%p -o ControlPersist=600 -o GSSAPIAuthentication=no  -o ServerAliveInterval=30 -o ServerAliveCountMax=3"

  #Use SSH keys
  if [ -z "$1" ] ; then
    chmod 0600 $(get_ssh_key)
    logger "Connecting to VM $vm_name, with details: ssh -i $(get_ssh_key) $(eval echo "$sshOptions") -o '$proxyDetails' $(get_ssh_user)@$(get_ssh_host) -p $(get_ssh_port)"
    ssh -i "$(get_ssh_key)" $(eval echo "$sshOptions") -o PasswordAuthentication=no -o "$proxyDetails" -t "$(get_ssh_user)"@"$(get_ssh_host)" -p "$(get_ssh_port)"

    if [ "$?" != "0" ] ; then
      logger "WARNING: Falied SSH connecting using keys.  Retuned code: $?"
      failed_ssh_keys="true"
    fi
    #chmod 0644 $(get_ssh_key)
  #Use password
  else
    logger "Connecting to VM $vm_name (using PASS), with details: ssh  $(eval echo "$sshOptions") -o '$proxyDetails' $(get_ssh_user)@$(get_ssh_host) -p $(get_ssh_port)"
    "$sshpass" "$(get_ssh_pass)" ssh $(eval echo "$sshOptions") -o "$proxyDetails" -t "$(get_ssh_user)"@"$(get_ssh_host)" -p "$(get_ssh_port)"
  fi
}

#$1 source files $2 destination $3 extra options $4 use password
vm_local_scp() {

  local sshpass=files/sshpass.sh
  local src="$1"

  log_INFO "SCPing files from: $(eval echo "${src}") to: $(get_ssh_user)@$(get_ssh_host):$2"

  set_shh_proxy

  #Use SSH keys
  if [ -z "$4" ] ; then
    #eval is for parameter expansion
    scp -i "$(get_ssh_key)" -o StrictHostKeyChecking=no -o PasswordAuthentication=no -o "$proxyDetails" -P  "$(get_ssh_port)" $(eval echo "$3") $(eval echo "${src}") "$(get_ssh_user)"@"$(get_ssh_host):$2"
  #Use password
  else
    "$sshpass" "$(get_ssh_pass)" scp -o StrictHostKeyChecking=no -o "$proxyDetails" -P  "$(get_ssh_port)" $(eval echo "$3") $(eval echo "${src}") "$(get_ssh_user)"@"$(get_ssh_host):$2"
  fi
}

# Rsync to a VM
# $1 source files $2 destination $3 extra options
#$vm_ssh_port must be set first
vm_rsync() {
    set_shh_proxy

    logger "INFO: Synching from Local dir: $1 To: $2"
    #eval is for parameter expansion  --progress --copy-links
    log_DEBUG "rsync -avur --partial --force  -e ssh -i $(get_ssh_key) -o StrictHostKeyChecking=no -p $(get_ssh_port) -o '$proxyDetails'  $(eval echo "$3") $(eval echo "$1") $(get_ssh_user)@$(get_ssh_host):$2"
    rsync -avur --partial --force  -e "ssh -i $(get_ssh_key) -o StrictHostKeyChecking=no -p $(get_ssh_port) -o '$proxyDetails' " $(eval echo "$3") $(eval echo "$1") "$(get_ssh_user)"@"$(get_ssh_host):$2"
}

# Rsync from a VM
# $1 source path(s)
# $2 destination host + path
# $3 destination port
# $4 extra SHH options (optional)
# $5 SHH proxy (optional)
# $6 Use a remote/global server instead of current node (optional)
vm_rsync_from() {
    local source="$1"
    local destination="$2"
    local destination_port="$3"
    local extra_options="$4"
    local proxy
    local global_server="$6"

    if [ "$5" ] ; then
      proxy="ProxyCommand=$5"
    else
      proxy="ProxyCommand=none"
    fi

    logger "INFO: Syncing from $(hostname): $source To external: $destination"

    #eval is for parameter expansion
    # -i $(get_ssh_key)
    local cmd="rsync -avur --partial --force  -e 'ssh -o StrictHostKeyChecking=no -p $destination_port -o \"$proxy\"' $(eval echo "$extra_options") $(eval echo "$source") \"$destination\""
    log_DEBUG "$cmd"

    if [[ "$global_server" ]]; then
      # Run command in background to continue execution
      (ssh "${global_server%%:*}" "nohup $cmd") &
    else
      #-i '$CONF_DIR/../../secure/keys/id_rsa'
      rsync -avur --partial --force  -e "ssh  -o StrictHostKeyChecking=no -p $destination_port -o '$proxy' " $(eval echo "$extra_options") $(eval echo "$source") "$destination"
    fi
}

get_master_name() {
  local master_name=''

  if [ ! -z "$nodeNames" ] ; then
    for node in $nodeNames ; do #pad the sequence with 0s
      local master_name="$node"
      break #just return one
    done
  else #generate them from standard naming
    for vm_id in $(seq -f "%02g" 0 "$numberOfNodes") ; do #pad the sequence with 0s
      local master_name="${clusterName}-${vm_id}"
      break #just return one
    done
  fi
  echo "$master_name"
}

#for Infiniband on clusters that support it
get_master_name_IB() {
  #logger "WARN: Special master name for InfiniBand not defined, using regular"
  echo "$(get_master_name)"
}

#overwrite if different in your provider
get_repo_path(){
  echo "$homePrefixAloja/$userAloja/share/"
}

#vm_name must be set, override when needed ie., azure, vagrant,...
get_vm_ssh_port() {
  echo "22"
}

#$1 vm_name
get_vm_id() {
  for vm_id in $(seq -f "%02g" 0 "$numberOfNodes") ; do #pad the sequence with 0s
    local vm_name_tmp="${clusterName}-${vm_id}"
    if [ "$vm_name_tmp" == "$1" ] ; then
      echo "$vm_id"
      break
    fi
  done
}

#requires $create_string to be defined
get_initizalize_disks() {
  if [[ "$attachedVolumes" -gt "12" ]] ; then
    logger "ERROR, function only supports up to 12 volumes"
    exit 1;
  fi

  logger "DEBUG: devicePrefix ${devicePrefix} cloud_drive_letters $cloud_drive_letters  " "" "to_file_"

  local create_string="error=0; echo ' DEBUG: listing devices'; lsblk;"

  num_drives="1"
  for drive_letter in $cloud_drive_letters ; do
    local create_string="$create_string

maxwait=60
waited=0
devok=0

while true; do
  if lsblk | grep -q '${devicePrefix}${drive_letter}'; then
    devok=1
    break
  fi
  echo ' Device ${devicePrefix}${drive_letter} not ready, sleeping 10 secs. '

  ((waited+=10))

  [ \$waited -gt \$maxwait ] && break

  sleep 10
done

if [ \$devok -eq 1 ]; then
  sudo parted -s /dev/${devicePrefix}${drive_letter} -- mklabel gpt mkpart primary 0% 100%;
  sudo mkfs -t ext4 -m 1 -O dir_index,extent,sparse_super -F /dev/${devicePrefix}${drive_letter}1;
else
  echo ' WARNING: device ${devicePrefix}${drive_letter} not ready, skip initialization'
  error=1
fi"
    #break when we have the required number
    [[ "$num_drives" -ge "$attachedVolumes" ]] && break
    num_drives="$((num_drives+1))"
  done

  create_string="$create_string
exit \$error
"

  echo -e "$create_string"
}

get_initizalize_disks_test() {
  create_string="echo ''"
  num_drives="1"
  for drive_letter in $cloud_drive_letters ; do
    create_string="$create_string && lsblk|grep ${devicePrefix}${drive_letter}"
    #break when we have the required number
    [[ "$num_drives" -ge "$attachedVolumes" ]] && break
    num_drives="$((num_drives+1))"
  done
  create_string="$create_string && echo '$testKey'"

  echo "$create_string"
}

# $1 server name (optional)
# $2 mount path (optional)
get_share_location() {

  local server_full_path="${1:-$fileServerFullPathAloja}"
  local mount_path="${2:-$homePrefixAloja/$userAloja/share}"

#  if [ "$cloud_provider" == "pedraforca" ] ; then
#    local fs_mount="$userAloja@minerva.bsc.es:$homePrefixAloja/$userAloja/aloja/ $homePrefixAloja/$userAloja/share fuse.sshfs _netdev,users,IdentityFile=$homePrefixAloja/$userAloja/.ssh/id_rsa,allow_other,nonempty,StrictHostKeyChecking=no,auto_cache,reconnect,workaround=all 0 0"
#  elif [ "$subscriptionID" == "8869e7b1-1d63-4c82-ad1e-a4eace52a8b4" ] && [ "$virtualNetworkName" == "west-europe-net" ] || [ "$cloud_provider" != "azure" ] ; then
#    #internal network
#    local fs_mount="$userAloja@aloja-fs:$homePrefixAloja/$userAloja/share/ $homePrefixAloja/$userAloja/share fuse.sshfs _netdev,users,IdentityFile=$homePrefixAloja/$userAloja/.ssh/id_rsa,allow_other,nonempty,StrictHostKeyChecking=no,auto_cache,reconnect,workaround=all 0 0"
#  else
#    #external network
#    local fs_mount="$userAloja@al-1001.cloudapp.net:$homePrefixAloja/$userAloja/share/ $homePrefixAloja/$userAloja/share fuse.sshfs _netdev,users,IdentityFile=$homePrefixAloja/$userAloja/.ssh/id_rsa,allow_other,nonempty,StrictHostKeyChecking=no,Port=222,auto_cache,reconnect,workaround=all 0 0"
#  fi

  local fs_mount="$server_full_path $mount_path fuse.sshfs _netdev,users,exec,IdentityFile=$homePrefixAloja/$userAloja/.ssh/id_rsa,allow_other,nonempty,StrictHostKeyChecking=no,auto_cache,reconnect,workaround=all,Port=$fileServerPortAloja 0 0"

  echo -e "$fs_mount"
}


# Checks if to mount the shared dir in the master node
is_master_fileserver() {
  if [[ "$dont_mount_share_master" ]]; then
    if [[ "$vm_name" == "$(get_master_name)" ]]; then
      return 0
    elif [[ "$defaultProvider" == "hdinsight" && $(vm_execute "hostname 2> /dev/null") == "$(get_master_name)" ]]; then
      return 0
    else
      return 1
    fi
  else
    return 1
  fi
}

make_fstab(){
  if [[ "$attachedVolumes" -gt "12" ]] ; then
    logger "ERROR, function only supports up to 12 volumes"
    exit 1;
  fi

  local create_string=""

  # Check if should mount the shared home
  if [ ! "$dont_mount_share" ] ; then
    # Check if we use the general one or a one in the master node for this cluster
    if [ ! "$dont_mount_share_master" ] ; then
      create_string="$(get_share_location)"
    else
      # For the Master
      if is_master_fileserver ; then
        create_string="$(get_share_location "" "$homePrefixAloja/$userAloja/share/share-global")"
      # For the rest of the cluster
      else
        create_string="$(get_share_location "$userAloja@$(get_master_name):$homePrefixAloja/$userAloja/share/")"
      fi
    fi
  else
    log_INFO "Not mounting ~/share as requested"
  fi

  # TODO this should be removed in the future (paths have changed)
  if [ "$clusterType" != "PaaS" ]; then
  num_drives="1"
  for drive_letter in $cloud_drive_letters ; do
    local create_string="$create_string
/dev/${devicePrefix}${drive_letter}1       /scratch/attached/$num_drives  auto    defaults,nobootwait,noatime,nodiratime 0       2"
    #break when we have the required number
    [[ "$num_drives" -ge "$attachedVolumes" ]] && break
    num_drives="$((num_drives+1))"
  done
  fi

  local create_string="$create_string
$(get_extra_fstab)"


#sudo chmod 777 /etc/fstab; sudo echo -e '# <file system> <mount point>   <type>  <options>       <dump>  <pass>
#/dev/xvda1	/               ext4    errors=remount-ro,noatime,barrier=0 0       1
##/dev/xvdc1	none            swap    sw              0       0' > /etc/fstab;

  logger "INFO: Updating /etc/fstab template $create_string"
  vm_update_template "/etc/fstab" "$create_string" "secured_file"
}

#requires $create_string to be defined
get_mount_disks() {

  local create_string="
    mkdir -p $homePrefixAloja/$userAloja/share;
    [ '$cloud_drive_letters' ] && sudo mkdir -p /scratch/attached/{1..$attachedVolumes} /scratch/local;
    $(get_extra_mount_disks)
    [[ '$cloud_drive_letters' && -d /scratch ]] &&  sudo chown -R $userAloja: /scratch;
    sudo mount -a;
  "
  echo -e "$create_string"
}

#$1 vm_name
wait_vm_ready() {
  logger "Checking status of VM $1"
  waitStartTime="$(date +%s)"
  for tries in {1..300}; do
    currentStatus="$(vm_get_status "$1")"
    waitElapsedTime="$(( $(date +%s) - waitStartTime ))"
    if [ "$currentStatus" == "$(get_OK_status)" ] ; then
      logger " VM $1 is ready!"
      break
    else
      logger " VM $1 is in $currentStatus status. Waiting for: $waitElapsedTime s. $tries attempt(s)."
    fi

    #sleep 1
  done

}

#"$vm_name" "$vm_ssh_port" must be set before
#1 number of tries
wait_vm_ssh_ready() {

  logger "INFO: Checking SSH status of VM $vm_name: $(get_ssh_user)@$(get_ssh_host):$(get_ssh_port)"

  waitStartTime="$(date +%s)"
  for tries in {1..300}; do

    test_action="$(vm_execute "echo '$testKey'")"

    #in case we get a welcome banner we need to grep
    test_action="$(echo -e "$test_action"|grep "$testKey")"

    waitElapsedTime="$(( $(date +%s) - waitStartTime ))"
    if [ ! -z "$test_action" ] ; then
      logger " VM $vm_name is ready!"
      return 0
      break #just in case
    else
      logger " VM $vm_name is down. Waiting for: $waitElapsedTime s. $tries attempts. Output: $test_action"

      if [ "$tries" == "2" ] ; then
        vm_start "$vm_name"
      elif [ "$tries" == "100" ] ; then
        vm_reboot "$vm_name"
      fi

    fi

    #stop if max number of tries has been specified
    [ ! -z "$1" ] && [[ "$tries" -ge "$1" ]] && break

    sleep 1
  done

  return 1
}

vm_test_initiallize_disks() {

  logger "Checking if the correct number of disks are atttached to VM $vm_name"

  local create_string="$(get_initizalize_disks_test)"

  #TODO check if disks are formated

  test_action="$(vm_execute "$create_string")"
  #in case SSH is not yet configured, a welcome message will be appended

  test_action="$(echo "$test_action"|grep "$testKey")"

  if [ ! -z "$test_action" ] ; then
    logger " disks OK for VM $vm_name"
    return 0
  else
    logger " disks KO for $vm_name Test output: $test_action"
    return 1
  fi
}


#$1 use password based auth
vm_set_ssh() {
  local bootstrap_file="${FUNCNAME[0]}"

  if check_bootstraped "$bootstrap_file" ""; then
    log_INFO "Setting SSH keys to VM $vm_name "

    if [ -z "$1" ] ; then
      local use_password="" #use SSH keys
    else
      local use_password="true" #use password
    fi

    # Useful when the key is not the default "insecure key"
    local pub_key="$(eval echo $ALOJA_SSH_COPY_KEYS |cut -d' ' -f 2|xargs cat)"

    vm_execute "mkdir -p $homePrefixAloja/$userAloja/.ssh/;
               echo -e '${insecureKey}' >> $homePrefixAloja/$userAloja/.ssh/authorized_keys;
               echo -e '${pub_key}' >> $homePrefixAloja/$userAloja/.ssh/authorized_keys;
               " "parallel" "$use_password"

    # Install extra pub keys for login if defined
    [ "$extraPublicKeys" ] && vm_execute "echo -e '${extraPublicKeys}' >> $homePrefixAloja/$userAloja/.ssh/authorized_keys;" "parallel" "$use_password"

    vm_update_template "$homePrefixAloja/$userAloja/.ssh/config" "$(get_ssh_config)" ""

    vm_local_scp "$ALOJA_SSH_COPY_KEYS" "$homePrefixAloja/$userAloja/.ssh/" "" "$use_password"
    vm_execute "chmod -R 0600 $homePrefixAloja/$userAloja/.ssh/*;" "" "$use_password"

    local test_action="$(vm_execute "grep 'UserKnownHostsFile' $homePrefixAloja/$userAloja/.ssh/config && ls $homePrefixAloja/$userAloja/.ssh/id_rsa && echo '$testKey'")"
    #logger "TEST SSH $test_set_ssh"

    if [[ "$test_action" == *"$testKey"* ]] ; then
      #set the lock
      check_bootstraped "$bootstrap_file" "set"
    else
      logger "ERROR setting SSH for $vm_name. Test output: $test_set_ssh"
    fi
  else
    logger "SSH already initialized"
  fi
}

#$1 vm_name
vm_check_attach_disks() {
  #attach required volumes
  if [ ! -z "$attachedVolumes" ] ; then

    logger " getting number of attached disks to VM $1"
    numberOfDisks="$(number_of_attached_disks "$1")"
    logger " $numberOfDisks attached disks to VM $1"

    if [ "$attachedVolumes" -gt "$numberOfDisks" ] 2>/dev/null; then #2>/dev/null avoid integer exp errors
      missingDisks="$(( attachedVolumes - numberOfDisks ))"
      logger " need to attach $missingDisks disk(s) to VM $1"
      for ((disk=0; disk<missingDisks; disk++ )) ; do
        vm_attach_new_disk "$1" "$diskSize" "$disk"
      done
    else
      logger " no need to attach new disks to VM $1"
    fi
  fi
}

#vm_format_disks() {
#  if check_bootstraped "vm_format_disks" "set"; then
#    logger "Formating disks for VM $vm_name "
#
#    vm_execute ";"
#  else
#    logger "Disks initialized"
#  fi
#}


vm_set_dsh() {
  local bootstrap_file="${FUNCNAME[0]}"

  if check_bootstraped "$bootstrap_file" ""; then
    logger "Setting up DSH for VM $vm_name "

    node_names="$(char2char "$(get_node_names)" ' ' '\n')"
    vm_update_template "$homePrefixAloja/$userAloja/.dsh/group/a" "$node_names" ""

    slave_names="$(char2char "$(get_slaves_names)" ' ' '\n')"
    vm_update_template "$homePrefixAloja/$userAloja/.dsh/group/s" "$slave_names" ""

    test_action="$(vm_execute " [ -f $homePrefixAloja/$userAloja/.dsh/group/a ] && echo '$testKey'")"
    if [[ "$test_action" == *"$testKey"* ]] ; then
      #set the lock
      check_bootstraped "$bootstrap_file" "set"
    else
      logger "ERROR setting DSH for $vm_name. Test output: $test_action"
    fi

  else
    logger "DSH already configured"
  fi
}

vm_set_dot_files() {
  local bootstrap_file="${FUNCNAME[0]}"

  if check_bootstraped "$bootstrap_file" ""; then
    logger "Setting up $bootstrap_file for VM $vm_name "

    vm_execute "touch $homePrefixAloja/$userAloja/.hushlogin;" #avoid welcome banners

    if [ "$type" = "cluster" ]; then
      vm_update_template "$homePrefixAloja/$userAloja/.bashrc" "
export HISTSIZE=50000
alias a='dsh -g a -M -c'
alias s='dsh -g s -M -c'
export PATH=\$HOME/share/${clusterName}/sw/bin:\$PATH" ""

    else
      vm_update_template "$homePrefixAloja/$userAloja/.bashrc" "
export HISTSIZE=50000
alias a='dsh -g a -M -c'
alias s='dsh -g s -M -c'
export PATH=\$HOME/share/sw/bin:\$PATH" ""

    fi

    vm_update_template "$homePrefixAloja/$userAloja/.screenrc" "
defscrollback 99999
startup_message off" ""

    test_action="$(vm_execute " [ \"\$\(grep 'dsh -g' $homePrefixAloja/$userAloja/.bashrc\)\" ] && echo '$testKey'")"
    if [[ "$test_action" == *"$testKey"* ]] ; then
      #set the lock
      check_bootstraped "$bootstrap_file" "set"
    else
      logger "ERROR setting $bootstrap_file for $vm_name. Test output: $test_action"
    fi

  else
    logger "$bootstrap_file already configured"
  fi
}

#1 command to execute in master (as a gateway to DSH)
cluster_execute() {
  vm_execute_master "dsh -g a -M -c \"$1\""
}

vm_initialize_disks() {
  if [[ "$attachedVolumes" -gt "0" ]] ; then

    if check_bootstraped "vm_initialize_disks" ""; then
      logger "Initializing disks for VM $vm_name "

      local create_string="$(get_initizalize_disks)"

      vm_execute "$create_string"
      local result=$?

      if [ $result -eq 0 ] ; then
        #set the lock
        check_bootstraped "vm_initialize_disks" "set"
      else
        logger "ERROR: initializing disks for $vm_name. Test output: $test_action"
        #exit 1
      fi

    else
      logger "Disks already initialized for VM $vm_name "
    fi

  else
    logger " no need to attach disks for VM $vm_name"
  fi
}

cluster_initialize_disks() {

  local bootstrap_file="${FUNCNAME[0]}"

  local create_string="$(get_initizalize_disks)"

  cluster_execute "
  if [[ -f $bootstrap_file ]] ; then
    echo 'Disks already initialized';
  else
    echo 'Initializing disks';

    $create_string

    test_action=\"\$(lsblk|grep ${devicePrefix}c1\) ] && echo '$testKey')\"
    if [ \"\$test_action\" == \"$testKey\" ] ; then
      touch $bootstrap_file;
    else
      echo  'ERROR initializing disks for $vm_name. Test output: \$test_action'
    fi
  fi"
}

vm_create_share_master() {
  local bootstrap_file="${FUNCNAME[0]}"
  if is_master_fileserver; then
    if check_bootstraped "$bootstrap_file" ""; then
      logger "INFO: Creating shared dir in: $vm_name"

      vm_make_fs "$master_share_path";

      local test_path="~/share/safe_store"
      [ "$master_share_path" ] && test_path="$master_share_path"

      # Create the global shared dir
      vm_execute "mkdir -p ~/share/share-global"

      local test_action="$(vm_execute "ls $test_path && ls ~/share/share-global && echo '$testKey'")"
      if [[ "$test_action" == *"$testKey"* ]] ; then
        #set the lock
        check_bootstraped "$bootstrap_file" "set"
      else
        logger "ERROR creating shared dir for $vm_name. Test output: $test_action"
      fi
    else
      logger "INFO: Shared dir already created or not master in node"
    fi
  else
    logger "INFO: Using global shared dir (instead of cluster specific)"
  fi
}

vm_mount_disks() {
  local bootstrap_file="${FUNCNAME[0]}"
  if check_bootstraped "$bootstrap_file" ""; then

    make_fstab

    logger "INFO: Mounting disks for VM $vm_name "

    local create_string="$(get_mount_disks)"
    local error

    vm_execute "$create_string"

    #TODO make this test more robust and to test all the mounts
    local test_action="$(vm_execute "lsblk |grep '/scratch/attached' && echo '$testKey'")"
    if (( attachedVolumes < 1 )) || [[ "$test_action" == *"$testKey"* ]] ; then
      #set the lock
      check_bootstraped "$bootstrap_file" "set"
    else
      logger "ERROR mounting disks for $vm_name. Test output: $test_action"
    fi
  else
    logger "Disks already mounted for VM $vm_name "
  fi
}

vm_build_required() {
  local bootstrap_file="${FUNCNAME[0]}"
  if check_bootstraped "$bootstrap_file" ""; then
    if [ "$vm_name" = "$(get_master_name)" ]; then
      log_INFO "Building required packages on master node: $vm_name"

      local bin_path="\$HOME/share/sw/bin"

      # Build sysstat always to have a fix and updated version for aloja
      local required_sysstat_version="11.4.2"
      if [[ "$required_sysstat_version" != "$(vm_execute "sar -V|head -n +1|cut -d ' ' -f3")" ]] ; then
        vm_build_sar "$bin_path"
      fi

      local test_action="$(vm_execute "which dsh && echo '$testKey'")"
      if [[ ! "$test_action" == *"$testKey"* ]] ; then
        vm_build_dsh
      fi

      # Check if to build a more recent bash version
      local minimum_BASH_version="4.2"
      local current_BASH_version="$(vm_execute "bash --version|head -n +1|cut -d ' ' -f4")"
      if [[ "$minimum_BASH_version" != "$(smaller_version "$current_BASH_version" "$minimum_BASH_version")" ]] ; then
        log_INFO "Building DSH, found version $current_BASH_version"
        vm_build_bash
        # Update the version
        current_BASH_version="$(vm_execute "bash --version|head -n +1|cut -d ' ' -f4")"
      fi

      local test_action="$(vm_execute "ls \"$bin_path/sar\" && dsh --version |grep 'Junichi' && echo '$testKey'")"
      if [[ "$test_action" == *"$testKey"* && "$minimum_BASH_version" == "$(smaller_version "$current_BASH_version" "$minimum_BASH_version")" ]] ; then
        #set the lock
        check_bootstraped "$bootstrap_file" "set"
      else
        log_WARN "Could not build sysstat or DSH correctly on $vm_name. Test output: $test_action\nBASH_VERSION=$current_BASH_version"
      fi
    fi
  else
    logger "Builds already performed for $clusterName"
  fi
}

cluster_mount_disks() {

  local bootstrap_file="${FUNCNAME[0]}"

#UUID=8ba50808-9dc7-4d4d-b87a-52c2340ec372	/	 ext4	defaults,discard	0 0
#/dev/sdb1	/mnt	auto	defaults,nobootwait,comment=cloudconfig	0	2

  local create_string="$(get_mount_disks)"

  mounts="$create_string"

  cluster_execute "
  if [[ -f $bootstrap_file ]] ; then
    echo 'Disks already mounted';
  else
    echo 'Mounting disks';
    touch $bootstrap_file;

    $create_string

  fi"
}

#parallel Node config
cluster_parallel_config() {
  if [ "$vmType" != 'windows' ] && [ -z "$dont_mount_share" ] && check_sudo; then

#    logger "Checking if to initilize cluster disks"
#    cluster_initialize_disks
#    logger "Checking if to mount cluster disks"
#    cluster_mount_disks

    cluster_final_boostrap
  else
    logger "Disks initialization and mounting disabled"
  fi
}

#master config to execute benchmarks
cluster_queue_jobs() {
  if [ "$vmType" != 'windows' ] ; then
    vm_set_master_crontab
    vm_set_master_forer
  fi
}

#$1 filename $2 set lock $3 execute on master
check_bootstraped() {

  local bootstrap_filename="bootstrap_${1}_${vm_name}"

  local result

  if [ -z "$3" ] ; then
    fileExists="$(vm_execute "[[ -f $homePrefixAloja/$userAloja/$bootstrap_filename ]] && echo '$testKey'")"
    result=$?
  else
    fileExists="$(vm_execute_master "[[ -f $homePrefixAloja/$userAloja/$bootstrap_filename ]] && echo '$testKey'")"
    result=$?
  fi

  if [ $result -eq 255 ]; then
    die "cannot check bootstrap file status (SSH error?)"
  fi

  #set lock
  if [ ! -z "$2" ] ; then
    vm_execute "touch $homePrefixAloja/$userAloja/$bootstrap_filename;"
  fi

  if [ ! -z "$fileExists" ] && [ "$fileExists" != "$testKey" ] ; then
    logger " Avoiding subsequent welcome banners"
    vm_execute "touch $homePrefixAloja/$userAloja/.hushlogin; " #avoid subsequent banners
    fileExists="$(vm_execute "[[ -f $homePrefixAloja/$userAloja/bootstrap_$1 ]] && echo '$testKey'")"
  fi
#TODO fix return codes should be the opposite
  if [ "$fileExists" == "$testKey" ] ; then
    return 1
  elif [ ! -z "$fileExists" ] ; then
    logger "Error checking bootstrap locks, LOCKING anyhow. Check manually. FileExists=$fileExists"
    return 0
  else
    return 0
  fi
}

#$1 command to execute in master
vm_execute_master() {
  #save current ssh_port and vm_name
  local vm_ssh_port_save="$vm_ssh_port"
  local vm_name_save="$vm_name"

  vm_ssh_port="$(get_vm_ssh_port)"
  vm_name="$(get_master_name)"

  vm_execute "$1"

  #restore port and vm_name
  vm_ssh_port="$vm_ssh_port_save"
  vm_name="$vm_name_save"
}

vm_set_master_crontab() {

  if check_bootstraped "vm_set_master_crontab" "set" "master"; then
    logger "Setting ALOJA crontab to master"

    crontab="# m h  dom mon dow   command
* * * * * export USER=$userAloja && bash $homePrefixAloja/$userAloja/share/shell/exeq.sh $clusterName
#backup data
#0 * * * * cp -ru share/jobs_$clusterName local >> $homePrefixAloja/$userAloja/cron.log 2>&1"

    vm_execute_master "echo '$crontab' |crontab"

  else
    logger "Crontab already installed in master"
  fi
}

#$1 share path
verify_share_cmd() {
  echo -e "[ ! \"\$(ls $1/safe_store )\" ] && { echo 'ERROR: share not mounted correctly, remounting'; sudo umount -f $1; sudo fusermount -uz $1; sudo pkill -9 -f 'sshfs $userAloja@'; sudo mount $1; sudo mount -a; }"

#[[ ! \"\$(mount |grep '$1'| grep 'rw,' )\" || \"\$(touch $1/touch )\" ]] && { echo 'ERROR: $1 not R/W remounting'; sudo umount -f $1; sudo fusermount -uz $1; sudo pkill -9 -f 'sshfs $userAloja@'; sudo mount $1; sudo mount -a; }
}

vm_set_master_forer() {

  if check_bootstraped "vm_set_master_forer" "set" "master"; then

  #logger "INFO: starting queues in background in case dirs are not yet created"
  #vm_execute_master "bash -c \"(nohup export USER=$userAloja && bash $homePrefixAloja/$userAloja/share/shell/exeq.sh $clusterName; touch nohup-exit) > /dev/null &\""

  logger "Checking if queues dirs already setup"
  test_action="$(vm_execute "ls $homePrefixAloja/$userAloja/local/queue_${clusterName}/queue.log && echo '$testKey'")"
  #in case we get a welcome banner we need to grep
  test_action="$(echo -e "$test_action"|grep "$testKey")"

  if [ -z "$test_action" ] ; then
    logger "WARN: queues not ready sleeping for 61s."
    sleep 61
  fi

  logger "Checking if queues already setup"
  test_action="$(vm_execute "ls $homePrefixAloja/$userAloja/local/queue_${clusterName}/conf/counter && echo '$testKey'")"
  #in case we get a welcome banner we need to grep
  test_action="$(echo -e "$test_action"|grep "$testKey")"

  if [ -z "$test_action" ] ; then

    #TODO shouldn't be necessary but...
    logger "DEBUG: Re-mounting disks"
    local verify_share="$(verify_share_cmd "$homePrefixAloja/$userAloja/share")"

    cluster_execute "$verify_share"

    logger "Generating jobs (forer)"

    if [ -f "$ALOJA_REPO_PATH/shell/forer_$clusterName.sh" ] ; then
      logger " synching forer files"
      vm_rsync "$ALOJA_REPO_PATH/shell/" "$homePrefixAloja/$userAloja/share/shell/"

      logger " executing forer_$clusterName.sh"
      vm_execute_master "bash $homePrefixAloja/$userAloja/share/shell/forer_$clusterName.sh $clusterName"
    else
      logger " executing forer_az.sh $ALOJA_REPO_PATH/shell/forer_$clusterName.sh"
      vm_execute_master "bash $homePrefixAloja/$userAloja/share/shell/forer_az.sh $clusterName"
    fi

  else
    logger " queues already setup"
  fi

  else
    logger "Jobs already generated and queued"
  fi
}

#Puppet apply
vm_puppet_apply() {

  logger "Transfering puppet to VM"
  vm_rsync "$puppet" "$homePrefixAloja/$userAloja/" ""
  logger "Puppet install modules and apply"

	vm_execute "cd $(basename $puppet) && sudo bash -c './$puppetBootFile'"
	if [ ! -z "$puppetPostScript" ]; then
	 vm_execute "cd $(basename $puppet) && sudo bash -c './$puppetPostScript'"
	fi
}

#Initialized the shared file system
#$1 share location
vm_make_fs() {

  if [ -z "$1" ] ; then
    local share_disk_path="/scratch/attached/1"
  else
    local share_disk_path="$1"
  fi

  logger "INFO: Initializing the shared file system for VM $vm_name at $share_disk_path"

  if [ -z "$homeIsShared" ] ; then
    logger "Checking if $homePrefixAloja/$userAloja/share is correctly linked"
    test_action="$(vm_execute "[ -d $homePrefixAloja/$userAloja/share ] && [ -L $homePrefixAloja/$userAloja/share ] && ls $homePrefixAloja/$userAloja/share/safe_store && echo '$testKey'")"
    #in case we get a welcome banner we need to grep
    test_action="$(echo -e "$test_action"|grep "$testKey")"

    if [ -z "$test_action" ] ; then

      #if the folder is different to ~/share, then link it to ~/share
      if [ "$share_disk_path" != "$homePrefixAloja/$userAloja/share" ] ; then
        logger " Linking $homePrefixAloja/$userAloja/share to $share_disk_path"

        vm_execute "

sudo mkdir -p '$share_disk_path'
sudo chown -R ${userAloja}: $share_disk_path;
[ -d $homePrefixAloja/$userAloja/share ] && [ ! -L $homePrefixAloja/$userAloja/share ] && mv $homePrefixAloja/$userAloja/share $homePrefixAloja/$userAloja/share_backup && echo 'WARNING: share dir moved to ~/share_backup';
ln -sf $share_disk_path $homePrefixAloja/$userAloja/share;"
      else
        #make sure the dir is created
        vm_execute "mkdir -p $share_disk_path"

      fi

      #make it officially a shared disk
      vm_execute "touch $homePrefixAloja/$userAloja/share/safe_store;"

    else
      logger " $homePrefixAloja/$userAloja/share is correctly mounted"
    fi

  else
    logger "NOTICE: /home is marked as shared, creating the dir if necessary"
    vm_execute "mkdir -p $homePrefixAloja/$userAloja/share; touch $homePrefixAloja/$userAloja/share/safe_store"
  fi

  vm_rsync "../shell ../aloja-deploy ../aloja-tools ../aloja-bench ../config"  "$homePrefixAloja/$userAloja/share"
  vm_rsync "../secure" "$homePrefixAloja/$userAloja/share/" "--copy-links"
  #vm_rsync "../blobs/aplic2/configs" "$homePrefixAloja/$userAloja/share/aplic2/" "--copy-links"

# Uncomment to sync deprecated aplic dir
#  logger "Checking if aplic exits to redownload or rsync for changes"
#  test_action="$(vm_execute "ls $homePrefixAloja/$userAloja/share/aplic/aplic_version && echo '$testKey'")"
#  #in case we get a welcome banner we need to grep
#  test_action="$(echo -e "$test_action"|grep "$testKey")"
#
#  if [ -z "$test_action" ] ; then
#    logger "Downloading aplic"
#    aloja_wget "$ALOJA_PUBLIC_HTTP/aplic.tar.bz2" "$homePrefixAloja/$userAloja/share/aplic.tar.bz2"
#
#    logger "Uncompressing aplic"
#    vm_execute "cd $homePrefixAloja/$userAloja/share; tar -jxf aplic.tar.bz2"
#  fi
#
#  logger "RSynching aplic for possible updates"
#  vm_rsync "../blobs/aplic" "$homePrefixAloja/$userAloja/share" "--copy-links"
}

#[$1 share location]
vm_rsync_public() {

  if [ -z "$1" ] ; then
    local share_disk_path="/scratch/attached/1/public"
  else
    local share_disk_path="$1"
  fi

  logger "INFO: rsynching the Web /public dir for VM $vm_name at $share_disk_path"

  if [ -d "$ALOJA_REPO_PATH/blobs" ] ; then
    vm_rsync "$ALOJA_REPO_PATH/blobs/{aplic2,boxes,DB_dumps,files}" "$share_disk_path/" "--copy-links"
  else
    logger "WARNING: blobs dir does not exists, not synching. DEBUG: path $ALOJA_REPO_PATH/blobs"
  fi
}

#$1 filename
vm_get_file_contents() {
  if [ "$1" ] ; then
    local fileContent="$(vm_execute " [ -f '$1' ] && cat '$1'")"
  else
    : #error
  fi

  echo -e "$fileContent"
}

#$1 filename $2 contents $3 change permissions
vm_put_file_contents() {

  if [ "$1" ] && [ "$2" ] ; then
    if [ "$3" ] ; then
      local command="
sudo chmod 777 $1 2> /dev/null;
sudo touch $1;
sudo cp $1 ${1}.$(date +%s).bak 2> /dev/null;
cat << 'EOF' > $1
$2
EOF

sudo chmod 644 $1"

    else
      local command="
touch $1;
cp $1 ${1}.$(date +%s).bak 2> /dev/null;
cat << 'EOF' > $1
$2
EOF
"

    fi

    vm_execute "$command"

  else
    : #error
  fi
}

#$1 filename on remote machine $2 template part content $3 change permissions
vm_update_template() {

  if [ "$3" ] ; then
    local use_sudo="sudo"
  else
    local use_sudo=""
  fi

  #logger "DEBUG: TEMPLATE getting $1 contents"
  local fileCurrentContent="$(vm_get_file_contents "$1")"

  #if file doesn't exists, is possible that the main dir does not exist either
  if [ ! "$fileCurrentContent" ] ; then
    logger "WARNING: atempting to create directory: $(dirname "$1") for $1"
    vm_execute "$use_sudo mkdir -p $(dirname "$1")"
  fi

  #logger "DEBUG: TEMPLATE $1 GOT contents"
  local fileNewContent="$(template_update_stream "$fileCurrentContent" "$2")"
  #logger "DEBUG: TEMPLATE GOT NEW contents"
  vm_put_file_contents "$1" "$fileNewContent" "$3"
  #logger "DEBUG: TEMPLATE UPDATED $1 with template"
}

#$1 filename on remote machine $2 template part content $3 change permissions
vm_update_host_template() {

  #logger "DEBUG: TEMPLATE getting $1 contents"
  local fileCurrentContent="$(vm_get_file_contents "$1")"

  #remove the same machine
  local fileCurrentContent="$(echo -e "$fileCurrentContent" |grep -v "$vm_name")"

  #logger "DEBUG: TEMPLATE $1 GOT contents"
  local fileNewContent="$(template_update_stream "$fileCurrentContent" "$2")"
  #logger "DEBUG: TEMPLATE GOT NEW contents"
  vm_put_file_contents "$1" "$fileNewContent" "$3"
  #logger "DEBUG: TEMPLATE UPDATED $1 with template"
}

#override if necessary ie., openstack
make_hosts_file() {
  local hosts_file=""
  echo -e "$hosts_file"
}

#updates /etc/hosts if called
vm_update_hosts_file() {
  logger "Getting list of hostnames for hosts file for VM $vm_name"
  #local hosts_file_command="$(make_hosts_file_command)"
  local hosts_file="$(make_hosts_file)"

  #remove the same machine
  #local hosts_file="$(echo -e "$hosts_file" |grep -v "$vm_name")"

  logger "Updating hosts file for VM $vm_name"
  #logger "DEBUG: $hosts_file $hosts_file_command"

  #vm_execute "$hosts_file_command"
  vm_update_host_template "/etc/hosts" "$hosts_file" "secured_file"
}

cluster_create_local_conf() {
  logger "INFO: Creating or updating local cluster config file"
  local cluster_conf="
# Cluster config, file is to be sourced by benchmarking scripts
clusterID='$clusterID'
clusterName='$clusterName'
numberOfNodes='$numberOfNodes'
"
  vm_update_host_template "$homePrefixAloja/$userAloja/aloja_cluster.conf" "$cluster_conf"
}

# Creates a user for ALOJA if needed
vm_useradd() {
  local bootstrap_file="${FUNCNAME[0]}"

  if check_bootstraped "$bootstrap_file" ""; then
    log_INFO "Creating user $userAloja in node $vm_name "

    vm_execute "
sudo useradd --create-home --home-dir $homePrefixAloja/$userAloja --shell /bin/bash $userAloja;
sudo echo -n '$userAloja:$passwordAloja' |sudo chpasswd;
sudo usermod -G sudo,adm,wheel $userAloja;

sudo bash -c \"echo '$userAloja ALL=NOPASSWD:ALL' >> /etc/sudoers\";

sudo mkdir -p $homePrefixAloja/$userAloja/.ssh;
sudo bash -c \"echo '${insecureKey}' >> $homePrefixAloja/$userAloja/.ssh/authorized_keys\";
sudo chown -R $userAloja: $homePrefixAloja/$userAloja/.ssh;
"
#sudo cp $homePrefixAloja/$userAloja/.profile $homePrefixAloja/$userAloja/.bashrc /root/;


    local test_action="$(vm_execute " [ -f $homePrefixAloja/$userAloja/.ssh/authorized_keys ] && echo '$testKey'")"
    if [[ "$test_action" == *"$testKey"* ]] ; then
      #set the lock
      check_bootstraped "$bootstrap_file" "set"
    else
      logger "ERROR: installing base packages for $vm_name. Test output: $test_action"
    fi
  else
    logger "$bootstrap_file already initialized"
  fi
}

# Sets sudo permissions without password for HDP/Rackspace
vm_sudo_hdfs() {
  local bootstrap_file="${FUNCNAME[0]}"

  if check_bootstraped "$bootstrap_file" ""; then
    log_INFO "Running $bootstrap_file in node $vm_name "

    vm_execute "sudo bash -c \"echo '$userAloja ALL=(hdfs)NOPASSWD:ALL' >> /etc/sudoers\";"

    local test_action="$(vm_execute " sudo grep 'ALL=(hdfs)' /etc/sudoers && echo '$testKey'")"
    if [[ "$test_action" == *"$testKey"* ]] ; then
      #set the lock
      check_bootstraped "$bootstrap_file" "set"
    else
      logger "ERROR: running $bootstrap_file  for $vm_name. Test output: $test_action"
    fi
  else
    logger "$bootstrap_file already initialized"
  fi
}