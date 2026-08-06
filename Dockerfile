# Dockerfile for OpenLumara (https://github.com/Rose22/openlumara)
# Builds by cloning the upstream repo directly -- no OpenLumara source
# needs to live in this repo.
FROM python:3.11-slim

# COPY the Docker CLI binary directly from the official docker image
COPY --from=docker:cli /usr/local/bin/docker /usr/local/bin/

# which branch/tag/commit to build from
ARG OPENLUMARA_REF=main

# build-essential: some tree-sitter-* packages may need to compile from source
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# CACHEBUST: docker only re-runs a RUN layer if something it depends on
# changed. Since the clone command itself never changes, a scheduled
# rebuild would otherwise reuse the old cached clone forever. Pass a fresh
# value (e.g. a CI run id or the current date) at build time to force a
# fresh clone on each scheduled run.
ARG CACHEBUST=1
RUN echo "cachebust: ${CACHEBUST}" \
    && git clone --depth 1 --branch ${OPENLUMARA_REF} https://github.com/Rose22/openlumara.git .

RUN pip install --no-cache-dir -r requirements.txt

RUN mkdir -p /app/data

ENV PYTHONUNBUFFERED=1

# WebUI defaults to port 3000 (channels/webui.py) and network_mode "local"
# (binds localhost only, unreachable from outside the container), so we
# force network_mode "internet" (binds 0.0.0.0) below.
EXPOSE 3000

# Create a minimal config.yml file that enables webui, network_mode internet, unsafe-shell
RUN echo "channels:\n  enabled:\n    - webui\n  settings:\n    webui:\n      network_mode: internet\n      port: 3000\nmodules:\n  enabled:\n  - unsafe_shell" > /app/config.yml

ENTRYPOINT ["python", "main.py"]
