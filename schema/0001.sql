DROP DATABASE IF NOT EXISTS template_postgis;

CREATE DATABASE template_postgis;

\c template_postgis

CREATE EXTENSION postgis;

CREATE EXTENSION "uuid-ossp";

UPDATE pg_database SET datistemplate = TRUE WHERE datname = 'template_postgis';
