# gardenbase

<table><tr>
<td><img src="logo.png" alt="gardenbase logo" width="300"></td>
<td>
PostGIS Docker image built from source for the
<a href="https://github.com/gardenio-dev/gardenio">GardenIO</a> project.
Compiles PostgreSQL, PostGIS, GDAL, GEOS, PROJ, and pgRouting
from source tarballs for fine-grained version control.
</td>
</tr></table>

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
source profiles/pg18-postgis3.6.env

# Start
docker compose up -d
```

## Component Versions

| Component  | pg18-postgis3.6 (default) | pg17-postgis3.5 |
|------------|---------------------------|-----------------|
| PostgreSQL | 18.6                      | 17.5            |
| PostGIS    | 3.6.4                     | 3.5.1           |
| GDAL       | 3.8.4                     | 3.10.2          |
| GEOS       | 3.12.1                    | 3.13.0          |
| PROJ       | 9.4.0                     | 9.5.0           |
| CGAL       | 6.1.3                     | 6.0.1           |
| SFCGAL     | 2.2.0                     | 2.1.0           |
| pgRouting  | 3.8.0                     | 3.6.3           |
| Python     | 3.14.10                   | 3.13.7          |
| Ubuntu     | 24.04                     | 24.04           |

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
# Build with the default profile (pg18-postgis3.6)
just build

# Build with a specific profile
just build pg18-postgis3.6

# Build and push to DockerHub
just push

# Push a specific profile
just push pg18-postgis3.6
```

Note: A full from-source build takes 30-60 minutes depending
on hardware.

Automated builds are also configured via GitHub Actions (see
`.github/workflows/build-push.yml`).

## Tagging Strategy

```
gardenio/gardenbase:pg18-postgis3.6          # Major versions
gardenio/gardenbase:18.6-3.6                 # Profile version
gardenio/gardenbase:latest                   # Most recent
```

## License

[PostgreSQL License](LICENSE) — the same permissive license
used by PostgreSQL and PostGIS.
