#!/bin/bash

set -e

cmd="$@"

until PGPASSWORD=in psql -h postgres -U in inaturalist_development -c '\q'; do
    >&2 echo "Postgres is unavailable - sleeping"
    sleep 1
done

>&2 echo "Postgres is up - executing command"
exec $cmd
