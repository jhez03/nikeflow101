# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Local Development
```bash
composer run setup   # one-time: install deps, run migrations, build assets
composer run dev     # starts Laravel server + queue worker + log viewer + Vite HMR concurrently
composer run test    # run full Pest test suite
```

### Individual commands
```bash
npm run build                              # production Vite asset build
php artisan pint                           # format PHP code
./vendor/bin/pest --filter <TestName>      # run a single test
php artisan migrate                        # run pending migrations
php artisan tinker                         # Laravel REPL
```

### Docker (run from `infra/` directory)
```bash
make up        # start all containers (PHP-FPM, Nginx, MySQL, PHPMyAdmin)
make down      # stop containers and remove volumes
make build     # rebuild containers
make shell     # open shell in PHP container
make migrate   # run migrations inside container
make key       # generate Laravel app key
```

PHPMyAdmin is available at `http://localhost:8080` when Docker is running.

## Architecture

This is a **Laravel 13 + Vue 3 + Inertia.js fullstack monolith** — there is no REST API layer. Laravel routes return `Inertia::render()` calls, which serve Vue page components with props directly, enabling SPA-style navigation without a separate API.

### Request flow
```
Request → Nginx → PHP-FPM → routes/web.php → Controller
  → Inertia::render('Pages/ComponentName', ['prop' => $value])
  → Vue 3 mounts in browser with props injected
  → Client-side navigation via Inertia (no full page reloads)
```

### Key directories
| Path | Purpose |
|------|---------|
| `app/Http/Controllers/` | Route handlers; return `Inertia::render()` or redirects |
| `app/Http/Middleware/HandleInertiaRequests.php` | Injects shared props (auth user, flash) into every page |
| `app/Http/Requests/` | Form request validation classes |
| `app/Models/` | Eloquent models |
| `resources/js/Pages/` | Inertia page components (one per route) |
| `resources/js/Components/` | Reusable Vue components |
| `routes/web.php` | Main web routes |
| `routes/auth.php` | Auth routes (Breeze-generated) |
| `database/migrations/` | Schema migrations |
| `infra/` | Docker, Nginx, Makefile, CI configs |

### Shared data
Global data available on every page (auth user, CSRF, flash messages) is injected in `HandleInertiaRequests::share()`. Add new globally-shared data there, not in individual controllers.

### Authentication
Uses **Laravel Breeze + Sanctum**. Auth routes and controllers live in `routes/auth.php` and `app/Http/Controllers/Auth/`. The `auth` middleware and `verified` middleware are applied in route groups in `routes/web.php`.

### Frontend build
Vite is configured in `vite.config.js` with the Laravel Vite plugin. In Docker, the Vite dev server runs inside the container — see `infra/readme.md` for HMR configuration notes.

## Testing

Tests use **Pest PHP** with the Laravel plugin. Feature tests are in `tests/Feature/`, unit tests in `tests/Unit/`. The test database uses SQLite in-memory by default (check `phpunit.xml`).

## CI/CD

- `.github/workflows/ci.yml` — runs Pint linting, Pest tests, and Vite build on every push
- `.github/workflows/cd-staging.yml` — deploys to staging on merge
