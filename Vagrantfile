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