---
name: caddy-external-volumes
description: caddy_data and caddy_config must be external volumes to survive stack deploys and prevent ACME re-runs
metadata:
  type: project
---

`docker stack deploy --prune` recreates any non-external named volumes. Before this fix, `caddy_data` and `caddy_config` were ephemeral, so every deploy wiped the Let's Encrypt cert store and forced Caddy to re-run ACME HTTP-01 (10–60s extra startup). Combined with the short `start_period: 10s`, this created a second race window causing the Swarm health check to fail.

**Fix applied:**
- `caddy_data` and `caddy_config` are now `external: true` in `infra/docker-stack.yml`
- `start_period` for the caddy healthcheck increased from 10s to 60s
- `infra/Makefile` gains `stack-volumes-init` target that creates all three external volumes (`nikeflow_db_data`, `nikeflow_caddy_data`, `nikeflow_caddy_config`) via the `vps` Docker context

**Why:** Ephemeral Caddy volumes caused ACME re-runs on every deploy, adding startup time that exceeded the health check window.

**How to apply:** Before first deploy on any new VPS, run `make -C infra stack-volumes-init`. The prerequisite comment block at the top of the Swarm section in the Makefile documents this as step 3.

**Related:** [[caddy-healthcheck-host-header-fix]] — Host header mismatch was the primary cause of the same timeout.
