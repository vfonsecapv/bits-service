#!/bin/bash

cd $(dirname $0)

# use brew install lastpass-cli
lpass show "Shared-Flintstone"/ci-config --notes > config.yml
ssh_key=$(lpass show "Shared-Flintstone"/Github --notes)
fly -t flintstone set-pipeline -p bits-service -c pipeline.yml -l config.yml -v github-private-key="${ssh_key}"
