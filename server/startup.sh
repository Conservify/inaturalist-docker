#!/bin/bash

export RUBYOPT="-KU -E utf-8:utf-8"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

export PGHOST=$POSTGRES_ADDRESS
export PGUSER=$POSTGRES_USERNAME
export PGPASSWORD=$POSTGRES_PASSWORD

which ruby
which psql

until psql -h $POSTGRES_ADDRESS -U $POSTGRES_USERNAME $POSTGRES_MASTER_DB -c '\q'; do
    >&2 echo "Postgres is unavailable - sleeping"
    sleep 1
done

env

set -xe

HAVE_DB=$(psql -qtAX -d $POSTGRES_MASTER_DB -c "SELECT COUNT(*) FROM pg_database WHERE datname = '$POSTGRES_DB'")
if [ $HAVE_DB == 0 ]; then
    psql $POSTGRES_MASTER_DB -f startup.sql
fi

HAVE_TABLES=$(psql -qtAX -d $POSTGRES_DB -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'sites'")
if [ $HAVE_TABLES == 0 ]; then
    # Environment variables handle this. 
    psql inaturalist_development -f db/structure.sql
fi

HAVE_SITE=$(psql -qtAX -d $POSTGRES_DB -c "SELECT COUNT(*) FROM sites")
if [ $HAVE_SITE == 0 ]; then
    rails r "Site.create!( id: 2000, name: 'iNaturalist', url: 'http://127.0.0.1:3000' )"
    rails r "Site.create!( id: 1000, name: 'iNaturalist', url: 'http://inat.aws.fkdev.org' )"
    rails r "User.create!( login: 'jacobtest', password: 'asdfasdf', password_confirmation: 'asdfasdf', email: 'jacobtest@test.com', name: 'Jacob' )"
    rails r "User.create!( login: 'shahtest', password: 'asdfasdf', password_confirmation: 'asdfasdf', email: 'shahtest@test.com', name: 'Shah' )"
    rails r tools/import_us_states.rb

    rails r tools/load_sources.rb
    rails r tools/load_iconic_taxa.rb || /bin/true

    # rails r tools/load_dummy_observations.rb

    # These fails with a locale conversion errors.
    # rails r tools/import_natural_earth_countries.rb
    # rails r tools/import_us_counties.rb
fi

# Any way to avoid this everytime?
rake es:rebuild

rails s -b 0.0.0.0
