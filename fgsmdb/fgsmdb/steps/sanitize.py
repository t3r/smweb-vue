"""Sanitize step — fix data integrity issues in the database.

Equivalent to the legacy sanitize.sh script.
"""

import logging
from ..db import Database

logger = logging.getLogger(__name__)


def run(db: Database):
    """Fix tile numbers and elevation offsets in the database."""
    logger.info("Running sanitize...")

    statements = [
        # Update object tile numbers where they don't match geometry
        """UPDATE fgs_objects SET ob_tile = fn_GetTileNumber(wkb_geometry)
           WHERE ob_tile != fn_GetTileNumber(wkb_geometry) OR ob_tile IS NULL""",
        # Update sign tile numbers where invalid
        """UPDATE fgs_signs SET si_tile = fn_GetTileNumber(wkb_geometry)
           WHERE si_tile < 1 OR si_tile IS NULL""",
        # Nullify zero elevation offsets
        """UPDATE fgs_objects SET ob_elevoffset = NULL
           WHERE ob_elevoffset = 0""",
    ]

    for stmt in statements:
        logger.debug("Executing: %s", stmt.strip()[:80])
        db.execute(stmt)

    logger.info("Sanitize complete.")
