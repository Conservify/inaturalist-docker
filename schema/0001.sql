CREATE EXTENSION postgis;

CREATE EXTENSION "uuid-ossp";

UPDATE pg_database SET datistemplate = TRUE WHERE datname = 'template_postgis';
