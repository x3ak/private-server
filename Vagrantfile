Vagrant.require_version ">= 2.0.1"

# some basic settings
machineName = ENV['VM_NAME'] || "ansible-builder_NOTSET"
if (machineName == "ansible-builder_NOTSET")
  print "\033[0;31mCan't run command without VM_NAME !\033[0m"
  print "\n"
  print "Please run all 'vagrant' command by prefixing VM_NAME=< name-of-the-vm >.\nLike:\n\t'VM_NAME=ansible-builder_my-playbook' vagrant status\n"
  exit(1)
end

Vagrant.configure('2') do |config|
  config.vm.network "forwarded_port",
    host: 25565,
    guest: 25565,
    auto_correct: true

  config.vm.box = "centos/7"
  config.vm.define machineName

  config.vm.provider "virtualbox" do |vb|
    vb.name = machineName

    # Customize the amount of memory on the VM:
    vb.memory = "1024"
  end

  # Empty content, just to force Vagrant to create configuration file
  # The "vagrantDummyBootstrap.yml" file is a dummy one. We don't want to provision the VM this way,
  # But manually, with the ansible-playbook command from the host.
  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "playbook/vagrantDummyBootstrap.yml"
    ansible.host_key_checking = false
  end
end
