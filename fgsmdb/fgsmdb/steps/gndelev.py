"""Ground elevation step — compute ground elevation for new objects using fgelev.

Equivalent to the legacy gndelev.sh script.

This step requires:
- fgelev binary (from FlightGear/SimGear)
- Terrain data in FG_SCENERY
- FG_ROOT pointing to FlightGear data (defaults.xml)
"""

import logging
import os
import subprocess
from ..db import Database

logger = logging.getLogger(__name__)


def run(db: Database, fgelev_path: str, fg_root: str, fg_scenery: str):
    """Compute ground elevations for objects with ob_gndelev = -9999.

    Queries unprocessed objects from the DB, pipes their coordinates through
    fgelev, then updates the database with computed elevations.

    Args:
        db: Database connection wrapper.
        fgelev_path: Path to the fgelev binary.
        fg_root: FG_ROOT path (FlightGear data directory).
        fg_scenery: FG_SCENERY path (terrain data directory).
    """
    terrain_path = os.path.join(fg_scenery, "Terrain")
    if not os.path.isdir(terrain_path):
        logger.error("No Terrain found in %s. Skipping gndelev.", fg_scenery)
        return

    logger.info("Querying objects needing ground elevation...")
    rows = db.execute(
        """SELECT ob_id, ST_X(wkb_geometry) AS lon, ST_Y(wkb_geometry) AS lat
           FROM fgs_objects
           WHERE ob_valid IS true AND ob_gndelev = -9999
           ORDER BY ob_tile"""
    )

    if not rows:
        logger.info("No objects need ground elevation updates.")
        return

    logger.info("Computing ground elevation for %d objects...", len(rows))

    # Prepare input for fgelev: "id lon lat\n" per line
    fgelev_input = ""
    for row in rows:
        fgelev_input += f"{row['ob_id']} {row['lon']} {row['lat']}\n"

    # Run fgelev
    env = os.environ.copy()
    env["FG_ROOT"] = fg_root
    env["FG_SCENERY"] = fg_scenery

    try:
        result = subprocess.run(
            [fgelev_path],
            input=fgelev_input,
            capture_output=True,
            text=True,
            env=env,
        )
    except FileNotFoundError:
        logger.error("fgelev binary not found at %s", fgelev_path)
        return

    # fgelev may return non-zero on EOF, that's expected
    if result.stdout:
        _process_fgelev_output(db, result.stdout)
    else:
        logger.warning("fgelev produced no output. stderr: %s", result.stderr[:500])


def _process_fgelev_output(db: Database, output: str):
    """Parse fgelev output and update the database.

    fgelev output format: "id:elevation\n"
    """
    update_count = 0
    for line in output.strip().split("\n"):
        line = line.strip()
        if not line or ":" not in line:
            continue

        parts = line.split(":")
        if len(parts) != 2:
            continue

        try:
            ob_id = int(parts[0].strip())
            elevation = float(parts[1].strip())
        except ValueError:
            logger.warning("Could not parse fgelev output line: %s", line)
            continue

        db.execute(
            "UPDATE fgs_objects SET ob_gndelev = %s WHERE ob_id = %s AND ob_gndelev = -9999",
            (elevation, ob_id),
        )
        update_count += 1

    logger.info("Updated ground elevation for %d objects.", update_count)
