---
name: caddy-healthcheck-host-header-fix
description: Caddy health check requires a bare :80 block because wget sends Host: localhost which doesn't match the named site block
metadata:
  type: project
---

The Caddy service healthcheck (`wget http://localhost/health`) sends `Host: localhost`. Caddy v2 routes by Host header, so a `/health` handle inside the `staging.thelaravelers.com` block is never reached — Caddy returns 404, the health check fails, and Swarm kills the container every ~60s (10s start_period + 3×15s retries).

**Fix applied:** Added a bare `:80` site block in `infra/Caddyfile` BEFORE the named site block. This catches any request where the Host header doesn't match a named site (i.e., container-internal health checks). Does not interfere with ACME HTTP-01.

**Why:** `docker stack deploy --prune` was triggering the kill/restart loop on every CI deploy, causing "Caddy rollout did not complete in 200s" errors in `.github/workflows/cicd-staging.yml`.

**How to apply:** Any time the Caddyfile gains a new named site block, keep the bare `:80` health block at the top. Never move `/health` inside a named site block.

**Related:** [[caddy-external-volumes]] — ephemeral caddy_data/caddy_config volumes were a secondary cause of the same timeout.
