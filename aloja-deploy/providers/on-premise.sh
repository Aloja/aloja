#on-premise specific functions

vm_initial_bootstrap() {

  bootstrap_file="${FUNCNAME[0]}"

  if check_bootstraped "$bootstrap_file" ""; then
    logger "Bootstraping $vm_name "

    logger "Setting SSH keys"
    vm_set_ssh "use_password"

    test_action="$(vm_execute " ls && echo '$testKey'")"

    if [[ "$test_action" == *"$testKey"* ]] ; then
      #set the lock
      check_bootstraped "$bootstrap_file" "set"
    else
      logger "ERROR at $bootstrap_file for $vm_name. Test output: $test_action"
    fi
  else
    logger "$bootstrap_file already configured"
  fi
}

#$1 vm_name
wait_vm_ready() {
  : #not needed
}

wait_vm_ssh_ready() {
  : #not needed
}