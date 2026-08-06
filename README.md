# OpenLumara Docker Builder

Daily automated Docker image builds for [OpenLumara](https://github.com/Rose22/openlumara), a modular, token-efficient AI agent framework.

This repository contains only a `Dockerfile` and CI workflow — the actual OpenLumara source is cloned fresh from upstream during each build, so you always get the latest `main` branch without needing to maintain a fork.

## Quick Start

### Pull a prebuilt image

Images are pushed to GitHub Container Registry:

```bash
docker pull ghcr.io/jonathanmajh/openlumara:latest
docker run -d \
  --name openlumara \
  -p 3000:3000 \
  -v openlumara_data:/app/data \
  openlumara
```

Then open http://localhost:3000 in your browser.

### Or use docker-compose

```bash
# Edit docker-compose.yml to set your username
docker compose up -d
```

See [docker-compose.yml](./docker-compose.yml) for volume setup and options.

## Configuration

Once the container starts, open the WebUI, click the settings gear in the top-right, and configure:

- **API Provider URL** — point to your LLM backend (OpenAI, local llamacpp/ollama/koboldcpp, etc)
- **API Key** — your provider's API key
- **Model** — which model to use

If you're running a local LLM on your host machine, use `http://host.docker.internal:<port>` as the API URL (already configured in the compose example).

## Data Persistence

Two Docker volumes persist across container restarts and image updates:

- `openlumara_data` — chat history, memories, scheduled tasks
- `openlumara_config` — API settings, module toggles, character definitions

To wipe everything and start fresh:

```bash
docker compose down -v
docker compose up -d
```

## Building Locally

To build from the Dockerfile instead of pulling a prebuilt image:

```bash
docker build -t openlumara .
docker run -d \
  --name openlumara \
  -p 3000:3000 \
  -v openlumara_data:/app/data \
  openlumara
```

Or with compose — uncomment the `build:` block in [docker-compose.yml](./docker-compose.yml) and comment out `image:`.

## Customizing the Build

### Change the OpenLumara branch/tag

Edit the `Dockerfile`'s `ARG OPENLUMARA_REF=main` line:

```dockerfile
ARG OPENLUMARA_REF=v1.2.3  # or a specific commit hash
```

Or pass it at build time:

```bash
docker build --build-arg OPENLUMARA_REF=v1.2.3 -t openlumara .
```

### Force a fresh clone on every local build

By default, Docker caches layers aggressively. To force a fresh clone and rebuild:

```bash
docker build --no-cache -t openlumara .
```

## CI/CD

This repo includes a GitHub Actions workflow that:

- Runs **daily at 03:00 UTC** (configurable in [.github/workflows/build.yml](./.github/workflows/build.yml))
- Clones the latest OpenLumara `main` branch
- Builds a fresh image and pushes to GitHub Container Registry
- Tags images as `:latest` and `:N` (run number, for rollback)

Can also be triggered manually from the **Actions** tab.

### Prerequisites

- Your GitHub repo must have **Actions enabled** (usually default)
- If using a **private package**, ensure:
  - Settings → Actions → General → **Workflow permissions** is set to "Read and write permissions"
  - Anyone pulling the image needs a PAT with `read:packages` scope

### Customize the schedule

Edit [.github/workflows/build.yml](./.github/workflows/build.yml), line 8:

```yaml
- cron: '0 3 * * *'   # daily at 03:00 UTC
```

Use [cron.guru](https://cron.guru) to fiddle with the schedule.

## Troubleshooting

### "Can't connect to the API"

Make sure your OpenAI-compatible endpoint is actually running and accessible from the container:

- **Local on host** → use `http://host.docker.internal:PORT` and ensure `extra_hosts` is uncommented in compose
- **Another container** → use `http://service-name:PORT` (replace `service-name` with the container's name in compose)
- **Cloud provider** → use the full URL and check firewall/security groups

### "Settings aren't saving"

Check that the `openlumara_config` volume is actually mounted and writable:

```bash
docker inspect openlumara | grep -A 10 Mounts
```

### "Image pull rate limited"

GitHub Container Registry is free, but has rate limits on public images. If you hit them, either:

- Wait a few hours for the limit to reset
- Authenticate when pulling: `docker login ghcr.io` with a PAT
- Build locally instead: `docker build -t openlumara .`

### Container exits immediately

Check the logs:

```bash
docker compose logs -f openlumara
```

Common causes:

- Port 3000 already in use — change it in compose: `"3001:3000"`
- Python/dependency error — file an issue with the log output

## What's Inside

The Dockerfile:

- Starts from `python:3.11-slim`
- Clones OpenLumara from GitHub
- Installs Python dependencies
- Exposes port 3000
- Runs the WebUI channel only (CLI needs an interactive terminal)

Environment variables can be passed to `docker run` or compose to override OpenLumara's CLI flags if needed, but the basics are preset.

## License

OpenLumara itself is [GPL-2.0](https://github.com/Rose22/openlumara/blob/main/LICENSE).

This Dockerfile and CI setup are provided as-is for convenience.

## Links

- **OpenLumara** — https://github.com/Rose22/openlumara
- **GitHub Container Registry** — https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry
- **Docker Compose** — https://docs.docker.com/compose/