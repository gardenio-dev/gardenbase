# gardenbase — from-source PostGIS Docker image

# Default profile
default_profile := "pg17-postgis3.5"

# List available recipes
default:
    @just --list

# Build the image from a profile
build profile=default_profile:
    #!/usr/bin/env bash
    set -euo pipefail
    source "profiles/{{ profile }}.env"
    docker build \
        --build-arg UBUNTU="${UBUNTU}" \
        --build-arg GEOS="${GEOS}" \
        --build-arg GDAL="${GDAL}" \
        --build-arg PROJ="${PROJ}" \
        --build-arg POSTGRES="${POSTGRES}" \
        --build-arg POSTGIS="${POSTGIS}" \
        --build-arg PGROUTING="${PGROUTING}" \
        --build-arg PYTHON="${PYTHON}" \
        -t "gardenio/gardenbase:${VERSION}" \
        -t "gardenio/gardenbase:latest" \
        .

# Log in to DockerHub
login:
    docker login

# Push the image for a profile (all tags)
push profile=default_profile: login (build profile)
    #!/usr/bin/env bash
    set -euo pipefail
    source "profiles/{{ profile }}.env"
    PG_MAJOR="${POSTGRES%%.*}"
    POSTGIS_MAJOR="${POSTGIS%.*}"
    docker tag "gardenio/gardenbase:${VERSION}" "gardenio/gardenbase:pg${PG_MAJOR}-postgis${POSTGIS_MAJOR}"
    docker tag "gardenio/gardenbase:${VERSION}" "gardenio/gardenbase:latest"
    docker push "gardenio/gardenbase:${VERSION}"
    docker push "gardenio/gardenbase:pg${PG_MAJOR}-postgis${POSTGIS_MAJOR}"
    docker push "gardenio/gardenbase:latest"
