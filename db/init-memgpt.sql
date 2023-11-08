-- Title: Init MemGPT Database

-- Fetch the docker secrets, if they're available.

\set db_user `([ -r /var/run/secrets/memgpt-user ] && cat /var/run/secrets/memgpt-user) || echo 'memgpt'`
\set db_password `([ -r /var/run/secrets/memgpt-password ] && cat /var/run/secrets/memgpt-password) || echo 'memgpt'`
\set db_name `[ -r /var/run/secrets/memgpt-db ] && cat /var/run/secrets/memgpt-db || echo 'memgpt'`

-- Check if the password is plaintext, and if so, hash it.
SELECT NOT :'db_password' ~ '^SCRAM-SHA-256[$]\d+:' AS is_plaintext
\gset

\if :is_plaintext
    \echo 'plaintext password detected...' :db_password
\else
    \echo 'password is already hashed... ' :db_password
\endif


CREATE USER :"db_user"
    WITH PASSWORD :'db_password'
    NOCREATEDB
    NOCREATEUSER
    ;

CREATE DATABASE :"db_name"
    WITH
    OWNER = :"db_user"
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.utf8'
    LC_CTYPE = 'en_US.utf8'
    LOCALE_PROVIDER = 'libc'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;

\c :"db_name"
CREATE EXTENSION vector;
