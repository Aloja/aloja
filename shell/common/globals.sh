#List of BASH globals used by aloja
#to keep sanity


#Node config
dont_mount_share='' #prevent ~/share to be mounted or created


#Cluster config
clusterID='' #from 03 0 99
clusterName='' #clusterName-clusterID
numberOfNodes='' #starts at 0 (max 99)

nodeNames='' #if defined, names are taken from this list

useProxy='' #weather to use a SSH proxy to conect to the host (or cluster)

#Node config
vmSize='' #Size according to cloud provider

attachedVolumes='0' #0 attached volumes by default
diskSize='1023' #1TB (in Azure format) for default diskSize

queueJobs='' #set to set the queue and add benchmarks to the cluster

#cluster_functions.sh
proxyDetails='' #SSH proxy details