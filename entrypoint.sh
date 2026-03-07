#!/usr/bin/env bash
set -eo pipefail

POSTGRES_DB="${POSTGRES_DB:-postgres}"
POSTGRES_USER="${POSTGRES_USER:-postgres}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-postgres}"
PGDATA="${PGDATA:-/data}"

# ── First-run initialization ───────────────────────────
if [ ! -s "$PGDATA/PG_VERSION" ]; then
    echo "Initializing database cluster in $PGDATA..."
    gosu postgres initdb \
        -D "$PGDATA" \
        --encoding=UTF8 \
        --locale=en_US.UTF-8

    # Install configuration
    cp /etc/gardenio/postgresql.conf "$PGDATA/postgresql.conf"
    cp /etc/gardenio/pg_hba.conf "$PGDATA/pg_hba.conf"

    # Start temporarily for setup
    gosu postgres pg_ctl -D "$PGDATA" -w start

    # Set password (double single quotes to escape for SQL)
    ESCAPED_PASS="${POSTGRES_PASSWORD//\'/\'\'}"
    gosu postgres psql -U postgres -c \
        "ALTER USER \"${POSTGRES_USER}\" WITH PASSWORD '${ESCAPED_PASS}';"

    # Create application database
    if [ "$POSTGRES_DB" != "postgres" ]; then
        DB_EXISTS=$(gosu postgres psql -U postgres -tAc \
            "SELECT 1 FROM pg_database WHERE datname = '${POSTGRES_DB}'")
        if [ "$DB_EXISTS" != "1" ]; then
            gosu postgres psql -U postgres -c \
                "CREATE DATABASE \"${POSTGRES_DB}\";"
        fi
    fi

    # Stop temporary server
    gosu postgres pg_ctl -D "$PGDATA" -w stop
    echo "Initialization complete."
fi

# ── Start PostgreSQL ───────────────────────────────────
echo "Starting PostgreSQL..."
exec gosu postgres postgres -D "$PGDATA"
