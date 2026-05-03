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

