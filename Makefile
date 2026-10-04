.PHONY: up down test

up:
	docker compose up --build -d

down:
	docker compose down

test:
	docker compose exec -T api python - < scripts/test_app.py
	docker compose config --quiet
	docker compose -f docker-compose.external-db.yml --env-file .env.external.example config --quiet
