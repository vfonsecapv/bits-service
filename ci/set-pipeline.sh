#!/bin/bash

# use brew install lastpass-cli
lpass show "Shared-Flintstone"/ci-config --notes > config.yml
fly -t flintstone set-pipeline -p bits-service -c pipeline.yml -l config.yml
