#on previous versions it does not download the VM image automatically
Vagrant.require_version ">= 1.6"

VAGRANTFILE_API_VERSION = "2"

#Uncomment below for docker as default provider
#avoids having to $ vagrant up --provider docker
#ENV['VAGRANT_DEFAULT_PROVIDER'] ||= 'docker'

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  #for Virtualbox (Default)
  config.vm.provider 'virtualbox' do |v|
    v.name = "aloja-web"

    #Default base image to build from scratch
    #config.vm.box = "ubuntu/trusty64"
    #Prebuilt box for ALOJA
    #config.vm.box = "npoggi/aloja-precise64" #Aloja v1 VM on Ubuntu 12.04
    config.vm.box = "npoggi/aloja-trusty64" #Aloja v2 VM on Ubuntu 14.04

    v.memory = 2048 #change as needed
    v.cpus = 2 #change as needed
  end

  #for Docker (optional, but faster on Linux)
  config.vm.provider 'docker' do |d, override|
    override.vm.box = nil #Vagrant gets confused with the Virtualbox name
    #use a prebuilt image ie 'npoggi/vagrant-docker:latest'
    if ENV['DOCKER_IMAGE'] then
      print "Using docker image " + ENV['DOCKER_IMAGE'] + " (downloads if necessary)\n"
      d.image = ENV['DOCKER_IMAGE']
    else
      #build from the Dockerfile
      d.build_dir = 'aloja-deploy/providers/'
      d.name = 'aloja-vagrant-docker'
    end
    #the docker image must remain running for SSH (See the Dockerfile)
    d.has_ssh = true
  end

  #web document root
  #config.vm.synced_folder "./", "/vagrant"
  config.vm.synced_folder "./aloja-web", "/vagrant/aloja-web", :owner=> 'www-data'
  config.vm.synced_folder "./aloja-web/logs", "/vagrant/aloja-web/logs", :owner=> 'www-data', :mount_options => ["dmode=775", "fmode=664"]
  config.vm.synced_folder "./aloja-web/cache", "/vagrant/aloja-web/cache", :owner=> 'www-data', :mount_options => ["dmode=775", "fmode=664"]

  #bash scripts
  #config.vm.provision :shell, :path => "aloja-deploy/providers/vagrant-ubuntu-14-bootstrap.sh"
  config.vm.provision :shell, :path => "aloja-deploy/deploy_node.sh", :args => "vagrant"

  # default box (aloja-web)
  config.vm.define "default", primary: true do |default|
  default.vm.hostname = "aloja-web"

  #net ports
  default.vm.network :forwarded_port, host: 8080, guest: 80 #web
  default.vm.network :forwarded_port, host: 4306, guest: 3306 #mysql
  #default.vm.network :forwarded_port, host: 3307, guest: 3307 #mysql prod

end

#
## cluster nodes for benchmarking (aloja-deploy)
#config.vm.define "vagrant1", autostart: false do |node|
#  node.vm.hostname = "vagrant1"
#  node.vm.network "private_network", ip: "10.42.42.101"
#  node.vm.provision "shell", path: "vagrant/files/vagrant_cluster/provision.sh"
#end
#config.vm.define "vagrant2", autostart: false do |node|
#  node.vm.hostname = "vagrant2"
#  node.vm.network "private_network", ip: "10.42.42.102"
#  node.vm.provision "shell", path: "vagrant/files/vagrant_cluster/provision.sh"
#end

end
