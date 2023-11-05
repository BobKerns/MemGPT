FROM ubuntu:latest as base

RUN --mount=type=cache,target=/memgpt/.cache,sharing=locked \
    useradd -mUs /bin/bash -d /memgpt memgpt \
    && mkdir -p /memgpt/.memgpt /memgpt/.local \
    && chown -R memgpt:memgpt /memgpt /memgpt/.memgpt /memgpt/.cache

ENV PATH=/memgpt/.local/bin:/memgpt/.cargo/bin:$PATH

RUN rm -f /etc/apt/apt.conf.d/docker-clean; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update \
    && apt-get --no-install-recommends install -y \
        python3 \
        python3-pip \
        python3-dev \
        build-essential \
        pkg-config \
        libssl-dev \
        libffi-dev \
        python3-setuptools \
        python3-venv \
        git \
        curl \
        tini \
        pipx \
    && ln -s /usr/bin/python3 /usr/bin/python \
    && rm -rf /var/lib/apt/lists/*


RUN --mount=type=cache,target=/memgpt/.cache,sharing=locked \
    chown -R memgpt:memgpt /memgpt/.cache \
    && chown -R memgpt:memgpt /memgpt

WORKDIR /memgpt
USER memgpt
ENV HOME=/memgpt

RUN --mount=type=tmpfs,target=/memgpt/.rustup/tmp \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > /tmp/rustup-install \
    && bash /tmp/rustup-install -y \
    && rm /tmp/rustup-install

RUN --mount=type=cache,target=/memgpt/.cache,sharing=locked \
    pipx install poetry
RUN --mount=type=cache,target=/memgpt/.cache,sharing=locked \
    python3 -m venv /memgpt/.venv \
    && ls -lR /memgpt/.venv 1>&2

COPY requirements.txt .

RUN --mount=type=cache,target=/memgpt/.cache,sharing=locked \
    pip install --upgrade pip \
    && pip install -r requirements.txt \
    && pip install pgvector psycopg

FROM base as build

WORKDIR /memgpt
USER memgpt

COPY . .

RUN --mount=type=cache,target=/memgpt/.cache,sharing=locked \
    poetry build

FROM base as memgpt

COPY --from=build /memgpt/dist/pymemgpt-*-py3-none-any.whl /tmp/

RUN pip install /tmp/pymemgpt-*-py3-none-any.whl

VOLUME /memgpt/.memgpt

ENTRYPOINT ["python3", "-m", "memgpt"]

CMD ["--help"]
