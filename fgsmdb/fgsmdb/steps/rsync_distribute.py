"""Distribution step — rsync exported scenery to mirror servers.

Equivalent to the legacy sync.sh script.
This step shells out to rsync since it's the right tool for efficient
network file transfer. SSH configuration (host, user, key) is read from
~/.ssh/config as usual.
"""

import logging
import os
import subprocess
import shlex
from concurrent.futures import ThreadPoolExecutor, as_completed

logger = logging.getLogger(__name__)


def rsync_to_target(scenery_dir: str, target: str, items: list[str]) -> int:
    """Rsync specific items to a target.

    Args:
        scenery_dir: Local scenery directory (source).
        target: rsync target URI (e.g., "host:/path/").
        items: List of file/directory names to sync.

    Returns:
        rsync exit code.
    """
    cmd = [
        "rsync", "-av",
        "--no-owner", "--no-group", "--no-perms",
        "--delete", "--copy-links", "--omit-dir-times",
    ] + items + [target]

    logger.info("rsync to %s: %s", target, " ".join(items))
    result = subprocess.run(cmd, cwd=scenery_dir, capture_output=True, text=True)

    if result.returncode != 0:
        logger.error("rsync to %s failed: %s", target, result.stderr[:500])
    else:
        logger.info("rsync to %s complete.", target)

    return result.returncode


def run(fg_scenery: str, sync_targets: list[str], cdn_invalidate_cmd: str = ""):
    """Distribute scenery to all mirror targets.

    Args:
        fg_scenery: Local scenery directory.
        sync_targets: List of rsync target URIs.
        cdn_invalidate_cmd: Optional shell command to invalidate CDN.
    """
    if not sync_targets:
        logger.info("No sync targets configured. Skipping distribution.")
        return

    scenery_items = ["Objects", "Models", "Airports", ".dirindex", "Airports_archive.tgz"]
    tarball = "SharedModels.txz"

    with ThreadPoolExecutor(max_workers=len(sync_targets) * 2) as executor:
        futures = []

        for target in sync_targets:
            # Main scenery sync
            futures.append(
                executor.submit(rsync_to_target, fg_scenery, target, scenery_items)
            )

            # SharedModels tarball to parent directory
            tarball_path = os.path.join(fg_scenery, tarball)
            if os.path.isfile(tarball_path):
                parent_target = target.rsplit("/", 2)[0] + "/"
                futures.append(
                    executor.submit(rsync_to_target, fg_scenery, parent_target, [tarball])
                )

        for future in as_completed(futures):
            future.result()

    # Invalidate CDN if configured
    if cdn_invalidate_cmd:
        logger.info("Invalidating CDN: %s", cdn_invalidate_cmd)
        subprocess.run(shlex.split(cdn_invalidate_cmd), check=False)
