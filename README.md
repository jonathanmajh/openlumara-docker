# OpenLumara Docker Builder

Daily automated Docker image builds for [OpenLumara](https://github.com/Rose22/openlumara), a modular, token-efficient AI agent framework.

This repository contains only a `Dockerfile` and CI workflow — the actual OpenLumara source is cloned fresh from upstream during each build.

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
# Edit docker-compose.yml 
docker compose up -d
```

See [example.docker-compose.yml](./example.docker-compose.yml) for volume setup and options.

## Configuration

If you're running a local LLM on your host machine, use `http://host.docker.internal:<port>` as the API URL

In most cases a config.yml file should be mount for persistence and management.

A minimal config.yml is generate within the container to turn on webui, network_mode: internet, unsafe_shell by default

### Shell

Since OpenLumara is in Docker the unsafe_shell is safer than the sandboxed_shell

unsafe_shell uses `subprocess.run()` which will be within the container, isolated from host.

sandboxed_shell requires podman / docker which means the host docker socket must be mounted within the container, giving full access to the host

Docker CLI is included in the image if sandboxed_shell is to be used

## Data Persistence

- `openlumara_data` — Docker Volume - chat history, memories, scheduled tasks
- `./config.yml` — File Mount - API settings, module toggles, character definitions

## CI/CD

This repo includes a GitHub Actions workflow that:

- Runs **daily at 03:00 UTC**
- Clones the latest OpenLumara `main` branch
- Builds a fresh image and pushes to GitHub Container Registry
- Tags images as `:latest` and `:N` (run number, for rollback)

Can also be triggered manually from the **Actions** tab.

## Troubleshooting

### "Can't connect to the API"

Make sure your OpenAI-compatible endpoint is actually running and accessible from the container:

- **Local on host** → use `http://host.docker.internal:PORT` and ensure `extra_hosts` is uncommented in compose
- **Another container** → use `http://service-name:PORT` (replace `service-name` with the container's name in compose)
- **Cloud provider** → use the full URL and check firewall/security groups

### "Settings aren't saving"

Check that the `./config.yml` volume is actually mounted and writable:

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
