"""CLI entry point for fgsmdb.

Usage:
    python3 -m fgsmdb export [options]
    python3 -m fgsmdb --version
"""

import argparse
import sys

from . import __version__
from .commands import export


def main():
    parser = argparse.ArgumentParser(
        prog="fgsmdb",
        description="FlightGear Scenemodels Database Tools",
    )
    parser.add_argument(
        "--version", "-V",
        action="version",
        version=f"fgsmdb {__version__}",
    )
    subparsers = parser.add_subparsers(dest="command", help="Available commands")

    # Register the export subcommand
    export.register(subparsers)

    args = parser.parse_args()

    print(f"fgsmdb {__version__}")

    if args.command is None:
        parser.print_help()
        sys.exit(1)

    # Dispatch to the command handler
    args.func(args)


if __name__ == "__main__":
    main()
