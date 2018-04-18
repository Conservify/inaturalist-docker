#!/bin/bash

export PGPASSWORD=$POSTGRES_PASSWORD

set -xe

export RUBYOPT="-KU -E utf-8:utf-8"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

export PGHOST=$POSTGRES_ADDRESS
export PGUSER=$POSTGRES_USERNAME

which ruby
which psql

if [ ! -f database-ready ]; then
    psql $POSTGRES_URL -f startup.sql

    # Environment variables handle this.
    psql inaturalist_development -f db/structure.sql

    # rake db:setup

    rake es:rebuild

    rails r "Site.create( id: 1000, name: 'iNaturalist', url: 'http://127.0.0.1:3000' )"
    rails r "User.create!( login: 'jacobtest', password: 'asdfasdf', password_confirmation: 'asdfasdf', email: 'jacobtest@test.com', name: 'Jacob' )"
    rails r "User.create!( login: 'shahtest', password: 'asdfasdf', password_confirmation: 'asdfasdf', email: 'shahtest@test.com', name: 'Shah' )"
    rails r tools/import_us_states.rb

    rails r tools/load_sources.rb
    rails r tools/load_iconic_taxa.rb || /bin/true

    # rails r tools/load_dummy_observations.rb

    # These fails with a locale conversion errors.
    # rails r tools/import_natural_earth_countries.rb
    # rails r tools/import_us_counties.rb

    touch database-ready
fi

rails s -b 0.0.0.0
