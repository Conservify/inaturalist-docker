#!/bin/bash

set -xe

if [ ! -f database-ready ]; then
    rake db:setup

    rake es:rebuild

    rails r tools/load_sources.rb 
    rails r tools/load_iconic_taxa.rb
    rails r "Site.create( name: 'iNaturalist', url: 'http://127.0.0.1:3000' )"
    rails r tools/import_natural_earth_countries.rb
    rails r tools/import_us_states.rb

    rails r "User.create( login: 'testperson', password: 'test', password_confirmation: 'test', email: 'test@test.com' )"
    # rails r tools/import_natural_earth_countries.rb
    # rails r tools/import_us_states.rb
    # rails r tools/import_us_counties.rb
    # rails r tools/load_dummy_observations.rb

    touch database-ready
fi

rails s -b 0.0.0.0
