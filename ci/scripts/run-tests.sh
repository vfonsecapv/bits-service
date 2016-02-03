#!/bin/bash -ex

cd git-bits-service

apt-get update
apt-get -y install zip

bundle install && bundle exec rspec spec
