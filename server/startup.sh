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

sed -i -e "s,{INAT_API_URL},$INAT_API_URL,g" config/config.yml

HAVE_SITE=$(psql -qtAX -d $POSTGRES_DB -c "SELECT COUNT(*) FROM sites")
if [ $HAVE_SITE == 0 ]; then
    rails r "Site.create!( id: 2000, name: 'iNaturalist', url: 'http://127.0.0.1:3000' )"
    rails r "Site.create!( id: 1000, name: 'iNaturalist', url: 'http://inat.fkdev.org' )"
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

HAVE_APPLICATION=$(psql -qtAX -d $POSTGRES_DB -c "SELECT COUNT(*) FROM oauth_applications")
if [ $HAVE_APPLICATION == 0 ]; then
    rails r "OauthApplication.create!( id: 1, owner_id: 1, owner_type: 'User', name: 'FieldKit', redirect_uri: 'http://local.conservify.org:8000/callback', secret: 'e49f160128d4a5ecfd2a1e425caaea6e2cf597705ac1989734021537b83e2663', uid: 'e222436ff6ab6d514f2d8a64a02fa70b13ee32f3ecc238ad8d37f6880dc387ee', url: '' )"
    psql -d $POSTGRES_DB -c "INSERT INTO oauth_access_tokens (id, resource_owner_id, application_id, token, expires_in, refresh_token, scopes, created_at) VALUES (1, 1, 1, 'd8621e6a0db495a1377fc4dc375024b6340ff413dc0595940d10f86a8cafa534', 86400 * 365, NULL, 'write', now())"
fi

# Any way to avoid this everytime?
rake es:rebuild

# Start delayed jobs.
mkdir -p tmp/pids
./script/delayed_job start

rails s -b 0.0.0.0
