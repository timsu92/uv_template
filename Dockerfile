ARG BASE_IMAGE=nvidia/cuda:12.2.2-cudnn8-runtime-ubuntu22.04

FROM $BASE_IMAGE AS python-base
ARG PROJECT_PATH

# python
ENV PYTHONUNBUFFERED=1 \
    # prevents python creating .pyc files
    # PYTHONDONTWRITEBYTECODE=1 \
    \
    # pip
    PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PIP_DEFAULT_TIMEOUT=100 \
    \
    # poetry
    # https://python-poetry.org/docs/configuration/#using-environment-variables
    POETRY_VERSION=2.1.1 \
    # make poetry install to this location
    POETRY_HOME="/opt/poetry" \
    # save package cache to this location
    POETRY_CACHE_DIR="/root/.cache/pypoetry" \
    # make poetry create the virtual environment in the project's root
    # it gets named `.venv`
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    # do not ask any interactive question
    # POETRY_NO_INTERACTION=1 \
    \
    # paths
    # this is where our requirements + virtual environment will live
    VENV_PATH="${PROJECT_PATH}/.venv"

# prepend poetry and venv to path
ENV PATH="$POETRY_HOME/bin:$VENV_PATH/bin:$PATH"

# install python3.10
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update \
    && apt-get install --no-install-recommends -y \
        python3.10 python-is-python3

################################################################################

# `builder-base` stage is used to build deps + create our virtual environment
FROM python-base AS builder-base
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update \
    && apt-get install --no-install-recommends -y \
        # deps for installing poetry
        curl \
        # deps for building python deps
        build-essential \
        # useful tools
        git
    # && apt-get clean \
    # && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# install poetry - respects $POETRY_VERSION & $POETRY_HOME
RUN curl -sSL https://install.python-poetry.org | python

# copy project requirement files here to ensure they will be cached.
WORKDIR ${PROJECT_PATH}

################################################################################

FROM builder-base AS prod-prepare

# install runtime deps - uses $POETRY_VIRTUALENVS_IN_PROJECT internally
    # Poetry download cache
RUN --mount=type=cache,dst=${POETRY_CACHE_DIR},sharing=locked \
    # Project files
    --mount=type=bind,source=pyproject.toml,target=${PROJECT_PATH}/pyproject.toml \
    --mount=type=bind,source=poetry.lock,target=${PROJECT_PATH}/poetry.lock \
    # Git auth for some private repos
    # --mount=type=secret,id=GIT_AUTH_TOKEN,env=GIT_AUTH_TOKEN \
    # poetry config repositories.REPO_NAME https://github.com/SOME_ORG/SOME_REPO.git && \
    # poetry config http-basic.REPO_NAME username ${GIT_AUTH_TOKEN} && \
    poetry install --no-root
    # poetry config --unset http-basic.REPO_NAME

################################################################################

FROM python-base AS prod
ARG DEBIAN_FRONTEND=noninteractive
ARG TZ
ENV TZ=${TZ}
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update \
    && apt-get install --no-install-recommends -y \
        # timezone
        tzdata
# set timezone
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && dpkg-reconfigure -f noninteractive tzdata

RUN useradd -m nonroot
USER nonroot
WORKDIR ${PROJECT_PATH}
COPY --chown=nonroot:nonroot --from=prod-prepare $PROJECT_PATH/.venv .venv
COPY --chown=nonroot:nonroot . .

################################################################################

FROM builder-base AS dev
ARG DEBIAN_FRONTEND=noninteractive
ARG TZ
ENV TZ=${TZ}
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update \
    && apt-get install --no-install-recommends -y \
        # timezone
        tzdata \
        # useful tools
        vim wget curl
# set timezone
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && dpkg-reconfigure -f noninteractive tzdata

WORKDIR ${PROJECT_PATH}

CMD ["/bin/sh", "-c", "echo \"Container started\"; trap \"echo Container stopped; exit 0\" 15; exec \"$@\"; while sleep 1 & wait $!; do :; done"]