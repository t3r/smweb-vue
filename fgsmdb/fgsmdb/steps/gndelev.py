"""Ground elevation step — compute ground elevation for new objects using fgelev.

Equivalent to the legacy gndelev.sh script.

This step requires fgelev reachable in one of three ways:
- Local binary (FGELEV_PATH)
- Docker container (FGELEV_DOCKER_IMAGE)
- Remote TCP service (FGELEV_TCP_HOST / FGELEV_TCP_PORT)
"""

import logging
import os

from ..db import Database
from ..fgelev import FgElevDaemon

logger = logging.getLogger(__name__)


def run(
    db: Database,
    fgelev_path: str,
    fg_root: str,
    fg_scenery: str,
    docker_image: str | None = None,
    tcp_host: str | None = None,
    tcp_port: int = 9000,
):
    """Compute ground elevations for objects with ob_gndelev = -9999.

    Queries unprocessed objects from the DB, streams their coordinates
    through a persistent fgelev daemon (so terrain tiles stay cached),
    then updates the database with computed elevations.

    Mode selection (first match wins):
        1. tcp_host set  → connect to remote fgelev TCP service
        2. docker_image set → spawn fgelev via docker run
        3. otherwise → run fgelev as a local binary

    Args:
        db: Database connection wrapper.
        fgelev_path: Path to the fgelev binary (local or inside container).
        fg_root: FG_ROOT path — not used in TCP mode (configured server-side).
        fg_scenery: FG_SCENERY path — not used in TCP mode.
        docker_image: Docker image to run fgelev in (optional).
        tcp_host: Hostname/IP of a remote fgelev TCP service (optional).
        tcp_port: TCP port of the remote service (default: 9000).
    """
    if tcp_host:
        daemon = FgElevDaemon.tcp(tcp_host, tcp_port)
        logger.info("Using remote fgelev service at %s:%d", tcp_host, tcp_port)
    else:
        terrain_path = os.path.join(fg_scenery, "Terrain")
        if not os.path.isdir(terrain_path):
            logger.error("No Terrain found in %s. Skipping gndelev.", fg_scenery)
            return
        if docker_image:
            daemon = FgElevDaemon.docker(docker_image, fg_root, fg_scenery, fgelev_path)
            logger.info("Using fgelev from Docker image: %s", docker_image)
        else:
            daemon = FgElevDaemon.local(fgelev_path, fg_root, fg_scenery)

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
    update_count = 0

    try:
        with daemon as fgelev:
            for row in rows:
                ob_id = row["ob_id"]
                elevation = fgelev.query(ob_id, row["lon"], row["lat"])

                if elevation is None:
                    logger.warning("No elevation result for ob_id=%s, skipping.", ob_id)
                    continue

                db.execute(
                    "UPDATE fgs_objects SET ob_gndelev = %s WHERE ob_id = %s AND ob_gndelev = -9999",
                    (elevation, ob_id),
                )
                update_count += 1

    except (FileNotFoundError, ConnectionRefusedError, OSError) as exc:
        logger.error("Could not reach fgelev: %s", exc)
        return

    logger.info("Updated ground elevation for %d objects.", update_count)
