# gardenbase

PostGIS Docker image built from source for the
[GardenIO](https://github.com/gardenio-dev/gardenio) project.
Compiles PostgreSQL, PostGIS, GDAL, GEOS, PROJ, and pgRouting
from source tarballs for fine-grained version control.

## Quick Start

```bash
docker run -d \
    --name gardenbase \
    -e POSTGRES_PASSWORD=postgres \
    -p 5432:5432 \
    gardenio/gardenbase:latest
```

Or with Docker Compose:

```bash
# Load a profile
source profiles/pg17-postgis3.5.env

# Start
docker compose up -d
```

## Component Versions

| Component  | Version |
|------------|---------|
| PostgreSQL | 17.5    |
| PostGIS    | 3.5.1   |
| GDAL       | 3.10.2  |
| GEOS       | 3.13.0  |
| PROJ       | 9.5.0   |
| pgRouting  | 3.6.3   |
| Python     | 3.13.7  |
| Ubuntu     | 24.04   |

Versions are pinned in profile files under `profiles/`.

## Environment Variables

| Variable            | Default    | Description                       |
|---------------------|------------|-----------------------------------|
| `POSTGRES_DB`       | `postgres` | Database created on first start   |
| `POSTGRES_USER`     | `postgres` | PostgreSQL superuser name         |
| `POSTGRES_PASSWORD` | `postgres` | Superuser password                |

Extensions available (not pre-enabled):
- `postgis`
- `pgrouting`
- `pgcrypto`

## Profiles

Version profiles live in `profiles/`. Each profile is a
`.env` file with component version pins. To add a new
profile, create a new `.env` file in `profiles/` with the
desired version pins.

## Building and Publishing

This project uses [just](https://github.com/casey/just) as
a command runner.

```bash
# Build with the default profile (pg17-postgis3.5)
just build

# Build with a specific profile
just build pg17-postgis3.5

# Build and push to DockerHub
just push

# Push a specific profile
just push pg17-postgis3.5
```

Note: A full from-source build takes 30-60 minutes depending
on hardware.

Automated builds are also configured via GitHub Actions (see
`.github/workflows/build-push.yml`).

## Tagging Strategy

```
gardenio/gardenbase:pg17-postgis3.5          # Major versions
gardenio/gardenbase:17.5-3.5                 # Profile version
gardenio/gardenbase:latest                   # Most recent
```

## License

[PostgreSQL License](LICENSE) — the same permissive license
used by PostgreSQL and PostGIS.
