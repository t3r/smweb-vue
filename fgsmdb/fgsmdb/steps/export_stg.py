"""Export STG step — generate .stg files (object placement) for each scenery tile.

Equivalent to the legacy exportstg.py script.
"""

import logging
import os
from ..db import Database

logger = logging.getLogger(__name__)


def run(db: Database, target: str):
    """Generate all .stg files from the database.

    Queries all distinct tiles that have objects or signs, then generates
    an .stg file for each tile using the database function fn_DumpStgRows().

    Args:
        db: Database connection wrapper.
        target: Target directory for exported files.
    """
    logger.info("Querying tile list...")

    sql_path = "concat('Objects/', fn_SceneDir(wkb_geometry), '/', fn_SceneSubDir(wkb_geometry), '/') AS obpath"
    rows = db.execute(
        f"""SELECT DISTINCT fn_gettilenumber(o.wkb_geometry) AS tile, {sql_path}
            FROM fgs_objects AS o
            UNION
            SELECT DISTINCT fn_gettilenumber(s.wkb_geometry) AS tile, {sql_path}
            FROM fgs_signs AS s
            ORDER BY tile"""
    )

    num_tiles = len(rows)
    logger.info("Generating .stg files for %d tiles...", num_tiles)

    for i, row in enumerate(rows, 1):
        ob_path = row["obpath"]
        ob_tile = row["tile"]
        stg_file = f"{ob_tile}.stg"

        if i % 1000 == 0:
            logger.info("Progress: %d / %d tiles", i, num_tiles)

        # Get STG content from the database function
        stg_rows = db.execute("SELECT fn_DumpStgRows(%s)", (ob_tile,))

        if stg_rows and stg_rows[0][0]:
            parent = os.path.join(target, ob_path)
            os.makedirs(parent, exist_ok=True)

            stg_full_path = os.path.join(parent, stg_file)
            with open(stg_full_path, "w") as f:
                f.write(f"{stg_rows[0][0]}\n")

    logger.info("STG export complete: %d tiles processed.", num_tiles)
