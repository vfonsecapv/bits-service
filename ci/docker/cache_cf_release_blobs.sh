#!/bin/bash

git clone https://github.com/cloudfoundry/cf-release.git

cd cf-release
git checkout v233
git submodule update --init --recursive

bosh create release --with-tarball

cd ..
rm -rf cf-release
