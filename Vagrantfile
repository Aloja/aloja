#on previous versions it does not download the VM image automatically
Vagrant.require_version ">= 1.6"

VAGRANTFILE_API_VERSION = "2"

#Uncomment below for docker as default provider
#avoids having to $ vagrant up --provider docker
#ENV['VAGRANT_DEFAULT_PROVIDER'] ||= 'docker'

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # default box (aloja-web)
  defaultName = "aloja-web"
  defaultSSHPort = 22200
  defaultIP = "192.168.99.2" #do not use .1 to avoid some vagrant warnings
  sshKeyPath = "../secure/keys_vagrant/id_rsa"

  config.vm.define defaultName, primary: true do |default|
    default.vm.hostname = defaultName

    #Default base image to build from scratch
    #config.vm.box = "ubuntu/trusty64"

    #Prebuilt box for ALOJA
    #config.vm.box = "npoggi/aloja-precise64" #Aloja v1 VM on Ubuntu 12.04
    default.vm.box = "npoggi/aloja-trusty64" #Aloja v2 VM on Ubuntu 14.04

    #for Virtualbox (Default)
    default.vm.provider 'virtualbox' do |v|
      v.name = defaultName

      v.memory = 2048 #change as needed
      v.cpus = 4 #change as needed
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
    default.vm.provision :shell, :path => "aloja-deploy/deploy_node.sh", :args => "aloja-web-vagrant"

    #web document root
    #config.vm.synced_folder "./", "/vagrant"
    default.vm.synced_folder "./aloja-web", "/vagrant/aloja-web", :owner=> 'www-data'
    default.vm.synced_folder "./aloja-web/logs", "/vagrant/aloja-web/logs", :owner=> 'www-data', :mount_options => ["dmode=775", "fmode=664"]
    default.vm.synced_folder "./aloja-web/cache", "/vagrant/aloja-web/cache", :owner=> 'www-data', :mount_options => ["dmode=775", "fmode=664"]

  end

  # cluster nodes for benchmarking (aloja-deploy)
  # start with vagrant up /.*/ or vagrant machine1 machine2

  # Number of nodes to provision (starts at 0)
  numberOfNodes = 1 #2 nodes
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
      node.vm.provision :shell, :path => "aloja-deploy/deploy_cluster.sh", :args => "-n " + nodeName + " vagrant-99"

      node.vm.provider "virtualbox" do |v|
        v.name = "vagrant-99-" + num.to_s.rjust(2, '0')
        v.memory = 1024 #change as needed
        v.cpus = 1 #change as needed
      end
    end
  end


end
