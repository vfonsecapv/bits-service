# How bosh-lite was installed

```
# silence is golden
touch ~/.hushlogin

# prereqs
apt-get install git vim unzip wget

#
# Vagrant
#
wget https://releases.hashicorp.com/vagrant/1.8.1/vagrant_1.8.1_x86_64.deb
dpkg -i vagrant_1.8.1_x86_64.deb

#
# VirtualBox
#

# register the package source
echo 'deb http://download.virtualbox.org/virtualbox/debian vivid contrib' >> /etc/apt/sources.list

# trust the key
wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -

# install
apt-get update
apt-get install virtualbox-5.0

#
# bosh-lite
#

# get the stemcell
wget https://s3.amazonaws.com/bosh-warden-stemcells/bosh-stemcell-3147-warden-boshlite-ubuntu-trusty-go_agent.tgz

# get the latest source
mkdir -p workspace
git clone https://github.com/cloudfoundry/bosh-lite
cd bosh-lite

# start the VM
vagrant up
bin/add-route

#
# Ruby
#
apt-get install software-properties-common
apt-add-repository ppa:brightbox/ruby-ng
apt-get update
apt-get install ruby2.3

# from now on, no more rdoc nor ri
echo 'gem: --no-rdoc --no-ri' >> ~/.gemrc
gem install bundler bosh_cli

#
# spiff
#
wget https://github.com/cloudfoundry-incubator/spiff/releases/download/v1.0.7/spiff_linux_amd64.zip
unzip spiff_linux_amd64.zip
mv spiff /usr/local/bin/
```

# Wire concourse and bosh-lite

## Concourse

### SSH keys

Concourse needs to be able to ssh into the box. Therefore the CI user's public key needs to be added to the `~/.ssh/authorized_keys` file on each bare-metal box, e.g. with `cat flintstone_id_rsa.pub >> ~/.ssh/authorized_keys`.

Regenerate the public key from the private one if necessary:

```
ssh-keygen -t rsa -f ./flintstone_id_rsa  -y > flintstone_id_rsa.pub
```

### IP routing

ssh into the bare-metal box 'concourse' and execute:

```
# bosh1
# access to BOSH director
ip route add 192.168.50.0/24 via 10.155.248.181

# access to bits-service VM
ip route add 10.250.0.0/22 via 10.155.248.181

# bosh2
# access to BOSH director
ip route add 192.168.100.0/24 via 10.155.248.185

# TODO We might need access to bits-service VM from bosh2, too:
# ip route add 10.???.0.0/22 via 10.155.248.185

# acceptance
# access to BOSH director
ip route add 192.168.150.0/24 via 10.155.248.164

# Concourse does NOT need access to bits-service VM on acceptance
```

## bosh1

ssh into the bare-metal box 'bosh1' and execute:

```
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
ip route add 10.250.0.0/16 via 192.168.50.4

cd ~/workspace/bosh-lite
vagrant ssh
ip route add 10.155.248.0/24 via 192.168.50.1 dev eth1
```

## bosh2

ssh into the bare-metal box 'bosh2' and execute:

```
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
ip route add 10.250.0.0/16 via 192.168.100.4

cd ~/workspace/bosh-lite
vagrant ssh
ip route add 10.155.248.0/24 via 192.168.100.1 dev eth1
```

## acceptance

ssh into the bare-metal box 'acceptance' and execute:

```
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
ip route add 10.250.0.0/16 via 192.168.150.4

cd ~/workspace/bosh-lite
vagrant ssh
ip route add 10.155.248.0/24 via 192.168.150.1 dev eth1
```

# Update bosh-lite

In order to update bosh-lite or re-create the vagrant vm do:

```
cd workspace/bosh-lite
vagrant destroy
git pull
vagrant box Update
vim Vagrantfile
```

In the Vagrantfile add the `v.cpus = 7`:

```
Vagrant.configure('2') do |config|
  config.vm.box = 'cloudfoundry/bosh-lite'

  config.vm.provider :virtualbox do |v, override|
    override.vm.box_version = '9000.94.0' # ci:replace
    v.cpus = 7  # <------------------------------------------------- add this line
    # To use a different IP address for the bosh-lite director, uncomment this line:
    # override.vm.network :private_network, ip: '192.168.59.4', id: :local
  end
  ...
```

Start bosh-lite and create our users:

```
vagrant up
bosh create user <user>
```

# Install cf

```
wget --output-document=cf-cli.deb 'https://cli.run.pivotal.io/stable?release=debian64&version=6.15.0&source=github-rel'
dpkg -i cf-cli.deb
```
