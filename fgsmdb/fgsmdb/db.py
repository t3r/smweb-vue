"""Database connection helper with automatic reconnect."""

import logging
import psycopg2
import psycopg2.extras

logger = logging.getLogger(__name__)


class Database:
    """Thin wrapper around psycopg2 with reconnect logic."""

    def __init__(self, pguri: str):
        self.pguri = pguri
        self._conn = None

    def connect(self):
        """Establish database connection."""
        if self._conn is None or self._conn.closed:
            logger.info("Connecting to database...")
            self._conn = psycopg2.connect(self.pguri)
            self._conn.autocommit = True
        return self._conn

    @property
    def conn(self):
        return self.connect()

    def cursor(self):
        """Return a DictCursor, reconnecting if needed."""
        return self.conn.cursor(cursor_factory=psycopg2.extras.DictCursor)

    def execute(self, sql: str, params=None, retries: int = 3):
        """Execute a query with automatic reconnect on OperationalError.

        Returns:
            List of result rows, or empty list for non-SELECT statements.
        """
        for attempt in range(retries):
            try:
                cur = self.cursor()
                cur.execute(sql, params)
                if cur.description:
                    return cur.fetchall()
                return []
            except psycopg2.OperationalError:
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
        cur = self.cursor()
        for stmt in statements:
            cur.execute(stmt)

    def close(self):
        """Close the database connection."""
        if self._conn and not self._conn.closed:
            self._conn.close()
            self._conn = None
