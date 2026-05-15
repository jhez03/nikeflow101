COMPOSE_BASE = docker compose -f docker-compose.yml
COMPOSE_DEV  = docker compose -f docker-compose.yml -f docker-compose.dev.yml

up:
	$(COMPOSE_DEV) up -d

down:
	$(COMPOSE_DEV) down -v

build:
	$(COMPOSE_DEV) up -d --build

shell:
	$(COMPOSE_BASE) exec php sh

key:
	$(COMPOSE_BASE) exec php php artisan key:generate

migrate:
	$(COMPOSE_BASE) exec php php artisan migrate

# Fresh Breeze setup — correct order
install-breeze:
	$(COMPOSE_BASE) up -d php db
	@echo "⏳ Waiting for DB to be healthy..."
	@until docker compose -f docker-compose.yml exec db mysqladmin ping -h localhost --silent; do sleep 2; done
	# $(COMPOSE_BASE) exec php php artisan key:generate
	$(COMPOSE_BASE) exec php composer require laravel/breeze --dev
	$(COMPOSE_BASE) exec php php artisan breeze:install
	$(COMPOSE_DEV) up -d node nginx
	@echo "✅ Done. Visit http://localhost"

#laravel php artisan commands
artisan-%:
	$(COMPOSE_BASE) exec php php artisan $*

# ── Docker Swarm stack operations ─────────────────────────────────────────────
# Prerequisites before first deploy:
#   1. Create context:         make stack-context-create VPS_HOST=<ip>
#   2. Init Swarm on VPS:      docker --context vps swarm init
#   3. Create external volume: docker --context vps volume create nikeflow_db_data
#   4. Create secrets:         make stack-secrets-init
# Then deploy: make stack-deploy PHP_IMAGE=ghcr.io/.../php:sha-xxx NGINX_IMAGE=ghcr.io/.../nginx:sha-xxx

STACK_NAME = nikeflow
STACK_FILE = infra/docker-stack.yml
DOCKER_CTX = docker --context vps

stack-deploy: ## Deploy or update the stack (PHP_IMAGE and NGINX_IMAGE must be set)
	@test -n "$(PHP_IMAGE)"   || (echo "ERROR: PHP_IMAGE is not set"   && exit 1)
	@test -n "$(NGINX_IMAGE)" || (echo "ERROR: NGINX_IMAGE is not set" && exit 1)
	$(DOCKER_CTX) stack deploy \
		--compose-file $(STACK_FILE) \
		--with-registry-auth \
		--prune \
		$(STACK_NAME)

stack-ps: ## List all running tasks in the stack
	$(DOCKER_CTX) stack ps $(STACK_NAME)

stack-services: ## Show all services with replica counts
	$(DOCKER_CTX) service ls --filter label=com.docker.stack.namespace=$(STACK_NAME)

stack-logs: ## Tail logs for a service. Usage: make stack-logs SERVICE=php
	$(DOCKER_CTX) service logs -f $(STACK_NAME)_$(SERVICE)

stack-rollback: ## Manually rollback a service. Usage: make stack-rollback SERVICE=php
	$(DOCKER_CTX) service rollback $(STACK_NAME)_$(SERVICE)

stack-rm: ## DANGER: remove the entire stack (external volumes are preserved)
	@read -p "Remove stack $(STACK_NAME)? Type 'yes' to confirm: " c && [ "$$c" = "yes" ]
	$(DOCKER_CTX) stack rm $(STACK_NAME)

stack-context-create: ## Create Docker context pointing to VPS. Usage: make stack-context-create VPS_HOST=1.2.3.4
	@test -n "$(VPS_HOST)" || (echo "ERROR: VPS_HOST is not set" && exit 1)
	docker context create vps --docker "host=ssh://deploy@$(VPS_HOST)"
	@echo "Context created. Test with: docker --context vps info"

stack-secrets-init: ## Interactively create all required Swarm secrets on the remote VPS
	@printf "app_key value (paste base64:... APP_KEY): "; read -rs v; echo; printf "%s" "$$v" | $(DOCKER_CTX) secret create app_key -
	@printf "db_password value: "; read -rs v; echo; printf "%s" "$$v" | $(DOCKER_CTX) secret create db_password -
	@printf "db_username value: "; read -rs v; echo; printf "%s" "$$v" | $(DOCKER_CTX) secret create db_username -
	@printf "mysql_root_password value: "; read -rs v; echo; printf "%s" "$$v" | $(DOCKER_CTX) secret create mysql_root_password -
	@echo "All secrets created. Verify with: make stack-secrets-list"

stack-secrets-list: ## List secret names on the remote Swarm (values are never shown)
	$(DOCKER_CTX) secret ls

