# gardenio/gardenbase
#
# From-source PostGIS image for the GardenIO project.
# Multi-stage build: compile everything in a build stage,
# copy only runtime artifacts to a minimal Ubuntu base.

# ── Build Args ─────────────────────────────────────────
ARG UBUNTU=24.04

# ── Stage 1: Build ─────────────────────────────────────
FROM ubuntu:${UBUNTU} AS build
ARG DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]

# Base build tools
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        build-essential bzip2 cmake wget ca-certificates \
        pkg-config && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir /build
WORKDIR /build

# ── GEOS ───────────────────────────────────────────────
ARG GEOS
RUN wget -q "https://download.osgeo.org/geos/geos-${GEOS}.tar.bz2" && \
    tar xjf "geos-${GEOS}.tar.bz2" && \
    cd "geos-${GEOS}" && \
    mkdir _build && cd _build && \
    cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        .. && \
    make -j"$(nproc)" && \
    make install && \
    cd /build && rm -rf "geos-${GEOS}"*

# ── Python ─────────────────────────────────────────────
ARG PYTHON
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        libreadline-dev libncursesw5-dev libssl-dev \
        libsqlite3-dev tk-dev libgdbm-dev libc6-dev \
        libbz2-dev libffi-dev zlib1g-dev && \
    rm -rf /var/lib/apt/lists/*
RUN wget -q "https://www.python.org/ftp/python/${PYTHON}/Python-${PYTHON}.tgz" && \
    tar xzf "Python-${PYTHON}.tgz" && \
    cd "Python-${PYTHON}" && \
    ./configure --prefix=/usr/local && \
    make -j"$(nproc)" install && \
    cd /build && rm -rf "Python-${PYTHON}"*

# ── PROJ ───────────────────────────────────────────────
ARG PROJ
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        curl libcurl4-openssl-dev libsqlite3-dev \
        libtiff-dev sqlite3 && \
    rm -rf /var/lib/apt/lists/*
RUN wget -q "https://download.osgeo.org/proj/proj-${PROJ}.tar.gz" && \
    tar xzf "proj-${PROJ}.tar.gz" && \
    cd "proj-${PROJ}" && \
    mkdir _build && cd _build && \
    cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        .. && \
    cmake --build . -j"$(nproc)" && \
    cmake --build . --target install && \
    cd /build && rm -rf "proj-${PROJ}"*
RUN proj

# ── PostgreSQL ─────────────────────────────────────────
ARG POSTGRES
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        bison flex icu-devtools libicu-dev \
        libreadline-dev zlib1g-dev libssl-dev && \
    rm -rf /var/lib/apt/lists/*
RUN wget -q "https://ftp.postgresql.org/pub/source/v${POSTGRES}/postgresql-${POSTGRES}.tar.gz" && \
    tar xzf "postgresql-${POSTGRES}.tar.gz" && \
    cd "postgresql-${POSTGRES}" && \
    ./configure \
        --prefix=/usr/local/pgsql \
        --with-openssl \
        --with-icu && \
    make -j"$(nproc)" world-bin && \
    make install-world-bin && \
    cd /build

# Set up locale (needed for initdb)
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends locales && \
    rm -rf /var/lib/apt/lists/* && \
    locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Build pg_trgm from source to match our PostgreSQL build
# (avoids symbol mismatch with PGDG-packaged .so files)
RUN cd "postgresql-${POSTGRES}/contrib/pg_trgm" && \
    make -j"$(nproc)" && \
    make install && \
    cd /build && rm -rf "postgresql-${POSTGRES}"*

# ── GDAL ───────────────────────────────────────────────
ARG GDAL
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        libcurl4-openssl-dev libtiff-dev libgeotiff-dev \
        libpng-dev libjpeg-dev libxml2-dev libexpat1-dev \
        libsqlite3-dev libpq-dev && \
    rm -rf /var/lib/apt/lists/*
RUN wget -q "https://github.com/OSGeo/gdal/releases/download/v${GDAL}/gdal-${GDAL}.tar.gz" && \
    tar xzf "gdal-${GDAL}.tar.gz" && \
    cd "gdal-${GDAL}" && \
    mkdir build && cd build && \
    cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        .. && \
    cmake --build . -j"$(nproc)" && \
    cmake --build . --target install && \
    cd /build && rm -rf "gdal-${GDAL}"*

# ── PostGIS ────────────────────────────────────────────
ARG POSTGIS
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        autoconf automake autotools-dev libtool \
        libboost-all-dev libcunit1-dev \
        libcurl4-gnutls-dev libgmp-dev libjson-c-dev \
        libmpfr-dev libpcre3-dev libprotobuf-c-dev \
        libsqlite3-dev libtiff-dev libxml2-dev \
        libxml2-utils protobuf-c-compiler xsltproc \
        docbook-xml docbook5-xml git && \
    rm -rf /var/lib/apt/lists/*
RUN wget -q "https://postgis.net/stuff/postgis-${POSTGIS}.tar.gz" && \
    tar xzf "postgis-${POSTGIS}.tar.gz" && \
    cd "postgis-${POSTGIS}" && \
    ./configure \
        --with-pgconfig=/usr/local/pgsql/bin/pg_config && \
    make -j"$(nproc)" && \
    make install && \
    cd /build && rm -rf "postgis-${POSTGIS}"*

# ── pgRouting ──────────────────────────────────────────
ARG PGROUTING
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        libboost-graph-dev libboost-system-dev \
        libboost-thread-dev && \
    rm -rf /var/lib/apt/lists/*
RUN wget -q "https://github.com/pgRouting/pgrouting/archive/refs/tags/v${PGROUTING}.tar.gz" \
        -O "pgrouting-${PGROUTING}.tar.gz" && \
    tar xzf "pgrouting-${PGROUTING}.tar.gz" && \
    cd "pgrouting-${PGROUTING}" && \
    mkdir build && cd build && \
    cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr/local/pgsql \
        -DPOSTGRESQL_PG_CONFIG=/usr/local/pgsql/bin/pg_config \
        -DPOSTGRESQL_EXECUTABLE=/usr/local/pgsql/bin/postgres \
        .. && \
    make -j"$(nproc)" && \
    make install && \
    cd /build && rm -rf "pgrouting-${PGROUTING}"*

# Clean up build directory
RUN rm -rf /build


# ── Stage 2: Runtime ───────────────────────────────────
FROM ubuntu:${UBUNTU} AS runtime
ARG DEBIAN_FRONTEND=noninteractive

# OCI Labels
ARG POSTGRES
ARG POSTGIS
ARG GDAL
ARG GEOS
ARG PROJ
ARG PGROUTING
LABEL org.opencontainers.image.title="gardenbase" \
      org.opencontainers.image.description="PostGIS image built from source for the GardenIO project" \
      org.opencontainers.image.source="https://github.com/gardenio-dev/gardenbase" \
      org.opencontainers.image.vendor="GardenIO" \
      org.opencontainers.image.licenses="PostgreSQL" \
      com.gardenio.postgres.version="${POSTGRES}" \
      com.gardenio.postgis.version="${POSTGIS}" \
      com.gardenio.gdal.version="${GDAL}" \
      com.gardenio.geos.version="${GEOS}" \
      com.gardenio.proj.version="${PROJ}" \
      com.gardenio.pgrouting.version="${PGROUTING}"

# Runtime dependencies only (no -dev packages, no compilers)
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        libcurl4 \
        libgmp10 \
        libicu74 \
        libjson-c5 \
        libmpfr6 \
        libpcre3 \
        libprotobuf-c1 \
        libreadline8t64 \
        libsqlite3-0 \
        libtiff6 \
        libxml2 \
        libssl3t64 \
        libboost-serialization1.83.0 \
        libboost-system1.83.0 \
        libboost-thread1.83.0 \
        libboost-graph1.83.0 \
        locales \
        gosu && \
    rm -rf /var/lib/apt/lists/* && \
    locale-gen en_US.UTF-8

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Copy compiled artifacts from build stage
COPY --from=build /usr/local /usr/local

# Ensure shared libraries are discoverable
RUN ldconfig

# Create postgres user with fixed UID/GID for volume
# permission consistency across hosts
RUN groupadd -r -g 999 postgres && \
    useradd -r -u 999 -g postgres -m -d /home/postgres \
        -s /bin/bash postgres

# Create data directory
RUN mkdir -p /data && chown postgres:postgres /data

# Copy configuration files
COPY conf/postgresql.conf /etc/gardenio/postgresql.conf
COPY conf/pg_hba.conf /etc/gardenio/pg_hba.conf

# Copy entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Add PostgreSQL binaries to PATH
ENV PATH="/usr/local/pgsql/bin:${PATH}"
ENV PGDATA="/data"

EXPOSE 5432
VOLUME ["/data"]

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD pg_isready -U postgres -q || exit 1

ENTRYPOINT ["entrypoint.sh"]
CMD ["postgres"]
