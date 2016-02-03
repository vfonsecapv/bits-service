#!/bin/bash -ex

cd git-bits-service

apt-get install zip

bundle install && bundle exec rspec spec
