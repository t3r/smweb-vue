"""Export command — orchestrates the full scenemodels export pipeline.

Usage:
    python3 -m fgsmdb export [--env-file .env] [--steps sanitize,gndelev,export,mkdiridx,upload,distribute]
    python3 -m fgsmdb export --all
    python3 -m fgsmdb export --steps export,mkdiridx

Available steps:
    sanitize   - Fix data integrity (tile numbers, elevation offsets)
    gndelev    - Compute ground elevations using fgelev
    export     - Export models and STG files from the database
    mkdiridx   - Create .dirindex files and Airports archive
    upload     - Sync export directory to local scenery tree
    distribute - Rsync scenery to mirror servers
"""

import logging
import os
import tarfile

from ..config import load_config
from ..db import Database
from ..steps import sanitize, gndelev, export_models, export_stg, dirindex, sync, rsync_distribute

ALL_STEPS = ["sanitize", "gndelev", "export", "mkdiridx", "upload"]
VALID_STEPS = ALL_STEPS + ["distribute"]

logger = logging.getLogger(__name__)


def register(subparsers):
    """Register the export subcommand with the argument parser."""
    parser = subparsers.add_parser(
        "export",
        help="Export scenemodels database to TerraSync file tree",
        description="Export the FlightGear scenemodels database into a "
                    "TerraSync-compatible file tree and optionally distribute to mirrors.",
    )
    parser.add_argument(
        "--env-file",
        default=None,
        help="Path to .env file (default: auto-detect)",
    )
    parser.add_argument(
        "--steps",
        default=None,
        help="Comma-separated list of steps to run (default: all except distribute)",
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="Run all steps (equivalent to: %s)" % ",".join(ALL_STEPS),
    )
    parser.add_argument(
        "--skip-check",
        action="store_true",
        help="Skip the pending-updates threshold check",
    )
    parser.add_argument(
        "--min-updates",
        type=int,
        default=None,
        help="Override MIN_UPDATES threshold from .env",
    )
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Enable debug logging",
    )
    parser.set_defaults(func=run)


def run(args):
    """Execute the export pipeline."""
    # Setup logging
    log_level = logging.DEBUG if args.verbose else logging.INFO
    logging.basicConfig(
        level=log_level,
        format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )

    # Load configuration
    config = load_config(args.env_file)

    # Determine which steps to run
    if args.steps:
        steps = [s.strip() for s in args.steps.split(",")]
        for s in steps:
            if s not in VALID_STEPS:
                logger.error("Unknown step: %s. Valid steps: %s", s, ", ".join(VALID_STEPS))
                raise SystemExit(1)
    else:
        steps = ALL_STEPS

    # Override min_updates if specified
    min_updates = args.min_updates if args.min_updates is not None else config["min_updates"]

    # Connect to the database
    db = Database(config["pguri"])

    try:
        # Always update statistics first
        logger.info("Updating statistics...")
        db.execute("SELECT fn_update_statistics()")

        # Check if there are enough pending updates
        if not args.skip_check:
            rows = db.execute(
                "SELECT count(*) AS cnt FROM fgs_objects WHERE ob_gndelev = -9999"
            )
            count = rows[0]["cnt"] if rows else 0
            logger.info("Pending model updates: %d (minimum: %d)", count, min_updates)
            if count < min_updates:
                logger.info("Not enough pending updates. Exiting.")
                return

        # Run pipeline steps
        if "sanitize" in steps:
            sanitize.run(db)

        if "gndelev" in steps:
            gndelev.run(
                db,
                fgelev_path=config["fgelev_path"],
                fg_root=config["fg_root"],
                fg_scenery=config["fg_scenery"],
            )

        if "export" in steps:
            export_models.run(db, target=config["fg_scenery_export"])
            export_stg.run(db, target=config["fg_scenery_export"])

        if "mkdiridx" in steps:
            dirindex.create_root_dirindex(
                fg_scenery=config["fg_scenery"],
                fg_scenery_export=config["fg_scenery_export"],
            )

        if "upload" in steps:
            sync.run(
                fg_scenery_export=config["fg_scenery_export"],
                fg_scenery=config["fg_scenery"],
            )

        # Update statistics after export
        if any(s in steps for s in ("export", "upload")):
            db.execute("SELECT fn_update_statistics()")

        # Create SharedModels tarball
        if "upload" in steps:
            _create_shared_models_tarball(config["fg_scenery"])

        # Distribution (rsync to mirrors)
        if "distribute" in steps:
            rsync_distribute.run(
                fg_scenery=config["fg_scenery"],
                sync_targets=config["sync_targets"],
                cdn_invalidate_cmd=config["cdn_invalidate_cmd"],
            )

        logger.info("Export pipeline complete.")

    finally:
        db.close()


def _create_shared_models_tarball(fg_scenery: str):
    """Create SharedModels.txz from the Models directory."""
    models_path = os.path.join(fg_scenery, "Models")
    output_path = os.path.join(fg_scenery, "SharedModels.txz")

    if not os.path.isdir(models_path):
        logger.warning("No Models directory at %s, skipping tarball.", models_path)
        return

    logger.info("Creating SharedModels.txz...")
    with tarfile.open(output_path, "w:xz") as tar:
        tar.add(models_path, arcname="Models")
    logger.info("SharedModels.txz created at %s", output_path)
