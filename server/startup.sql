DROP DATABASE IF EXISTS template_postgis;
CREATE DATABASE template_postgis;
\c template_postgis
UPDATE pg_database SET datistemplate = TRUE WHERE datname = 'template_postgis';

DROP DATABASE IF EXISTS inaturalist_development;
CREATE DATABASE inaturalist_development;
\c inaturalist_development
CREATE EXTENSION postgis;
CREATE EXTENSION "uuid-ossp";

