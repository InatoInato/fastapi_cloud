# AWS FastAPI playground

Small Product API for learning Docker, networking, AWS, and Terraform.

```text
localhost:8000 -> API container -> db:5432 -> PostgreSQL volume
                       └-> JSON logs to stdout
```

Inside Compose, the API connects to the database by hostname `db`. PostgreSQL
is not published on a host port.

## Run and test

```bash
make up
docker compose ps
curl http://localhost:8000/health
make test
docker compose logs --tail=30 api
```

Wait until `api` is healthy in `docker compose ps` before running tests.
`make test` checks CRUD against PostgreSQL, migration state, validation, health,
logging, and both Compose configurations. Inspect the database with
`docker compose exec db psql -U app -d products`. Open
<http://localhost:8000/docs> to try the API manually.

Stop the app and keep local database data with `make down`. To delete the local
database volume too, run `docker compose down -v`.

## External PostgreSQL

For a later RDS lab, copy `.env.external.example` to `.env.external`, set the
real database URL, then run migrations and the API with:

```bash
docker compose -f docker-compose.external-db.yml --env-file .env.external run --rm api alembic upgrade head
docker compose -f docker-compose.external-db.yml --env-file .env.external up --build -d
```

Keep `.env.external` private. The example values do not connect to a real DB.

## AWS

Start with [the first Terraform lab](infra/README.md). Run Terraform directly
from `infra/`; add one AWS resource at a time and inspect each plan.
