#!/bin/bash


#aws --output "${output}" ec2 describe-key-pairs 
#KEYPAIRS	8d:a5:57:2b:c5:bc:7e:86:c9:ed:3c:de:64:2e:a9:94	aloja
#
#aws ec2 import-key-pair --key-name aloja --public-key-material "$(cat aloja/secure/keys/id_rsa.pub)"
#
#
#[davide@swedishchef Thu Dec 03 16:09:17 ~]$ aws ec2 describe-security-groups
#SECURITYGROUPS	default VPC security group	sg-73f7dc15	default	647922963326	vpc-d8d94ebc
#IPPERMISSIONS	-1
#USERIDGROUPPAIRS	sg-73f7dc15	647922963326
#IPPERMISSIONSEGRESS	-1
#IPRANGES	0.0.0.0/0
#
#
#[davide@swedishchef Thu Dec 03 16:38:21 ~]$ aws ec2 describe-security-groups
#SECURITYGROUPS	default VPC security group	sg-73f7dc15	default	647922963326	vpc-d8d94ebc
#IPPERMISSIONS	-1
#IPRANGES	0.0.0.0/0
#IPPERMISSIONSEGRESS	-1
#IPRANGES	0.0.0.0/0
#
#aws ec2 authorize-security-group-ingress --group-name devenv-sg --protocol tcp --port 22 --cidr 0.0.0.0/0
#

export AWS_ACCESS_KEY_ID="${aws_access_key_id}"
export AWS_SECRET_ACCESS_KEY="${aws_secret_access_key}"
export AWS_DEFAULT_REGION="${awsRegion}"

if [ -z "${AWS_ACCESS_KEY_ID}" ] || [ -z "${AWS_SECRET_ACCESS_KEY}" ] || [ -z "${AWS_DEFAULT_REGION}" ]; then
  logger "WARNING: AWS credentials or default region not set, make sure they are defined in config"
fi


awsAmi="ami-548acf3e"
#awsInstanceType="m3.medium"
awsRootDev="/dev/sda1"
awsSshKeyName=aloja
awsDefaultDiskType=gp2   

# io1 provisioned IOPS (SSD)  best
# gp2 general purpose SSD     2nd best
# standard (magnetic disk)    worst

declare -A dnsName
declare -A instance
declare -A avZone

#Amazon specific functions

cluster_do_pre(){
  aws_check_create_sg
}


# create a security group for the cluster
aws_check_create_sg(){

  local sg

  logger "Checking whether security group ${clusterName} exists"

  sg=$(aws --output text ec2 describe-security-groups --query 'SecurityGroups[?GroupName == `'"${clusterName}"'`].GroupId')

  if [ "${sg}" != "" ]; then
    logger "Security group ${clusterName} already exists"
    return
  fi

  logger "Creating security group for ${clusterName}"
  sg=$(aws ec2 create-security-group --group-name "${clusterName}" --description "Security group for cluster ${clusterName}")

  logger "Adding rules to security group ${sg}"

  aws ec2 authorize-security-group-ingress --group-id "${sg}" --protocol tcp --port 0-65535 --cidr 0.0.0.0/0

}


# $1 vm name
vm_exists() {

  local exists

  logger "Checking if VM $1 exists..."

  exists=$(aws --output text ec2 describe-instances --query 'Reservations[*].Instances[?Tags[?Key == `name` && Value == `'"${1}"'`] && State.Name != `terminated`].[Tags[?Key == `name`].Value]')
  if [ "$exists" = "$1" ]; then
    return 0
  else
    return 1
  fi
}

# $1 vm name, $2 ssh port
vm_create() {

  # create instance and assign name= and clustername= tags to save its name and cluster membership

  local instance_id

  logger "Creating Linux VM $1..."

  instance_id=$(aws --output text ec2 run-instances --image-id "${awsAmi}" --block-device-mappings "[{\"DeviceName\":\"${awsRootDev}\",\"Ebs\":{\"DeleteOnTermination\":false}}]" --security-groups "${clusterName}" --count 1 --instance-type "${vmSize}" --key-name "${awsSshKeyName}" --query 'Instances[0].InstanceId')

  # wait for it to be ready
  logger "Waiting for VM $instance_id to become available"
  while true; do
    instance_status=$(aws --output text ec2 describe-instances --instance-ids "${instance_id}" --query 'Reservations[*].Instances[*].[State.Name]')
    logger "VM ${instance_id} is in ${instance_status} status..."
    if [ "${instance_status}" = "running" ]; then
      break
    fi
    sleep 1
  done

  # set tag
  aws ec2 create-tags --resources "${instance_id}" --tags "Key=name,Value=${1}"
  aws ec2 create-tags --resources "${instance_id}" --tags "Key=clustername,Value=${clusterName}"

}

#Azure uses a different key
get_ssh_key() {
  echo "$ALOJA_SSH_KEY"
}

resolve_name(){

  if [ -z "${dnsName["${1}"]}" ]; then

    # get machine details
    local cacheFileName="amazon_hosts_${clusterName}"
    local hosts="$(cache_get "$cacheFileName" "60")"

    if [ ! "$hosts" ] ; then
      local hosts=$(aws --output text ec2 describe-instances --query 'Reservations[*].Instances[?Tags[?Key == `clustername` && Value == `'"${clusterName}"'`] && State.Name != `terminated`].[PublicDnsName,InstanceId,Placement.AvailabilityZone,Tags[?Key == `name`].Value]' | awk 'NR%2 == 0 { print prev "\t" $0; next } { prev = $0 }')
      [ "$hosts" != "" ] && cache_put "$cacheFileName" "$hosts"
    fi
    # get node data (names, public IPs)
    if [ "$hosts" != "" ]; then
      while read -r publicDns instanceId avz nodeName; do
        dnsName["${nodeName}"]="${publicDns}"
        instance["${nodeName}"]="${instanceId}"
        avZone["${nodeName}"]="${avz}"
      done <<< "$hosts"
    fi
  fi
}

#$1 vm_name
vm_get_status(){
  resolve_name "$1"
  aws --output text ec2 describe-instances --instance-ids "${instance["$1"]}" --query 'Reservations[*].Instances[*].[State.Name]'
}


get_ssh_host() {

  resolve_name "${vm_name}"

  echo "${dnsName[$vm_name]}"

}

get_vm_ssh_port() {
  echo 22
}

get_ssh_port() {
  echo 22
}


# $1 vm name
vm_start() {
  logger "Starting VM $1"
  resolve_name "$1"
  aws ec2 start-instances --instance-ids "${instance["$1"]}" > /dev/null
}

# $1 vm name
vm_reboot() {
  logger "Rebooting VM $1"

  resolve_name "$1"

  aws ec2 stop-instances --instance-ids "${instance["$1"]}" > /dev/null
  aws ec2 start-instances --instance-ids "${instance["$1"]}" > /dev/null
}

#1 $vm_name
node_delete() {
  logger "Deleting node/cluster $1 and its associated attached volumes"

  resolve_name "$1"

  # save volume list to delete them later
  logger "Saving volume list for machine $1 (${instance["$1"]})"
  volumes=$(aws --output text ec2 describe-volumes --filters Name=attachment.instance-id,Values="${instance["$1"]}" --query 'Volumes[*].Attachments[*].VolumeId')

  # terminate instance
  logger "Terminating machine $1 (${instance["$1"]})"
  aws ec2 terminate-instances --instance-ids "${instance["$1"]}" > /dev/null

  # wait for it to go terminated
  count=0
  while true; do 
    instance_status=$(aws --output text ec2 describe-instances --instance-ids "${instance["$1"]}" --query 'Reservations[*].Instances[*].[State.Name]')
    logger "Waiting for machine to terminate ($count), status is $instance_status"
    if [ "$instance_status" = "terminated" ]; then
      break
    fi
    sleep 1
    ((count++))
  done

  # delete volumes
  logger "Deleting volumes for machine $1 (${instance["$1"]})"
  while read volId; do
    logger "Deleting volume $volId"
    aws ec2 delete-volume --volume-id "$volId"
  done <<< "$volumes"

}

#1 $vm_name
node_stop() {
  logger "Stopping vm $1"
  resolve_name "$1"
  aws ec2 stop-instances --instance-ids "${instance["$1"]}" > /dev/null
}

#1 $vm_name
node_start() {
  logger "Starting VM $1"
  resolve_name "$1"
  aws ec2 start-instances --instance-ids "${instance["$1"]}" > /dev/null
}





get_OK_status() {
  echo "running"
}

#$1 vm_name
number_of_attached_disks() {

  local numberOfDisks

  # skip /dev/sda*
  numberOfDisks=$(aws --output text ec2 describe-volumes --filters Name=attachment.instance-id,Values="${instance["$1"]}" --query 'Volumes[*].Attachments[?!starts_with(Device, `/dev/sda`)].Device' | wc -l)
  echo "${numberOfDisks}"
}

#$1 vm_name $2 disk size in MB $3 disk number
vm_attach_new_disk() {

  local volume_id letter lastletter
  local -a letters

  logger " Attaching a new disk #$3 to VM $1 of size ${2}GB"

  resolve_name "$1"

  # find which device we have to use (from f to p)
  last_used_dev=$(aws --output text ec2 describe-volumes --filters Name=attachment.instance-id,Values="${instance["$1"]}" --query 'Volumes[*].Attachments[?!starts_with(Device, `/dev/sda`)].Device' | tail -n 1)

  letters=( ${cloud_drive_letters} )

  if [ "${last_used_dev}" = "" ]; then
    letter=${letters[0]}
  else

    lastletter=${last_used_dev: -1:1}

    for ((i=0; i<= ${#letters[@]}; i++)); do
      if [ "$lastletter" = "${letters[i]}" ]; then
        if [ $i -lt ${#letters[@]} ]; then
          letter=${letters[i+1]}
        else
          logger "Cannot find free disk letter to attach de disk, skipping"
          return 1
        fi
      fi
    done
  fi

  # first, create the volume
  volume_id=$(aws ec2 create-volume --size "${2}" --volume-type "${awsDefaultDiskType}" --availability-zone "${avZone["$1"]}" --query 'VolumeId')

  # wait for the volume to become available
  logger "Waiting for volume $volume_id to become available"
  while true; do
    volstatus=$(aws ec2 describe-volumes --volume-id "${volume_id}" --query 'Volumes[*].State')
    if [ "${volstatus}" = "available" ]; then
      break
    fi
    sleep 1
  done

  # attach the volume to the instance
  aws ec2 attach-volume --volume-id "${volume_id}" --instance-id "${instance["$1"]}" --device "/dev/sd${letter}"

}

vm_final_bootstratp() {
  : #not necessary for Amazon (yet)
}

### cluster functions

cluster_final_boostrap() {

  local hosts_fragment old_vm

  logger "Getting machine/IP list for cluster ${clusterName}"

  hosts_fragment=$(azure vm list -s "$subscriptionID" | awk -v s="^${clusterName}-" '$2 ~ s { print $6, $2 }')

  old_vm=${vm_name}

  for vm_name in $(get_node_names); do  
    logger "Updating /etc/hosts"
    vm_update_template "/etc/hosts" "${hosts_fragment}" "secured_file"
  done

  vm_name=${old_vm}
}

###for executables

#1 $vm_name
node_connect() {
  logger "Connecting to amazon cluster ${clusterName}"
  vm_connect
}


get_extra_fstab() {

  local create_string="/mnt       /scratch/local    none bind 0 0"

  if [ "$clusterName" == "al-29" ] ; then
    vm_execute "mkdir -p /scratch/ssd/1"
    local create_string="$create_string
/mnt       /scratch/ssd/1    none bind,nobootwait 0 0"
  fi

  echo -e "$create_string"
}

# make sure /dev/sdb1 is ext4, not NTFS

get_extra_mount_disks(){

  echo "
if mount | grep -q '/dev/sdb1 on /mnt'; then
  sudo umount /mnt
  sudo mkfs.ext4 /dev/sdb1
  sudo mount /mnt
fi
  "
}

vm_final_bootstrap() {

  logger "Checking if setting a static host file for cluster"
  vm_set_statics_hosts

}

vm_set_statics_hosts() {

  if [ "$clusterName" == "al-26" ] || [ "$clusterName" == "al-29" ] ; then
    logger "WARN: Setting statics hosts file for cluster"
    vm_update_template "/etc/hosts" "$(get_static_hostnames)" "secured_file"
  else
    logger "INFO: no need to set static host file for cluster"
  fi
}

get_static_hostnames() {

#a 'ip addr |grep inet |grep 10.'|sort
  echo -e "
10.32.0.4	al-26-00
10.32.0.5	al-26-01
10.32.0.6	al-26-02
10.32.0.12	al-26-03
10.32.0.13	al-26-04
10.32.0.14	al-26-05
10.32.0.20	al-26-06
10.32.0.21	al-26-07
10.32.0.22	al-26-08

10.32.0.4	al-29-00
10.32.0.5	al-29-01
10.32.0.6	al-29-02
10.32.0.12	al-29-03
10.32.0.13	al-29-04
10.32.0.14	al-29-05
10.32.0.20	al-29-06
10.32.0.21	al-29-07
10.32.0.22	al-29-08
"

}
