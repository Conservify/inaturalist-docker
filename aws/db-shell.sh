#!/bin/bash

set -xe

echo "Starting ssh-agent..."
eval $(ssh-agent)
trap "ssh-agent -k" exit
ssh-add ~/.ssh/cfy.pem

ssh -t core@inat.aws.fkdev.org "export \$(cat /etc/docker/compose/inat.env | grep -v ^# | xargs); docker run -it --rm postgres psql postgres://\$POSTGRES_USERNAME:\$POSTGRES_PASSWORD@\$POSTGRES_ADDRESS/inaturalist_development?sslmode=disable"
