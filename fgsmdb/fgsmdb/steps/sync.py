"""Sync step — synchronize exported scenery to the local scenery tree.

Equivalent to the legacy upload.sh + LocalSync.py scripts.
Uses .dirindex-based diffing to copy only changed files.
"""

import hashlib
import logging
import os
import shutil

logger = logging.getLogger(__name__)

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


class DirIndex:
    """Parser for .dirindex files."""

    def __init__(self, path: str):
        self.directories: list[dict] = []
        self.files: list[dict] = []
        self.version = 0
        self.path = ""

        with open(path) as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue

                tokens = line.split(":")
                if tokens[0] == "version":
                    self.version = int(tokens[1])
                elif tokens[0] == "path":
                    self.path = tokens[1] if len(tokens) > 1 else ""
                elif tokens[0] == "d":
                    self.directories.append({"name": tokens[1], "hash": tokens[2]})
                elif tokens[0] in ("f", "t"):
                    self.files.append({
                        "name": tokens[1],
                        "hash": tokens[2],
                        "size": tokens[3] if len(tokens) > 3 else "0",
                    })

    def get_file_by_name(self, name: str) -> dict | None:
        """Find a file entry by name."""
        for f in self.files:
            if f["name"] == name:
                return f
        return None


def sync_path(src: str, dst: str, expected_hash: str | None = None) -> str | None:
    """Sync a directory from src to dst using .dirindex-based diffing.

    Only copies files whose hashes differ between source and destination.
    Removes files present in destination but not in source.

    Args:
        src: Source directory path.
        dst: Destination directory path.
        expected_hash: Expected hash of the source .dirindex (for validation).

    Returns:
        SHA1 hash of the source .dirindex file.
    """
    src_dirindex_path = os.path.join(src, DIRINDEX_FILENAME)
    if not os.path.isfile(src_dirindex_path):
        logger.debug("No .dirindex at %s, skipping.", src)
        return None

    src_index = DirIndex(src_dirindex_path)

    # Recurse into subdirectories first
    for sub_dir in src_index.directories:
        sync_path(
            os.path.join(src, sub_dir["name"]),
            os.path.join(dst, sub_dir["name"]),
            sub_dir["hash"],
        )

    # Compute hash if not provided
    if expected_hash is None:
        expected_hash = sha1_of_file(src_dirindex_path)

    dst_dirindex_path = os.path.join(dst, DIRINDEX_FILENAME)

    if not os.path.isfile(dst_dirindex_path):
        # No destination .dirindex — copy everything
        os.makedirs(dst, exist_ok=True)
        for file_entry in src_index.files:
            _copy_file(file_entry["name"], src, dst)
            logger.debug("copy (new) %s : %s -> %s", file_entry["name"], src, dst)
        _copy_file(DIRINDEX_FILENAME, src, dst)
    else:
        # Have destination .dirindex — do incremental sync
        dst_index = DirIndex(dst_dirindex_path)

        for src_file in src_index.files:
            dst_file = dst_index.get_file_by_name(src_file["name"])
            if dst_file is None or dst_file["hash"] != src_file["hash"]:
                os.makedirs(dst, exist_ok=True)
                _copy_file(src_file["name"], src, dst)
                logger.debug("copy (changed) %s : %s -> %s", src_file["name"], src, dst)

        # Update .dirindex if hashes differ
        if expected_hash != sha1_of_file(dst_dirindex_path):
            _copy_file(DIRINDEX_FILENAME, src, dst)

        # Remove files that no longer exist in source
        for dst_file in dst_index.files:
            if src_index.get_file_by_name(dst_file["name"]) is None:
                dst_file_path = os.path.join(dst, dst_file["name"])
                if os.path.exists(dst_file_path):
                    os.remove(dst_file_path)
                    logger.debug("delete %s", dst_file_path)

    return expected_hash


def _copy_file(name: str, src_dir: str, dst_dir: str):
    """Copy a single file from src_dir to dst_dir."""
    src_path = os.path.join(src_dir, name)
    dst_path = os.path.join(dst_dir, name)
    shutil.copy2(src_path, dst_path)


def run(fg_scenery_export: str, fg_scenery: str):
    """Sync the export directory into the scenery directory.

    Args:
        fg_scenery_export: Source export directory.
        fg_scenery: Destination scenery directory.
    """
    logger.info("Syncing export to scenery: %s -> %s", fg_scenery_export, fg_scenery)
    sync_path(fg_scenery_export, fg_scenery)
    logger.info("Sync complete.")
