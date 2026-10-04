"""Local integration and small unit checks; run inside the API container."""

import json
import logging
import unittest
from decimal import Decimal
from unittest.mock import patch
from urllib.error import HTTPError
from urllib.request import Request, urlopen

from fastapi import HTTPException
from sqlalchemy import text

from app.database import engine
from app.main import JsonFormatter, health


BASE_URL = "http://localhost:8000"


def request(method: str, path: str, payload: dict | None = None):
    body = json.dumps(payload).encode() if payload is not None else None
    headers = {"Content-Type": "application/json"} if body is not None else {}
    req = Request(BASE_URL + path, data=body, headers=headers, method=method)
    try:
        with urlopen(req, timeout=5) as response:
            raw = response.read()
            return response.status, json.loads(raw) if raw else None
    except HTTPError as error:
        raw = error.read()
        return error.code, json.loads(raw) if raw else None


class ProductsIntegrationTests(unittest.TestCase):
    def test_health_checks_database(self):
        self.assertEqual(request("GET", "/health"), (200, {"status": "ok"}))

    def test_crud_persists_in_postgresql(self):
        status, created = request(
            "POST", "/products", {"name": "Integration test", "price": "1.25"}
        )
        self.assertEqual(status, 201)
        product_id = created["id"]
        self.addCleanup(request, "DELETE", f"/products/{product_id}")
        self.assertEqual(created["price"], "1.25")
        self.assertIn("created_at", created)

        with engine.connect() as connection:
            row = connection.execute(
                text("SELECT name, price FROM products WHERE id = :id"),
                {"id": product_id},
            ).one()
        self.assertEqual(row.name, "Integration test")
        self.assertEqual(row.price, Decimal("1.25"))

        status, products = request("GET", "/products")
        self.assertEqual(status, 200)
        self.assertIn(product_id, [product["id"] for product in products])
        self.assertEqual(request("GET", f"/products/{product_id}"), (200, created))

        status, updated = request(
            "PUT", f"/products/{product_id}", {"name": "Updated", "price": "2.50"}
        )
        self.assertEqual(status, 200)
        self.assertEqual((updated["name"], updated["price"]), ("Updated", "2.50"))
        with engine.connect() as connection:
            row = connection.execute(
                text("SELECT name, price FROM products WHERE id = :id"),
                {"id": product_id},
            ).one()
        self.assertEqual((row.name, row.price), ("Updated", Decimal("2.50")))

        self.assertEqual(request("DELETE", f"/products/{product_id}"), (204, None))
        self.assertEqual(request("GET", f"/products/{product_id}")[0], 404)
        with engine.connect() as connection:
            remaining = connection.scalar(
                text("SELECT count(*) FROM products WHERE id = :id"),
                {"id": product_id},
            )
        self.assertEqual(remaining, 0)

    def test_missing_product_is_404_for_read_update_and_delete(self):
        missing = 2147483647
        self.assertEqual(request("GET", f"/products/{missing}")[0], 404)
        self.assertEqual(
            request("PUT", f"/products/{missing}", {"name": "X", "price": "1.00"})[0],
            404,
        )
        self.assertEqual(request("DELETE", f"/products/{missing}")[0], 404)

    def test_invalid_product_input_is_rejected(self):
        for payload in (
            {"name": "", "price": "1.00"},
            {"name": "X", "price": "0"},
            {"name": "X", "price": "-1"},
            {"name": "X", "price": "1.234"},
            {"name": "X", "price": "123456789.00"},
        ):
            with self.subTest(payload=payload):
                self.assertEqual(request("POST", "/products", payload)[0], 422)
        self.assertEqual(request("GET", "/products/not-an-id")[0], 422)

    def test_migration_is_current(self):
        with engine.connect() as connection:
            revision = connection.scalar(text("SELECT version_num FROM alembic_version"))
            table = connection.scalar(text("SELECT to_regclass('public.products')"))
        self.assertEqual(revision, "20260909_01")
        self.assertEqual(table, "products")


class ApplicationUnitTests(unittest.TestCase):
    def test_health_returns_503_when_database_fails(self):
        class BrokenSession:
            def execute(self, _query):
                raise ConnectionError("simulated database outage")

        with patch("app.main.logger.exception") as log_exception:
            with self.assertRaises(HTTPException) as raised:
                health(BrokenSession())
        self.assertEqual(raised.exception.status_code, 503)
        self.assertEqual(raised.exception.detail, "Database unavailable")
        log_exception.assert_called_once_with("database_health_check_failed")

    def test_logging_is_structured_json(self):
        record = logging.LogRecord(
            "products_api", logging.INFO, __file__, 1, "request_completed", (), None
        )
        record.method = "GET"
        record.path = "/health"
        record.status_code = 200
        record.duration_ms = 1.25
        entry = json.loads(JsonFormatter().format(record))
        self.assertEqual(entry["message"], "request_completed")
        self.assertEqual(entry["level"], "INFO")
        self.assertEqual(entry["path"], "/health")
        self.assertEqual(entry["status_code"], 200)
        self.assertEqual(entry["duration_ms"], 1.25)
        self.assertIn("timestamp", entry)

if __name__ == "__main__":
    unittest.main(verbosity=2)
