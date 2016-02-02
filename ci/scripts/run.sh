#!/bin/bash -ex

cd git-bits-service-release

apt-get install wget
wget https://github.com/cloudfoundry-incubator/spiff/releases/download/v1.0.7/spiff_linux_amd64.zip
unzip spiff_linux_amd64.zip
mv spiff /usr/local/bin/

bosh -u x -p x target $BOSH_TARGET Lite
bosh login $BOSH_USERNAME $BOSH_PASSWORD
bosh status

bosh -n delete deployment bits-service
bosh -n delete release bits-service

./scripts/generate-bosh-lite-manifest
rm -rf ../manifest/*

cp deployments/bits-service-release-bosh-lite.yml ../manifest/manifest.yml
cat ../manifest/manifest.yml

rm -rf dev_releases
bosh create release --force --name bits-service --with-tarball
cp dev_releases/bits-service/bits-service-*.tgz ../manifest/

# wget https://s3.amazonaws.com/bosh-warden-stemcells/bosh-stemcell-3147-warden-boshlite-ubuntu-trusty-go_agent.tgz -O ../manifest/bosh-stemcell-3147-warden-boshlite-ubuntu-trusty-go_agent.tgz
