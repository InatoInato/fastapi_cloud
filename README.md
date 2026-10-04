# AWS FastAPI playground

A deliberately small FastAPI + PostgreSQL application for learning Docker,
networking, AWS, and Terraform.

## Local architecture

```text
Browser/curl -> localhost:8000 -> api container -> db:5432 -> PostgreSQL container
                                      |
                                      +-> JSON logs to stdout
```

Compose creates one private network. The API reaches PostgreSQL using the service
name `db`; `localhost` inside the API container would point back to the API
container, not PostgreSQL.

## Run

Docker Desktop or another Docker engine must be running.

```bash
docker compose up --build
```

Then open <http://localhost:8000/docs> or check:

```bash
curl http://localhost:8000/health
```

No local PostgreSQL or `psql` installation is required. To use the client inside
the database container:

```bash
docker compose exec db psql -U app -d products
```

## CRUD examples

```bash
curl -X POST http://localhost:8000/products \
  -H 'Content-Type: application/json' \
  -d '{"name":"Keyboard","price":"89.90"}'

curl http://localhost:8000/products
curl http://localhost:8000/products/1

curl -X PUT http://localhost:8000/products/1 \
  -H 'Content-Type: application/json' \
  -d '{"name":"Mechanical keyboard","price":"109.90"}'

curl -X DELETE http://localhost:8000/products/1
```

Stop containers while preserving data:

```bash
docker compose down
```

Delete containers and the PostgreSQL data volume:

```bash
docker compose down -v
```

## Configuration

Compose has local defaults, so `docker compose up` works immediately.
Copy `.env.example` to `.env` only when you want to override them. PostgreSQL
is only reachable on the Compose network; use `docker compose exec db psql` to
inspect it. Source changes require `docker compose up --build` to rebuild the
API image.

## First Terraform lab

See [terraform/README.md](terraform/README.md) for the step-by-step EC2 lab.
It uses the same Compose project on one small VM. Terraform is not applied
automatically; review the plan and AWS costs before creating resources.
