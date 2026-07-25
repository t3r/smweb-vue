"""Directory index generation — creates .dirindex files for TerraSync.

Equivalent to the legacy CreateDirectoryIndexes.py and mkdiridx.sh scripts.

TerraSync .dirindex format:
    version:1
    path:<relative_path>
    f:<filename>:<sha1>:<size>     (regular files)
    t:<filename>:<sha1>:<size>     (tar archives)
    d:<dirname>:<sha1_of_dirindex> (subdirectories)
"""

import hashlib
import logging
import os
import tarfile
from datetime import datetime, timezone

logger = logging.getLogger(__name__)

DIRINDEX_VERSION = 1
DIRINDEX_FILENAME = ".dirindex"


def sha1_of_file(path: str) -> str:
    """Compute SHA1 hash of a file."""
    h = hashlib.sha1()
    try:
        with open(path, "rb") as f:
            for chunk in iter(lambda: f.read(4096), b""):
                h.update(chunk)
    except OSError:
        pass
    return h.hexdigest()


def create_dirindex(path: str, parent: str = "") -> str:
    """Recursively create .dirindex files in a directory tree.

    Args:
        path: Absolute or relative path to the directory.
        parent: Relative path prefix for the dirindex 'path:' field.

    Returns:
        SHA1 hash of the generated .dirindex file.
    """
    dirindex_path = os.path.join(path, DIRINDEX_FILENAME)

    entries = sorted(os.listdir(path))

    with open(dirindex_path, "w") as f:
        f.write(f"version:{DIRINDEX_VERSION}\n")
        f.write(f"path:{parent}\n")

        for entry in entries:
            full_path = os.path.join(path, entry)

            if entry == DIRINDEX_FILENAME:
                continue

            if os.path.isfile(full_path):
                file_hash = sha1_of_file(full_path)
                file_size = os.stat(full_path).st_size
                if entry.endswith(".tgz") or entry.endswith(".txz"):
                    f.write(f"t:{entry}:{file_hash}:{file_size}\n")
                else:
                    f.write(f"f:{entry}:{file_hash}:{file_size}\n")

            elif os.path.isdir(full_path) and entry != ".svn":
                child_parent = os.path.join(parent, entry) if parent else entry
                child_hash = create_dirindex(full_path, child_parent)
                f.write(f"d:{entry}:{child_hash}\n")

    return sha1_of_file(dirindex_path)


def create_root_dirindex(fg_scenery: str, fg_scenery_export: str):
    """Create the root .dirindex and Airports archive.

    This combines data from the remote scenery (Airports, Terrain) with
    exported data (Objects, Models) into a unified root .dirindex.

    Args:
        fg_scenery: Path to the remote/mounted scenery (has Airports, Terrain).
        fg_scenery_export: Path to the export directory (has Objects, Models).
    """
    logger.info("Creating directory indexes...")

    # Create Airports dirindex and archive
    airports_path = os.path.join(fg_scenery, "Airports")
    if os.path.isdir(airports_path):
        logger.info("Creating Airports .dirindex...")
        create_dirindex(airports_path, "Airports")

        # Create Airports archive
        archive_path = os.path.join(fg_scenery, "Airports_archive.tgz")
        logger.info("Creating Airports_archive.tgz...")
        with tarfile.open(archive_path, "w:gz") as tar:
            tar.add(airports_path, arcname="Airports")

    # Create Objects and Models dirindexes in the export directory
    objects_path = os.path.join(fg_scenery_export, "Objects")
    if os.path.isdir(objects_path):
        logger.info("Creating Objects .dirindex...")
        create_dirindex(objects_path, "Objects")

    models_path = os.path.join(fg_scenery_export, "Models")
    if os.path.isdir(models_path):
        logger.info("Creating Models .dirindex...")
        create_dirindex(models_path, "Models")

    # Build the root .dirindex
    logger.info("Creating root .dirindex...")
    root_dirindex_path = os.path.join(fg_scenery_export, DIRINDEX_FILENAME)
    with open(root_dirindex_path, "w") as f:
        f.write(f"version:{DIRINDEX_VERSION}\n")
        f.write("path:\n")
        f.write(f"time:{datetime.now(timezone.utc).strftime('%Y%m%d-%H:%MZ')}\n")

        # Airports (from remote scenery)
        airports_dirindex = os.path.join(airports_path, DIRINDEX_FILENAME)
        if os.path.isfile(airports_dirindex):
            f.write(f"d:Airports:{sha1_of_file(airports_dirindex)}\n")

        # Models (from export)
        models_dirindex = os.path.join(models_path, DIRINDEX_FILENAME)
        if os.path.isfile(models_dirindex):
            f.write(f"d:Models:{sha1_of_file(models_dirindex)}\n")

        # Objects (from export)
        objects_dirindex = os.path.join(objects_path, DIRINDEX_FILENAME)
        if os.path.isfile(objects_dirindex):
            f.write(f"d:Objects:{sha1_of_file(objects_dirindex)}\n")

        # Terrain (from remote scenery)
        terrain_dirindex = os.path.join(fg_scenery, "Terrain", DIRINDEX_FILENAME)
        if os.path.isfile(terrain_dirindex):
            f.write(f"d:Terrain:{sha1_of_file(terrain_dirindex)}\n")

        # Airports archive tarball
        archive_path = os.path.join(fg_scenery, "Airports_archive.tgz")
        if os.path.isfile(archive_path):
            archive_hash = sha1_of_file(archive_path)
            archive_size = os.stat(archive_path).st_size
            f.write(f"t:Airports_archive.tgz:{archive_hash}:{archive_size}\n")

    logger.info("Root .dirindex created at %s", root_dirindex_path)
