#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE USER nocodb WITH PASSWORD 'nocodb';
    CREATE DATABASE nocodb;
    GRANT ALL PRIVILEGES ON DATABASE nocodb TO nocodb;
EOSQL