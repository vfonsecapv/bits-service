# How Bosh-lite was installed
```
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

# ruby in ubuntu trusty is old and problematic -> install 2.2
apt-get install software-properties-common
add-apt-repository ppa:brightbox/ruby-ng-experimental
apt-get update
apt-get install ruby2.2

gem install bosh_cli --no-ri --no-rdoc

wget https://github.com/cloudfoundry-incubator/spiff/releases/download/v1.0.7/spiff_linux_amd64.zip
unzip spiff_linux_amd64.zip
mv spiff /usr/local/bin/
```

# Wire concourse and bosh-lite

```
# concourse:
ip route add 192.168.50.0/24 via 10.155.248.181
ip route add 10.254.0.0/24 via 10.155.248.181

# bare metal:
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
ip route add 10.250.0.0/16 via 192.168.50.4

vagrant ssh  #(into bosh lite)
ip route add 10.155.248.0/24 via 192.168.50.1 dev eth1
```
