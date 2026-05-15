# Deployment Guide

This project deploys as a Docker Swarm stack to a single VPS. CI builds both the PHP and nginx images on every push to `develop`; the CD pipeline deploys them to the Swarm via Docker Context — no SSH scripting required.

---

## Architecture

```
Internet
   │  (ports 80/443)
   ▼
Caddy (Swarm service, Let's Encrypt TLS)
   │  (overlay network: frontend)
   ▼
nginx (Swarm service, 2 replicas — serves static assets + proxies PHP-FPM)
   │  (overlay network: backend, internal)
   ├──▶ php (PHP-FPM, 2 replicas — Laravel application)
   │         └── app_storage volume (shared across replicas)
   └──▶ db (MySQL 8.0, 1 replica, external volume)

worker    (1 replica, same PHP image, runs queue:work)
scheduler (1 replica, same PHP image, runs schedule:work)
```

Sensitive values (APP_KEY, DB_PASSWORD, etc.) are stored as Docker Secrets and mounted read-only into containers at `/run/secrets/`. They never appear in environment variables, image layers, or compose files.

---

## 1. Fresh VPS Setup

Run as `root` on a fresh Ubuntu 22.04 or 24.04 VPS:

```bash
# Install Docker
curl -fsSL https://get.docker.com | sh

# Create a non-root deploy user with Docker access
adduser deploy
usermod -aG docker deploy

# Add the SSH public key that GitHub Actions (and you locally) will use
mkdir -p /home/deploy/.ssh
cat >> /home/deploy/.ssh/authorized_keys << 'EOF'
ssh-ed25519 AAAA... your-deploy-key-public
EOF
chown -R deploy:deploy /home/deploy/.ssh
chmod 700 /home/deploy/.ssh
chmod 600 /home/deploy/.ssh/authorized_keys

# Open required ports
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable
```

---

## 2. Docker Swarm Initialization

Run as `deploy` on the VPS:

```bash
docker swarm init --advertise-addr <VPS_PUBLIC_IP>
```

For a single-node Swarm, this VPS is both the manager and the only worker. Save the join token output if you plan to add worker nodes later.

---

## 3. Create External Volume

The database volume is declared `external: true` in the stack file to prevent accidental deletion on `docker stack rm`.

```bash
docker volume create nikeflow_db_data
```

Verify:
```bash
docker volume ls | grep nikeflow
```

---

## 4. Create Docker Secrets

Run on the Swarm manager (the VPS) as `deploy`. Use `printf` rather than `echo` to avoid a trailing newline being included in the secret value.

```bash
# APP_KEY — generate locally with: php artisan key:generate --show
printf 'base64:YOUR_APP_KEY_HERE' | docker secret create app_key -

# Database credentials
printf 'your_strong_db_password' | docker secret create db_password -
printf 'laravel'                  | docker secret create db_username -
printf 'your_root_password'       | docker secret create mysql_root_password -
```

Verify (names only — values are never shown):
```bash
docker secret ls
```

> **Secrets are immutable.** To rotate a secret, see [Rotating Secrets](#9-rotating-secrets).

---

## 5. Docker Context Setup (local machine)

Docker Context lets you run Docker commands against a remote Swarm over SSH, without logging into the server.

```bash
# Generate a dedicated SSH key (or reuse an existing one)
ssh-keygen -t ed25519 -f ~/.ssh/vps_deploy_key -C "docker-context-vps"

# Add the public key to the VPS (if not already done in step 1)
ssh-copy-id -i ~/.ssh/vps_deploy_key.pub deploy@<VPS_IP>

# Create the context
docker context create vps --docker "host=ssh://deploy@<VPS_IP>"

# Test
docker --context vps info
docker --context vps node ls    # should show one manager node
```

All `stack-*` Makefile targets use this context automatically.

---

## 6. GitHub Actions Secrets

In the repository: **Settings → Secrets and variables → Actions → Secrets**

| Secret | Value |
|---|---|
| `VPS_HOST` | IP address or hostname of the VPS |
| `VPS_SSH_KEY` | Full contents of the SSH private key (e.g., `~/.ssh/vps_deploy_key`) |

The `GITHUB_TOKEN` secret is provided automatically by Actions — no manual setup needed.

> If you previously had `STAGING_HOST`, `STAGING_USER`, `STAGING_SSH_KEY` secrets, those are no longer used and can be removed.

---

## 7. Initial Deploy

The first deploy must be run manually since the stack doesn't exist on the Swarm yet.

```bash
# Authenticate to GHCR (one-time per machine)
echo $GITHUB_PAT | docker login ghcr.io -u <your-github-username> --password-stdin

# Set image tags (use the SHA from a CI-built image, or build locally)
export SHORT_SHA=$(git rev-parse --short HEAD)
export PHP_IMAGE=ghcr.io/<org>/<repo>/php:sha-${SHORT_SHA}
export NGINX_IMAGE=ghcr.io/<org>/<repo>/nginx:sha-${SHORT_SHA}

# Build and push both images (if not already pushed by CI)
docker buildx build --file infra/Dockerfile --target runtime \
  --tag $PHP_IMAGE --push .

docker buildx build --file infra/Dockerfile --target nginx-stage \
  --tag $NGINX_IMAGE --push .

# Deploy the stack
docker --context vps stack deploy \
  --compose-file infra/docker-stack.yml \
  --with-registry-auth \
  --prune \
  nikeflow

# Watch startup
docker --context vps stack ps nikeflow --no-trunc
```

Wait for all tasks to show `Running`. The `php` service runs `php artisan migrate --force` on first start, which creates all database tables.

Verify the site is live:
```bash
curl -I https://staging.example.com/up
# Expected: HTTP/2 200
```

Or use the Makefile shortcuts:
```bash
make stack-deploy PHP_IMAGE=$PHP_IMAGE NGINX_IMAGE=$NGINX_IMAGE
make stack-ps
```

---

## 8. Rolling Deploys (automated via CI)

All subsequent deploys are automatic:

1. Push commits to `develop`
2. CI workflow runs (Pint lint → Pest tests → Vite build)
3. On CI success, CD workflow (`cd-staging.yml`) triggers:
   - Builds `php:sha-xxx` (`--target runtime`) and `nginx:sha-xxx` (`--target nginx-stage`)
   - Pushes both images to GHCR
   - Creates a Docker context pointing to the VPS via SSH
   - Runs `docker --context vps stack deploy` with the new image tags
   - Polls until all `php` replicas are running

### Rolling update behaviour (zero-downtime)

For `php` and `nginx` (both use `order: start-first`):
1. Swarm starts a new replica with the new image
2. New replica must pass healthchecks before the old one stops
3. Old replica is then stopped
4. Repeats for each replica

If the new replica fails healthchecks, Swarm automatically rolls back to the previous image.

For `worker` and `scheduler` (`order: stop-first`), the old container stops first to drain in-flight jobs before the new one starts.

---

## 9. Rotating Secrets

Docker Swarm secrets are immutable — they cannot be updated in place. The rotation procedure is:

```bash
# 1. Create the new secret under a versioned name
printf 'new_secret_value' | docker --context vps secret create app_key_v2 -

# 2. Update docker-stack.yml: change `app_key` → `app_key_v2` in both
#    the `secrets:` block at the top and in each service's `secrets:` list.
#    Also update the load_secret call in entrypoint.sh if the name changed.

# 3. Redeploy (via CI push, or manually):
make stack-deploy PHP_IMAGE=<current-tag> NGINX_IMAGE=<current-tag>

# 4. After successful deploy, remove the old secret
docker --context vps secret rm app_key
```

---

## 10. Rollback Procedures

### Automatic rollback

If a rolling update fails healthchecks, Swarm rolls the affected service back to the previous image automatically. No action required.

### Manual rollback of a service

```bash
# Roll back php to the previous version
docker --context vps service rollback nikeflow_php

# Or via Makefile
make stack-rollback SERVICE=php
```

### Redeploy to a specific image tag

```bash
export PHP_IMAGE=ghcr.io/<org>/<repo>/php:sha-<previous-sha>
export NGINX_IMAGE=ghcr.io/<org>/<repo>/nginx:sha-<previous-sha>
make stack-deploy PHP_IMAGE=$PHP_IMAGE NGINX_IMAGE=$NGINX_IMAGE
```

### Database migrations

`php artisan migrate --force` runs in the entrypoint on every container start. Rolling back the PHP image does **not** reverse already-applied migrations. To roll back a migration manually:

```bash
# Get a shell into a running php container
docker --context vps exec \
  $(docker --context vps ps -q -f name=nikeflow_php) \
  php artisan migrate:rollback
```

Write reversible migrations (`up` + `down`) to make this safe.

---

## 11. Viewing Logs

```bash
# Follow logs for a service (replace <service> with php, nginx, worker, scheduler, caddy, db)
docker --context vps service logs -f nikeflow_<service>

# Or via Makefile
make stack-logs SERVICE=php

# Last 100 lines
docker --context vps service logs --tail 100 nikeflow_php

# Task history (shows which containers ran, failed, or were stopped)
docker --context vps stack ps nikeflow --no-trunc
```

---

## 12. Useful Commands

```bash
# List all services with replica counts
make stack-services

# List all running tasks
make stack-ps

# Remove the entire stack (external volumes are preserved)
make stack-rm

# Create secrets interactively
make stack-secrets-init

# List secret names
make stack-secrets-list

# Scale a service (e.g., increase php to 3 replicas)
docker --context vps service scale nikeflow_php=3

# Force re-run entrypoint (e.g., after config change without image change)
docker --context vps service update --force nikeflow_php
```

---

## 13. Troubleshooting

### Service stuck in `Pending`
```bash
docker --context vps service ps nikeflow_php --no-trunc
# Look for: "no suitable node" or "insufficient memory/cpu"
# Single-node Swarm: ensure DB is placed on manager node (already constrained in stack file)
```

### Image pull failure (401 Unauthorized)
The `--with-registry-auth` flag in the deploy command passes GHCR credentials from the CI runner to Swarm nodes. If pulling fails on the VPS itself (e.g., manual deploy), authenticate once:
```bash
echo $GITHUB_PAT | docker --context vps login ghcr.io -u <username> --password-stdin
```

### `APP_KEY not set` error in php container
Verify the secret exists and is attached to the service:
```bash
docker --context vps secret ls
docker --context vps service inspect nikeflow_php \
  --format '{{json .Spec.TaskTemplate.ContainerSpec.Secrets}}'
```

### Caddy ACME rate limit
Caddy stores certificates in the `caddy_data` named volume. If the volume is deleted and recreated too many times, Let's Encrypt rate limits apply (5 certificates/domain/week). For testing, add this to the global options in `Caddyfile` to use the staging ACME server:
```
{
    acme_ca https://acme-staging-v02.api.letsencrypt.org/directory
}
```
Remove it before going live.

### `docker stack deploy` variable substitution not working
`PHP_IMAGE` and `NGINX_IMAGE` must be exported in the shell before running `stack deploy`. Unset variables produce an empty image name and a cryptic pull failure.
```bash
# Check they are set
echo $PHP_IMAGE
echo $NGINX_IMAGE
```

### MySQL container exits on first start
Check that all three MySQL secrets (`db_username`, `db_password`, `mysql_root_password`) exist on the Swarm:
```bash
docker --context vps secret ls
```
MySQL reads these via `MYSQL_*_FILE` env vars in its entrypoint. If any secret is missing, the MySQL container will not start.
