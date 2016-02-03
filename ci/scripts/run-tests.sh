#!/bin/bash -ex

cd git-bits-service

apt-get update
apt-get install zip

bundle install && bundle exec rspec spec
