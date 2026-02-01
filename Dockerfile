# syntax=docker/dockerfile:1.7

ARG JUPYTERLAB_VERSION=4.2.5
ARG NOTEBOOK_VERSION=7.2.2
ARG JUPYTER_SERVER_VERSION=2.14.2

########################################
# Builder stage: build wheels only
########################################
FROM python:3.12-slim-bookworm AS builder

ARG JUPYTERLAB_VERSION
ARG NOTEBOOK_VERSION
ARG JUPYTER_SERVER_VERSION

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential \
      python3-dev \
      libffi-dev \
      libssl-dev \
      ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

COPY requirements.txt constraints.txt ./

RUN --mount=type=cache,target=/root/.cache/pip \
    python -m pip install --upgrade pip setuptools wheel \
    && python -m pip wheel --wheel-dir=/build/wheels -r requirements.txt -c constraints.txt \
    && python -m pip wheel \
         --wheel-dir=/build/wheels \
         -c constraints.txt \
         jupyterlab==${JUPYTERLAB_VERSION} \
         notebook==${NOTEBOOK_VERSION} \
         jupyter-server==${JUPYTER_SERVER_VERSION}

########################################
# Runtime stage: minimal and clean
########################################
FROM python:3.12-slim-bookworm AS runtime

ARG USER_ID=1000
ARG GROUP_ID=1000
ARG JUPYTERLAB_VERSION
ARG NOTEBOOK_VERSION
ARG JUPYTER_SERVER_VERSION

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    PYTHONWARNINGS="ignore::jupyter_events.JupyterEventsVersionWarning"

RUN apt-get update && apt-get install -y --no-install-recommends \
      tini \
      ca-certificates \
      curl \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -g ${GROUP_ID} jupyter \
    && useradd -m -u ${USER_ID} -g ${GROUP_ID} -s /bin/bash jupyter

USER jupyter
WORKDIR /home/jupyter/jupyter-work

RUN python -m venv /home/jupyter/venv
ENV PATH="/home/jupyter/venv/bin:${PATH}"

COPY --from=builder --chown=jupyter:jupyter /build/wheels /tmp/wheels
COPY --chown=jupyter:jupyter requirements.txt /tmp/requirements.txt
COPY --chown=jupyter:jupyter constraints.txt /tmp/constraints.txt

RUN python -m pip install --no-index --find-links=/tmp/wheels -c /tmp/constraints.txt \
    jupyterlab==${JUPYTERLAB_VERSION} \
    notebook==${NOTEBOOK_VERSION} \
    jupyter-server==${JUPYTER_SERVER_VERSION} \
    && python -m pip install --no-index --find-links=/tmp/wheels -c /tmp/constraints.txt -r /tmp/requirements.txt \
    && rm -rf /tmp/wheels /tmp/requirements.txt /tmp/constraints.txt

EXPOSE 8888

ENTRYPOINT ["/usr/bin/tini", "--"]

CMD ["jupyter", "notebook", \
     "--ServerApp.ip=0.0.0.0", \
     "--ServerApp.port=8888", \
     "--ServerApp.open_browser=False", \
    "--IdentityProvider.token=", \
    "--ServerApp.password_required=False", \
     "--ServerApp.allow_origin=*"]

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD curl -fsS http://0.0.0.0:8888/ >/dev/null || exit 1
