# CLAUDE.md

## Project Overview

gardenbase is a from-source PostGIS Docker image for the
[GardenIO](https://github.com/gardenio-dev/gardenio) project.
It compiles PostgreSQL, PostGIS, GDAL, GEOS, PROJ, pgRouting,
and Python from source tarballs on Ubuntu, giving fine-grained
control over every component version.

Published to DockerHub as `gardenio/gardenbase`.

Extensions (postgis, pgrouting, pgcrypto) are compiled into
the image and available for use but not pre-enabled. GardenIO
is responsible for enabling extensions in tenant databases.

## Architecture

### Multi-Stage Dockerfile

- **Stage 1 (`build`)**: Ubuntu with build tools. Compiles
  all components from source in dependency order: GEOS →
  Python → PROJ → PostgreSQL → GDAL → PostGIS → pgRouting.
  Also rebuilds `pg_trgm` from PG contrib source to avoid
  PGDG binary incompatibility.

- **Stage 2 (`runtime`)**: Fresh Ubuntu with only runtime
  shared libraries. Compiled artifacts are copied from the
  build stage via `COPY --from=build /usr/local /usr/local`.

### Profile System

Version pins live in `profiles/*.env` files. Profile names
follow the tagging convention: `pg{major}-postgis{major}.env`
(e.g., `pg17-postgis3.5.env`).

Each profile sets: `IMAGE`, `VERSION`, `UBUNTU`, `GEOS`,
`GDAL`, `PROJ`, `POSTGRES`, `POSTGIS`, `PGROUTING`, `PYTHON`.

### Entrypoint

`entrypoint.sh` handles:
- First-run: `initdb`, install config, set password, create
  DB (if `POSTGRES_DB` is not `postgres`)
- Subsequent starts: run PostgreSQL in foreground directly
- Uses `gosu` to drop from root to `postgres` user
- Runs PG via `exec` so signals propagate correctly

### Configuration

Config files live in `conf/`:
- `postgresql.conf` — only non-default overrides (not the
  full 842-line default file)
- `pg_hba.conf` — active auth rules only

Configs are copied to `/etc/gardenio/` in the image and
installed into `$PGDATA` on first run.

## Key Files

| File | Purpose |
|------|---------|
| `Dockerfile` | Multi-stage build definition |
| `entrypoint.sh` | Container init and PG startup |
| `conf/postgresql.conf` | PG config overrides |
| `conf/pg_hba.conf` | Client authentication rules |
| `profiles/*.env` | Component version pins |
| `justfile` | Build and push recipes (just) |
| `docker-compose.yml` | Local build and run |
| `.github/workflows/build-push.yml` | CI/CD pipeline |

## Development Commands

```bash
# Build with default profile (pg17-postgis3.5)
just build

# Build with a specific profile
just build pg17-postgis3.5

# Build and push to DockerHub
just push

# Run locally with docker compose
source profiles/pg17-postgis3.5.env
docker compose up -d
```

Note: A full from-source build takes 30-60 minutes.

## Tagging Strategy

```
gardenio/gardenbase:pg17-postgis3.5      # Major versions
gardenio/gardenbase:17.5-3.5             # Profile version
gardenio/gardenbase:latest               # Most recent
```

## CI/CD

GitHub Actions workflow (`.github/workflows/build-push.yml`):
- **Push to main**: build + push to DockerHub
- **Pull requests**: build only (no push)
- **Manual dispatch**: select profile by name

Requires repository secrets:
- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`

## Adding a New Version Profile

1. Create `profiles/pg{major}-postgis{major}.env` with
   updated version pins
2. Update the workflow default if this becomes the primary
   profile
3. Update the component versions table in `README.md`
4. Build and test before pushing

## Relationship to GardenIO

This image is used as the PostGIS service in GardenIO's
devcontainer (`.devcontainer/docker-compose.yml`). When
updating versions here, the devcontainer build args should
be updated to match.

## License

PostgreSQL License — matches PostgreSQL and PostGIS licensing.
