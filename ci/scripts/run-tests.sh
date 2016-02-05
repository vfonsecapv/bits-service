#!/bin/bash -ex

cd git-bits-service

bundle install && bundle exec rake spec:all
