"""Directory index generation — creates .dirindex and dirindex.txt files for TerraSync.

Equivalent to the legacy CreateDirectoryIndexes.py and mkdiridx.sh scripts.

TerraSync .dirindex format:
    version:1
    path:<relative_path>
    f:<filename>:<sha1>:<size>     (regular files)
    t:<filename>:<sha1>:<size>     (tar archives)
    d:<dirname>:<sha1_of_dirindex> (subdirectories)

Both .dirindex and dirindex.txt are written with identical content.
"""

import hashlib
import logging
import os
import tarfile
from datetime import datetime, timezone

logger = logging.getLogger(__name__)

DIRINDEX_VERSION = 1
DIRINDEX_FILENAME = ".dirindex"
DIRINDEX_TXT_FILENAME = "dirindex.txt"


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


def _write_dirindex(directory: str, content: str):
    """Write .dirindex and dirindex.txt with identical content.

    Returns the SHA1 hash of the written .dirindex file.
    """
    dirindex_path = os.path.join(directory, DIRINDEX_FILENAME)
    txt_path = os.path.join(directory, DIRINDEX_TXT_FILENAME)
    with open(dirindex_path, "w") as f:
        f.write(content)
    with open(txt_path, "w") as f:
        f.write(content)
    return sha1_of_file(dirindex_path)


def create_dirindex(path: str, parent: str = "") -> str:
    """Recursively create .dirindex and dirindex.txt files in a directory tree.

    Args:
        path: Absolute or relative path to the directory.
        parent: Relative path prefix for the dirindex 'path:' field.

    Returns:
        SHA1 hash of the generated .dirindex file.
    """
    lines = [
        f"version:{DIRINDEX_VERSION}",
        f"path:{parent}",
    ]

    for entry in sorted(os.listdir(path)):
        full_path = os.path.join(path, entry)

        if entry in (DIRINDEX_FILENAME, DIRINDEX_TXT_FILENAME):
            continue

        if os.path.isfile(full_path):
            file_hash = sha1_of_file(full_path)
            file_size = os.stat(full_path).st_size
            prefix = "t" if entry.endswith(".tgz") or entry.endswith(".txz") else "f"
            lines.append(f"{prefix}:{entry}:{file_hash}:{file_size}")

        elif os.path.isdir(full_path) and entry != ".svn":
            child_parent = os.path.join(parent, entry) if parent else entry
            child_hash = create_dirindex(full_path, child_parent)
            lines.append(f"d:{entry}:{child_hash}")

    return _write_dirindex(path, "\n".join(lines) + "\n")


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

        # Create Airports archive in the export directory so it gets picked
        # up by the upload step and synced into fg_scenery alongside Objects
        # and Models.
        archive_path = os.path.join(fg_scenery_export, "Airports_archive.tgz")
        logger.info("Creating Airports_archive.tgz...")
        with tarfile.open(archive_path, "w:gz", dereference=True) as tar:
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

    lines = [
        f"version:{DIRINDEX_VERSION}",
        "path:",
        f"time:{datetime.now(timezone.utc).strftime('%Y%m%d-%H:%MZ')}",
    ]

    # Airports (from remote scenery)
    airports_dirindex = os.path.join(airports_path, DIRINDEX_FILENAME)
    if os.path.isfile(airports_dirindex):
        lines.append(f"d:Airports:{sha1_of_file(airports_dirindex)}")

    # Models (from export)
    models_dirindex = os.path.join(models_path, DIRINDEX_FILENAME)
    if os.path.isfile(models_dirindex):
        lines.append(f"d:Models:{sha1_of_file(models_dirindex)}")

    # Objects (from export)
    objects_dirindex = os.path.join(objects_path, DIRINDEX_FILENAME)
    if os.path.isfile(objects_dirindex):
        lines.append(f"d:Objects:{sha1_of_file(objects_dirindex)}")

    # Terrain (from remote scenery)
    terrain_dirindex = os.path.join(fg_scenery, "Terrain", DIRINDEX_FILENAME)
    if os.path.isfile(terrain_dirindex):
        lines.append(f"d:Terrain:{sha1_of_file(terrain_dirindex)}")

    # Airports archive tarball (staged in export dir, synced to fg_scenery by upload step)
    archive_path = os.path.join(fg_scenery_export, "Airports_archive.tgz")
    if os.path.isfile(archive_path):
        archive_hash = sha1_of_file(archive_path)
        archive_size = os.stat(archive_path).st_size
        lines.append(f"t:Airports_archive.tgz:{archive_hash}:{archive_size}")

    _write_dirindex(fg_scenery_export, "\n".join(lines) + "\n")
    logger.info("Root .dirindex created at %s", fg_scenery_export)
