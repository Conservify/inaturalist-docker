#!/bin/bash

set -xe

if [ ! -f database-ready ]; then
    rake db:setup

    rails r "User.create( login: 'testerson', password: 'test', password_confirmation: 'test', email: 'test@test.com' )"
    rails r tools/import_natural_earth_countries.rb
    rails r tools/import_us_states.rb
    rails r tools/import_us_counties.rb
    rails r tools/load_dummy_observations.rb

    touch database-ready
fi

rails s
