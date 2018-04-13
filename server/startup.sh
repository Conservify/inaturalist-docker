#!/bin/bash

set -xe

export RUBYOPT="-KU -E utf-8:utf-8"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

if [ ! -f database-ready ]; then
    rake db:setup

    rake es:rebuild

    rails r tools/load_sources.rb
    rails r tools/load_iconic_taxa.rb
    rails r "Site.create( name: 'iNaturalist', url: 'http://127.0.0.1:3000' )"
    rails r tools/import_us_states.rb

    rails r "User.create!( login: 'jacobtest', password: 'asdfasdf', password_confirmation: 'asdfasdf', email: 'jacobtest@test.com', name: 'Jacob' )"
    rails r "User.create!( login: 'shahtest', password: 'asdfasdf', password_confirmation: 'asdfasdf', email: 'shahtest@test.com', name: 'Shah' )"
    rails r tools/load_dummy_observations.rb

    # These fails with a locale conversion errors.
    # rails r tools/import_natural_earth_countries.rb
    # rails r tools/import_us_counties.rb

    touch database-ready
fi

rails s -b 0.0.0.0
