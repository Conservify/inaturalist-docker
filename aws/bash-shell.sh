#!/bin/bash

set -xe

echo "Starting ssh-agent..."
eval $(ssh-agent)
trap "ssh-agent -k" exit
ssh-add ~/.ssh/cfy.pem

ssh core@inat.aws.fkdev.org 
