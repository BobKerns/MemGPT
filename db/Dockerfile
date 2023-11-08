# syntax = docker/dockerfile:1.6

# Build and install pgvector extension ito postgres image

ARG PG_MAJOR=16
ARG PGVECTOR=0.5.1

# Base image, common to both final image and build image
FROM postgres:$PG_MAJOR AS base
ARG PG_MAJOR
ARG PGVECTOR

# Cache the apt packages
RUN rm -f /etc/apt/apt.conf.d/docker-clean; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update \
    && apt-mark hold locales \
    && apt-get install -y --no-install-recommends  \
    && rm -rf /var/lib/apt/lists/*

# Build image, used to build pgvector extension
# This allows us to leverage the build cache for rapid development.
FROM base AS build
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update \
    && apt-mark hold locales \
    && apt-get install -y --no-install-recommends build-essential postgresql-server-dev-$PG_MAJOR \
    && apt-mark unhold locales \
    && rm -rf /var/lib/apt/lists/*

# Clone the pgvector repo
ADD https://github.com/pgvector/pgvector.git#v$PGVECTOR /tmp/pgvector

# Build and install pgvector
# The output from the make install will be used in the final image
RUN cd /tmp/pgvector \
    && make clean \
    && make OPTFLAGS="" \
    && make --debug install \
    && mkdir /usr/share/doc/pgvector \
    && cp LICENSE README.md /usr/share/doc/pgvector

# Final image, installs pgvector extension by copying the installed files from the build image
FROM base AS pgvector

COPY --link --from=build /usr/lib/postgresql/$PG_MAJOR/lib/vector.so /usr/lib/postgresql/$PG_MAJOR/lib/vector.so
COPY --link --from=build /usr/share/postgresql/$PG_MAJOR/extension/vector.control /usr/share/postgresql/$PG_MAJOR/extension/vector.control
COPY --link --from=build /usr/share/postgresql/$PG_MAJOR/extension/*vector* /usr/share/postgresql/$PG_MAJOR/extension/
COPY --link --from=build /usr/include/postgresql/$PG_MAJOR/server/extension /usr/include/postgresql/$PG_MAJOR/server/extension/
COPY --link --from=build /usr/lib/postgresql/$PG_MAJOR/lib/bitcode/vector /usr/lib/postgresql/$PG_MAJOR/lib/bitcode/vector/

# Set up our memgpt database, installing the pgvector extension
# and creating the memgpt user.  The credentials are passedin
# via these docker secrets:
#
# memgpt-user
# memgpt-password
# memgpt-db
COPY init-memgpt.sql /docker-entrypoint-initdb.d/init-memgpt.sql
