"""Database connection helper with automatic reconnect."""

import logging
import psycopg
from psycopg.rows import dict_row

logger = logging.getLogger(__name__)


class Database:
    """Thin wrapper around psycopg (v3) with reconnect logic."""

    def __init__(self, pguri: str):
        self.pguri = pguri
        self._conn = None

    def connect(self):
        """Establish database connection."""
        if self._conn is None or self._conn.closed:
            logger.info("Connecting to database...")
            self._conn = psycopg.connect(self.pguri, autocommit=True, row_factory=dict_row)
        return self._conn

    @property
    def conn(self):
        return self.connect()

    def execute(self, sql: str, params=None, retries: int = 3):
        """Execute a query with automatic reconnect on OperationalError.

        Returns:
            List of result rows as dicts, or empty list for non-SELECT statements.
        """
        for attempt in range(retries):
            try:
                with self.conn.cursor() as cur:
                    cur.execute(sql, params)
                    if cur.description:
                        return cur.fetchall()
                    return []
            except psycopg.OperationalError:
                logger.warning(
                    "Database connection lost (attempt %d/%d), reconnecting...",
                    attempt + 1,
                    retries,
                )
                self._conn = None
                if attempt == retries - 1:
                    raise

    def execute_batch(self, statements: list[str]):
        """Execute multiple SQL statements in sequence."""
        with self.conn.cursor() as cur:
            for stmt in statements:
                cur.execute(stmt)

    def close(self):
        """Close the database connection."""
        if self._conn and not self._conn.closed:
            self._conn.close()
            self._conn = None
