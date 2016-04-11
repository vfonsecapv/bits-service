# How Bosh-lite was installed
```
# silence is golden
touch ~/.hushlogin

# prereqs
apt-get install git vim unzip

# install or update vagrant manually - the 1.4.x version coming with Ubuntu 14.4
# does not know all options in the bosh-lite config
wget https://releases.hashicorp.com/vagrant/1.8.1/vagrant_1.8.1_x86_64.deb
dpkg -i vagrant_1.8.1_x86_64.deb

apt-get install virtualbox
wget https://s3.amazonaws.com/bosh-warden-stemcells/bosh-stemcell-3147-warden-boshlite-ubuntu-trusty-go_agent.tgz

mkdir -p workspace
git clone https://github.com/cloudfoundry/bosh-lite
cd bosh-lite

vagrant up
bin/add-route

# ruby in ubuntu trusty is old and problematic -> install 2.3
apt-get install software-properties-common
apt-add-repository ppa:brightbox/ruby-ng
apt-get update
apt-get install ruby2.3

# from now on, no more rdoc nor ri
echo 'gem: --no-rdoc --no-ri' >> ~/.gemrc
gem install bundler bosh_cli

wget https://github.com/cloudfoundry-incubator/spiff/releases/download/v1.0.7/spiff_linux_amd64.zip
unzip spiff_linux_amd64.zip
mv spiff /usr/local/bin/
```

# Wire concourse and bosh-lite

```
# concourse:
ip route add 192.168.50.0/24 via 10.155.248.181   # bosh1
ip route add 192.168.100.0/24 via 10.155.248.185  # bosh2
ip route add 10.254.0.0/22 via 10.155.248.181

# bare metal (bosh1):
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
ip route add 10.250.0.0/16 via 192.168.50.4

# bare metal (bosh2):
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
ip route add 10.250.0.0/16 via 192.168.100.4

vagrant ssh  #(into bosh1)
ip route add 10.155.248.0/24 via 192.168.50.1 dev eth1

vagrant ssh  #(into bosh2)
ip route add 10.155.248.0/24 via 192.168.100.1 dev eth1
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
