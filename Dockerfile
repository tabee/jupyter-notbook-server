# syntax=docker/dockerfile:1.7

########################################
# Builder stage: build wheels only
########################################
FROM python:3.12-slim-bookworm AS builder

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

COPY requirements.txt .

RUN --mount=type=cache,target=/root/.cache/pip \
    python -m pip install --upgrade pip setuptools wheel \
    && python -m pip wheel \
         --wheel-dir=/build/wheels \
         jupyterlab==4.2.5 \
         notebook==7.2.2 \
         jupyter-server==2.14.2 \
         -r requirements.txt

########################################
# Runtime stage: minimal and clean
########################################
FROM python:3.12-slim-bookworm AS runtime

ARG USER_ID=1000
ARG GROUP_ID=1000

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1

RUN apt-get update && apt-get install -y --no-install-recommends \
      tini \
      ca-certificates \
      curl \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -g ${GROUP_ID} me \
    && useradd -m -u ${USER_ID} -g ${GROUP_ID} -s /bin/bash me

USER me
WORKDIR /home/me/jupyter-work

RUN python -m venv /home/me/venv
ENV PATH="/home/me/venv/bin:${PATH}"

COPY --from=builder --chown=me:me /build/wheels /wheels
COPY --chown=me:me requirements.txt /tmp/requirements.txt

RUN python -m pip install --no-index --find-links=/wheels \
      jupyterlab==4.2.5 \
      notebook==7.2.2 \
      jupyter-server==2.14.2 \
    && python -m pip install --no-index --find-links=/wheels -r /tmp/requirements.txt

EXPOSE 8888

ENTRYPOINT ["/usr/bin/tini", "--"]

CMD ["jupyter", "lab", \
     "--ServerApp.ip=0.0.0.0", \
     "--ServerApp.port=8888", \
     "--ServerApp.open_browser=False"]

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD curl -fsS http://127.0.0.1:8888/api/status || exit 1
