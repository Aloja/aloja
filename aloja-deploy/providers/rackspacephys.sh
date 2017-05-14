CUR_DIR_TMP="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$CUR_DIR_TMP/on-premise.sh"

# Create needed directories
vm_initial_bootstrap() {
  local bootstrap_file="${FUNCNAME[0]}"
  if check_bootstraped "$bootstrap_file" ""; then

    # Create a user for aloja
    vm_useradd

    # Once the access is created, we don't need this anymore
    requireRootFirst["$vm_name"]="" #disable root/admin user from this part on
    needPasswordPre=

    # Check if we should sync keys
    local test_action="$(vm_execute "[ ! -f $homePrefixAloja/$userAloja/.ssh/id_rsa ] && echo '$testKey'")"
    if [[ "$test_action" == *"$testKey"* ]] ; then
      log_INFO "Setting SSH keys"
      vm_set_ssh "use_password"
    fi

    # Add sudo permissions as hdfs user
    vm_sudo_hdfs

    logger "Creating necessary folders for $defaultProvider"
    vm_execute "sudo mkdir -p /grid/{0..9}/aloja /hadoop/cache/aloja && sudo chown -R $userAloja: /grid/{0..9}/aloja /hadoop/cache/aloja"

    local test_action="$(vm_execute "ls /grid/9/aloja && echo '$testKey'")"
    if [[ "$test_action" == *"$testKey"* ]] ; then
      #set the lock
      #check_bootstraped "$bootstrap_file" "set"
:
    else
      log_WARN "Could not create aloja directories on $vm_name. Test output: $test_action"
    fi
  fi
}