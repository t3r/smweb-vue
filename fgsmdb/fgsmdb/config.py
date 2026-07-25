"""Configuration loader — reads .env and provides settings to all modules."""

import os
from dotenv import load_dotenv


def load_config(env_file: str | None = None) -> dict:
    """Load configuration from .env file and environment variables.

    Args:
        env_file: Path to .env file. If None, searches in current directory
                  and parent directories.

    Returns:
        Dictionary with all configuration values.
    """
    if env_file:
        load_dotenv(env_file)
    else:
        load_dotenv()

    config = {
        "pguri": os.environ["PGURI"],
        "fgelev_path": os.environ.get("FGELEV_PATH", "/usr/local/bin/fgelev"),
        "fg_root": os.environ.get("FG_ROOT", "/app/data"),
        "fg_scenery": os.environ.get("FG_SCENERY", "./fgscenery"),
        "fg_scenery_export": os.environ.get("FG_SCENERY_EXPORT", "./export"),
        "groundnets_path": os.environ.get("GROUNDNETS_PATH", "./groundnets"),
        "min_updates": int(os.environ.get("MIN_UPDATES", "1")),
        "sync_targets": [
            t.strip()
            for t in os.environ.get("SYNC_TARGETS", "").split(",")
            if t.strip()
        ],
        "cdn_invalidate_cmd": os.environ.get("CDN_INVALIDATE_CMD", ""),
    }
    return config
