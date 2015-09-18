CUR_DIR_TMP="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CUR_DIR_TMP/openstack.sh"

#$1 cluster name
vm_final_bootstrap() {
 logger "Configuring nodes.."
 vm_name=$(echo $nodeNames | cut --delimiter " " --fields 1)
 vm_set_ssh
 make_fstab
# vm_execute "cp /etc/hadoop/conf/slaves slaves; cp slaves machines && echo master-1 >> machines"
 vm_execute "sudo yum -y -q install pdsh pssh git"
 vm_execute "pscp.pssh -h slaves .ssh/{config,id_rsa,id_rsa.pub} /home/pristine/.ssh/"
 vm_execute "dsh -M -f machines -Mc -- sudo yum -y -q install bwm-ng sshfs sysstat ntp"
 vm_execute "dsh -f machines -Mc -- 'mkdir -p share'"
 vm_execute "dsh -f slaves -cM -- echo \"'\`cat /etc/fstab | grep 162.209.77.102\`' | sudo tee -a /etc/fstab > /dev/null\""
 vm_execute "dsh -f machines -cM -- sudo mount -a"
#vm_execute "dsh -f slaves -cM -- \"sshfs 'pristine@aloja.cloudapp.net:/home/pristine/share' '/home/pristine/share'\""
# vm_execute "cd share; git clone https://github.com/Aloja/aloja.git ."
# vm_execute "dsh -f slaves -cM -- \"sudo echo $(hostname -i) headnode0 | sudo tee --append /etc/hosts > /dev/null\""
 vm_execute "cp /usr/hdp/current/hadoop-mapreduce-client/hadoop-mapreduce-examples.jar ."
 vm_execute "dsh -M -f machines -Mc -- 'sudo chmod 775 /data1'"
 vm_execute "dsh -M -f machines -Mc -- 'sudo chown root.pristine /data1'"
 vm_execute "sudo su hdfs -c \"hdfs dfs -mkdir /HiBench\""
 ##Initiate hosts files
 vm_execute "dsh -f slaves -- cat /etc/hosts >> hosts.tmp"
 vm_execute "cat hosts.tmp | cut -d: -f2 |  sed -e 's/^[ \t]*//' | sudo tee -a /etc/hosts"
 vm_execute "dsh -f slaves -cM -- \"echo '\`cat /etc/hosts\`' | sudo tee -a /etc/hosts\""
 vm_execute "pscp.pssh -r -h slaves sysstat-10.0.3/ /home/pristine"
 vm_execute "dsh -f slaves -cM -- 'cd sysstat-10.0.3 && sudo make install'"
 vm_execute "sudo yum install -y -q screen"
# vm_execute "sudo su hdfs -c \"hdfs dfs -chown pristine /HiBench\""
# vm_execute "sudo su hdfs -c \"hdfs dfs -chmod 1777 /mr-history\""
}

get_slaves_names() {
    local nodes=$numberOfNodes
    local node_names
    for i in `seq 1 $nodes` ; do
        node_names="${node_names}\nslave-${i}.local"
    done
    echo -e "$node_names"
}

get_node_names() {
    local nodes=$numberOfNodes
    local node_names
    for i in `seq 1 $nodes` ; do
        node_names="${node_names}\nslave-${i}.local"
    done
    node_names="${node_names}\nmaster-1.local"
    echo -e "$node_names"
}

#$1 node_name, expects workernode{id}
get_vm_id() {
    local id="$(echo "$1" | grep -oP "[0-9]+"|tail -n 1)"
    printf %02d "$id"
}

