#!/bin/bash

pushd ../terraform
export ENV_DB_URL=`terraform output db_url`
export APP_SERVER_ADDRESS=`terraform output app_server_public_ip`
popd
