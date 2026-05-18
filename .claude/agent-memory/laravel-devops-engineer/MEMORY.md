# Memory Index

- [Caddy Health Check Host Header Fix](project_caddy_healthcheck.md) — bare :80 block required so wget Host:localhost reaches /health; named site blocks won't match
- [Caddy External Volumes](project_caddy_external_volumes.md) — caddy_data/caddy_config must be external to survive --prune deploys and avoid ACME re-runs every deploy
