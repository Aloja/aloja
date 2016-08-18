#on previous versions it does not download the VM image automatically
Vagrant.require_version ">= 1.6"

VAGRANTFILE_API_VERSION = "2"

# defaults for aloja-web
vm_name = "aloja-web"
vm_ssh_port = 22200

# extract relevant values from config files
node_config = "shell/conf/node_aloja-web-vagrant.conf"
IO.foreach(node_config) do |line|

  # skip comments and empty lines
  next if line =~ /^(\s*)(#|$)/

  # strip comments
  line.gsub!(/\s*#.*/, '')

  if line =~ /^\s*vm_name\s*=\s*(.*)/
    vm_name = $1.to_s.strip.gsub(/^['"]|['"]$/, '')
  elsif line =~ /^\s*vm_ssh_port\s*=\s*(.*)/
    vm_ssh_port = $1.to_s.strip.gsub(/^['"]|['"]$/, '')
  end
end

# env overrides
vm_mem = 2048
if ENV['WMEM']
  vm_mem = ENV['WMEM']
end

vm_cpus = 4
if ENV['WCPUS']
  vm_cpus = ENV['WCPUS']
end


# defaults for cluster
numberOfNodes = 1   # starts at 0, really means 2
vmRAM = 4096
vmCPUS = 1

# extract relevant values from config files
cluster_config = "shell/conf/cluster_vagrant-99.conf"
IO.foreach(cluster_config) do |line|

  # skip comments and empty lines
  next if line =~ /^(\s*)(#|$)/

  # strip comments
  line.gsub!(/\s*#.*/, '')

  if line =~ /^\s*numberOfNodes\s*=\s*(.*)/
    numberOfNodes = $1.to_s.strip.gsub(/^['"]|['"]$/, '').to_i
  elsif line =~ /^\s*vmRAM\s*=\s*(.*)/
    vmRAM = $1.to_s.strip.gsub(/^['"]|['"]$/, '').to_i * 1024
  end
end

# env overrides
if ENV['CNODES']
  numberOfNodes = ENV['CNODES'].to_i
end

if ENV['CMEM']
  vmRAM = ENV['CMEM'].to_i
end

if ENV['CCPUS']
  vmCPUS = ENV['CCPUS'].to_i
end


#Uncomment below for docker as default provider
#avoids having to $ vagrant up --provider docker
#ENV['VAGRANT_DEFAULT_PROVIDER'] ||= 'docker'

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # default box (aloja-web)
  defaultName = vm_name
  defaultSSHPort = vm_ssh_port
  defaultIP = "192.168.99.2" #do not use .1 to avoid some vagrant warnings
  sshKeyPath = "../secure/keys_vagrant/id_rsa"

  config.vm.define defaultName, primary: true do |default|
    default.vm.hostname = defaultName
    default.vm.box_check_update = true

    #Default base image to build from scratch
    #default.vm.box = "ubuntu/trusty64"
    #Prebuilt box for ALOJA
    #default.vm.box = "npoggi/aloja-precise64" #Aloja v1 VM on Ubuntu 12.04
    default.vm.box = "npoggi/aloja-trusty64" #Aloja v2.x VM on Ubuntu 14.04
    default.vm.box_version = "2.3" #to force update version

    #for Virtualbox (Default)
    default.vm.provider 'virtualbox' do |v|
      v.name = defaultName

      v.memory = vm_mem   #change as needed
      v.cpus = vm_cpus    #change as needed

      # Force to use hosts DNS
      v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    end

    # #for Docker (optional, but faster on Linux)
    # default.vm.provider 'docker' do |d, override|
    #   override.vm.box = nil #Vagrant gets confused with the Virtualbox name
    #   #use a prebuilt image ie 'npoggi/vagrant-docker:latest'
    #   if ENV['DOCKER_IMAGE'] then
    #     print "Using docker image " + ENV['DOCKER_IMAGE'] + " (downloads if necessary)\n"
    #     d.image = ENV['DOCKER_IMAGE']
    #   else
    #     #build from the Dockerfile
    #     d.build_dir = 'aloja-deploy/providers/'
    #     d.name = 'aloja-vagrant-docker'
    #   end
    #   #the docker image must remain running for SSH (See the Dockerfile)
    #   d.has_ssh = true
    # end

    #used a fixed port, so that we can connect from the deploy scripts
    default.ssh.port = defaultSSHPort
    default.vm.network :forwarded_port, guest: 22, host: defaultSSHPort, id: 'ssh'
    default.ssh.private_key_path = File.expand_path(sshKeyPath, __FILE__)
    default.ssh.insert_key = false #relaxed security

    default.vm.network :private_network, ip: defaultIP

    #net ports
    default.vm.network :forwarded_port, host: 8080, guest: 80 #web
    default.vm.network :forwarded_port, host: 4306, guest: 3306 #mysql
    #default.vm.network :forwarded_port, host: 3307, guest: 3307 #mysql prod

    #use aloja-deploy for provisiong (bash scripts)
    default.vm.provision :shell, :path => "aloja-deploy/deploy_node.sh", :args => "aloja-web-vagrant", :binary => false

    #web document root
    #config.vm.synced_folder "./", "/vagrant"
    default.vm.synced_folder "./aloja-web", "/vagrant/aloja-web", :owner=> 'www-data'
    default.vm.synced_folder "./aloja-web/logs", "/vagrant/aloja-web/logs", :owner=> 'www-data', :mount_options => ["dmode=775", "fmode=664"]
    default.vm.synced_folder "./aloja-web/cache", "/vagrant/aloja-web/cache", :owner=> 'www-data', :mount_options => ["dmode=775", "fmode=664"]

  end

  # cluster nodes for benchmarking (aloja-deploy)
  # start with vagrant up /.*/ or vagrant machine1 machine2

  # Number of nodes to provision (starts at 0)
  ### numberOfNodes = 1 #2 nodes
  # IP Address Base for private network
  ipAddrPrefix = "192.168.99.1"
  # Prefix port for the different VMs
  sshPortPrefix = 22220

  # Provision Config for each of the nodes
  0.upto(numberOfNodes) do |num|

    nodeName = "vagrant-99-0" + num.to_s
    config.vm.define nodeName, autostart: false do |node|
      node.vm.box = "ubuntu/trusty64"
      node.vm.hostname = nodeName
      node.vm.network :private_network, ip: ipAddrPrefix + num.to_s.rjust(2, '0')

      #used a fixed port, so that we can connect from the deploy scripts
      node.ssh.port = sshPortPrefix + num
      node.vm.network :forwarded_port, guest: 22, host: sshPortPrefix + num, id: 'ssh'
      node.ssh.private_key_path = File.expand_path(sshKeyPath, __FILE__)
      node.ssh.insert_key = false #relaxed security

      #use aloja-deploy for provisiong (bash scripts)
      node.vm.provision :shell, :path => "aloja-deploy/deploy_cluster.sh", :args => "-n " + nodeName + " vagrant-99", :binary => false

      node.vm.provider "virtualbox" do |v|
        v.name = "vagrant-99-" + num.to_s.rjust(2, '0')
        v.memory = vmRAM #change as needed
        v.cpus = vmCPUS  #change as needed
        # Force to use hosts DNS
        v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      end
    end
  end
end
