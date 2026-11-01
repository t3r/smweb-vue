"""fgsmdb — FlightGear Scenemodels Database Tools."""

from importlib.metadata import version, PackageNotFoundError

try:
    __version__ = version("fgsmdb")
except PackageNotFoundError:
    # Package is not installed (e.g. running directly from source)
    __version__ = "unknown"
