#!/bin/bash

set -e

env

cmd="$@"

until PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_ADDRESS -U $POSTGRES_USERNAME $POSTGRES_DB -c '\q'; do
    >&2 echo "Postgres is unavailable - sleeping"
    sleep 1
done

>&2 echo "Postgres is up - executing command"
exec $cmd
