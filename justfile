# gardenbase — from-source PostGIS Docker image

# Default profile
default_profile := "pg17-postgis3.5"

# List available recipes
default:
    @just --list

# Build the image from a profile (native platform, loadable into Docker)
build profile=default_profile:
    #!/usr/bin/env bash
    set -euo pipefail
    source "profiles/{{ profile }}.env"
    PG_MAJOR="${POSTGRES%%.*}"
    POSTGIS_MAJOR="${POSTGIS%.*}"
    docker buildx build \
        --load \
        --build-arg UBUNTU="${UBUNTU}" \
        --build-arg GEOS="${GEOS}" \
        --build-arg CGAL="${CGAL}" \
        --build-arg SFCGAL="${SFCGAL}" \
        --build-arg GDAL="${GDAL}" \
        --build-arg PROJ="${PROJ}" \
        --build-arg POSTGRES="${POSTGRES}" \
        --build-arg POSTGIS="${POSTGIS}" \
        --build-arg PGROUTING="${PGROUTING}" \
        --build-arg PYTHON="${PYTHON}" \
        -t "gardenio/gardenbase:${VERSION}" \
        -t "gardenio/gardenbase:pg${PG_MAJOR}-postgis${POSTGIS_MAJOR}" \
        -t "gardenio/gardenbase:latest" \
        .

# Log in to DockerHub
login:
    docker login

# Build and push multi-platform image for a profile (all tags)
push profile=default_profile: login
    #!/usr/bin/env bash
    set -euo pipefail
    source "profiles/{{ profile }}.env"
    PG_MAJOR="${POSTGRES%%.*}"
    POSTGIS_MAJOR="${POSTGIS%.*}"
    docker buildx build \
        --platform linux/amd64,linux/arm64 \
        --push \
        --build-arg UBUNTU="${UBUNTU}" \
        --build-arg GEOS="${GEOS}" \
        --build-arg CGAL="${CGAL}" \
        --build-arg SFCGAL="${SFCGAL}" \
        --build-arg GDAL="${GDAL}" \
        --build-arg PROJ="${PROJ}" \
        --build-arg POSTGRES="${POSTGRES}" \
        --build-arg POSTGIS="${POSTGIS}" \
        --build-arg PGROUTING="${PGROUTING}" \
        --build-arg PYTHON="${PYTHON}" \
        -t "gardenio/gardenbase:${VERSION}" \
        -t "gardenio/gardenbase:pg${PG_MAJOR}-postgis${POSTGIS_MAJOR}" \
        -t "gardenio/gardenbase:latest" \
        .
