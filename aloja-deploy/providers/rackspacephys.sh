#!/bin/bash

# Don't touch disks
cloud_drive_letters="" # don't touch the disks
vm_initialize_disks() {
  log_DEBUG "No neeed to ${FUNCNAME[0]##*vm_} for $defaultProvider"
}

## Don't touch SSH config either
#vm_set_ssh() {
#  log_DEBUG "No neeed to ${FUNCNAME[0]##*vm_} for $defaultProvider"
#}

# Avoid installing ganglia
must_install_ganglia(){
  echo ""
}

# Create needed directories
vm_initial_bootstrap() {
  local bootstrap_file="${FUNCNAME[0]}"
  if check_bootstraped "$bootstrap_file" ""; then

    vm_execute "sudo mkdir -p /grid/{0..9}/aloja /hadoop/cache/aloja && sudo chown -R rack: /grid/{0..9}/aloja /hadoop/cache/aloja"

    local test_action="$(vm_execute "ls /grid/9/aloja && echo '$testKey'")"
    if [[ "$test_action" == *"$testKey"* ]] ; then
      #set the lock
      check_bootstraped "$bootstrap_file" "set"
    else
      log_WARN "Could not create aloja directories on $vm_name. Test output: $test_action"
    fi
  fi
}