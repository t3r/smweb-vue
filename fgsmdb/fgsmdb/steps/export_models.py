"""Export models step — extract 3D model files from the database.

Equivalent to the legacy exportmodels.py script.
Exports shared models (to Models/) and per-hemisphere object models (to Objects/).
"""

import base64
import io
import logging
import os
import tarfile
from ..db import Database

logger = logging.getLogger(__name__)


def run(db: Database, target: str, incremental: bool = False):
    """Export all models: shared models + east/west hemisphere objects.

    Args:
        db: Database connection wrapper.
        target: Target directory for exported files.
        incremental: If True, only export when new models exist.
    """
    os.makedirs(target, exist_ok=True)

    if incremental and not _has_new_models(db):
        logger.info("No new models to export (incremental mode).")
        return

    _export_shared_models(db, target)
    _export_hemisphere_models(db, target, "west")
    _export_hemisphere_models(db, target, "east")


def _has_new_models(db: Database) -> bool:
    """Check if there are new models since the last export timestamp."""
    rows = db.execute(
        """SELECT count(*) AS cnt FROM fgs_models
           WHERE mo_modified > (SELECT max(ti_stamp) FROM fgs_timestamps WHERE ti_type=1)"""
    )
    return rows[0]["cnt"] > 0 if rows else False


def _export_shared_models(db: Database, target: str):
    """Export shared models (mo_shared > 0) to Models/ subdirectory."""
    logger.info("Exporting shared models...")

    rows = db.execute(
        """SELECT m.mo_id AS id,
                  concat('Models/', g.mg_path) AS path,
                  m.mo_modelfile AS modelfile
           FROM fgs_models AS m
           LEFT JOIN fgs_modelgroups AS g ON m.mo_shared = g.mg_id
           WHERE m.mo_shared > 0"""
    )

    count = 0
    for row in rows:
        _extract_model(row, target)
        count += 1

    logger.info("Exported %d shared models.", count)


def _export_hemisphere_models(db: Database, target: str, hemisphere: str):
    """Export per-object models for a hemisphere.

    Args:
        hemisphere: "east" or "west"
    """
    constraint = ">= 0" if hemisphere == "east" else "< 0"
    logger.info("Exporting %s hemisphere models...", hemisphere)

    rows = db.execute(
        f"""SELECT m.mo_id AS id,
                   concat('Objects/', fn_SceneDir(o.wkb_geometry), '/', fn_SceneSubDir(o.wkb_geometry), '/') AS path,
                   m.mo_modelfile AS modelfile
            FROM fgs_objects AS o
            LEFT JOIN fgs_models AS m ON o.ob_model = m.mo_id
            WHERE o.ob_gndelev > -9999 AND m.mo_shared = 0 AND ST_X(o.wkb_geometry) {constraint}"""
    )

    count = 0
    for row in rows:
        _extract_model(row, target)
        count += 1

    logger.info("Exported %d %s hemisphere models.", count, hemisphere)


def _extract_model(row, target: str):
    """Decode and extract a model's tar.gz archive to the target path."""
    model_path = row["path"]
    full_path = os.path.join(target, model_path)

    os.makedirs(full_path, exist_ok=True)

    try:
        tar_bytes = io.BytesIO(base64.b64decode(row["modelfile"]))
        with tarfile.open(fileobj=tar_bytes, mode="r:gz") as tar:
            tar.extractall(path=full_path)
    except Exception as e:
        logger.warning("Failed to extract model %s: %s", row["id"], e)
