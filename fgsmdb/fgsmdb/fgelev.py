"""fgelev daemon wrapper.

Manages communication with fgelev so its terrain-tile cache persists
across all queries in a single export run.

Protocol (unchanged from the fgelev binary):
    input:  "<id> <lon> <lat>\\n"   (one object per line)
    output: "<id>:<elevation>\\n"   (one result per line, same order)
    fgelev exits non-zero on EOF — that is expected and ignored.

Three launch modes are supported via class methods:

    # Local binary
    FgElevDaemon.local(fgelev_path, fg_root, fg_scenery)

    # fgelev inside a Docker container (volumes mounted automatically)
    FgElevDaemon.docker(image, fg_root, fg_scenery)

    # fgelev running as a remote TCP service (e.g. Docker Compose stack)
    FgElevDaemon.tcp(host, port)
"""

import logging
import os
import socket
import subprocess

logger = logging.getLogger(__name__)

# Fixed mount points used when running inside Docker.
_CONTAINER_FG_ROOT = "/fg/root"
_CONTAINER_FG_SCENERY = "/fg/scenery"


class FgElevDaemon:
    """Communication wrapper for fgelev, kept alive across all queries.

    Do not construct directly — use the :meth:`local`, :meth:`docker`,
    or :meth:`tcp` class methods.

    Usage::

        with FgElevDaemon.local(path, fg_root, fg_scenery) as fgelev:
            elevation = fgelev.query(ob_id, lon, lat)

        with FgElevDaemon.docker(image, fg_root, fg_scenery) as fgelev:
            elevation = fgelev.query(ob_id, lon, lat)

        with FgElevDaemon.tcp("fgelev-host", 9000) as fgelev:
            elevation = fgelev.query(ob_id, lon, lat)
    """

    def __init__(self, cmd: list[str], env: dict | None = None):
        self._cmd = cmd
        self._env = env  # None means inherit the current environment
        self._proc: subprocess.Popen | None = None
        # TCP mode — set by the tcp() factory method
        self._tcp_host: str | None = None
        self._tcp_port: int | None = None
        self._sock: socket.socket | None = None
        self._sock_in = None
        self._sock_out = None

    # ------------------------------------------------------------------
    # Factory methods
    # ------------------------------------------------------------------

    @classmethod
    def local(cls, fgelev_path: str, fg_root: str, fg_scenery: str) -> "FgElevDaemon":
        """Run fgelev as a local binary.

        Args:
            fgelev_path: Absolute path to the fgelev binary.
            fg_root: FG_ROOT directory (FlightGear data, contains defaults.xml).
            fg_scenery: FG_SCENERY directory (terrain data).
        """
        env = os.environ.copy()
        env["FG_ROOT"] = fg_root
        env["FG_SCENERY"] = fg_scenery
        return cls([fgelev_path], env=env)

    @classmethod
    def docker(
        cls,
        image: str,
        fg_root: str,
        fg_scenery: str,
        fgelev_path: str = "/usr/local/bin/fgelev",
    ) -> "FgElevDaemon":
        """Run fgelev inside a Docker container.

        The host paths fg_root and fg_scenery are bind-mounted read-only
        into the container. The docker CLI must be available on PATH.

        Args:
            image: Docker image name, e.g. "fgelev:latest".
            fg_root: Host path to FG_ROOT (bind-mounted into the container).
            fg_scenery: Host path to FG_SCENERY (bind-mounted into the container).
            fgelev_path: Path to the fgelev binary *inside* the container.
        """
        cmd = [
            "docker", "run", "--rm",
            "--interactive",                              # keep stdin open
            "--volume", f"{fg_root}:{_CONTAINER_FG_ROOT}:ro",
            "--volume", f"{fg_scenery}:{_CONTAINER_FG_SCENERY}:ro",
            "--env", f"FG_ROOT={_CONTAINER_FG_ROOT}",
            "--env", f"FG_SCENERY={_CONTAINER_FG_SCENERY}",
            image,
            fgelev_path,
        ]
        return cls(cmd)

    @classmethod
    def tcp(cls, host: str, port: int) -> "FgElevDaemon":
        """Connect to a remote fgelev service over TCP.

        The service must speak the same line-oriented protocol as the local
        binary (e.g. the fgelev Docker image running with socat on port 9000).
        FG_ROOT and FG_SCENERY are configured on the server side — the client
        does not need local terrain data.

        Args:
            host: Hostname or IP address of the fgelev service.
            port: TCP port the service is listening on (default: 9000).
        """
        instance = cls([])
        instance._tcp_host = host
        instance._tcp_port = port
        return instance

    # ------------------------------------------------------------------
    # Lifecycle
    # ------------------------------------------------------------------

    def start(self):
        """Launch or connect to fgelev."""
        if self._tcp_host is not None:
            self._start_tcp()
        else:
            self._start_proc()

    def _start_proc(self):
        """Launch a local fgelev subprocess."""
        logger.debug("Starting fgelev: %s", self._cmd)
        self._proc = subprocess.Popen(
            self._cmd,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            bufsize=1,  # line-buffered — each flush() sends exactly one line
            env=self._env,
        )
        logger.info("fgelev started (pid %d)", self._proc.pid)

    def _start_tcp(self):
        """Open a TCP connection to the remote fgelev service."""
        logger.debug("Connecting to fgelev service at %s:%d", self._tcp_host, self._tcp_port)
        self._sock = socket.create_connection((self._tcp_host, self._tcp_port), timeout=10)
        self._sock.settimeout(None)  # block indefinitely — fgelev may take time loading terrain tiles
        self._sock_in = self._sock.makefile("r")
        self._sock_out = self._sock.makefile("w")
        logger.info("Connected to fgelev service at %s:%d", self._tcp_host, self._tcp_port)

    def stop(self):
        """Disconnect or shut down fgelev."""
        if self._sock is not None:
            try:
                self._sock.shutdown(socket.SHUT_WR)  # signal EOF to fgelev
                self._sock.close()
            except OSError:
                pass
            finally:
                self._sock = None
                self._sock_in = None
                self._sock_out = None
                logger.debug("fgelev TCP connection closed.")
        if self._proc is not None:
            try:
                self._proc.stdin.close()
                self._proc.wait(timeout=30)
            except subprocess.TimeoutExpired:
                logger.warning("fgelev did not exit cleanly; terminating.")
                self._proc.terminate()
                self._proc.wait(timeout=5)
            finally:
                self._proc = None
                logger.debug("fgelev stopped.")

    def __enter__(self):
        self.start()
        return self

    def __exit__(self, *_):
        self.stop()

    # ------------------------------------------------------------------
    # Querying
    # ------------------------------------------------------------------

    def query(self, ob_id: int, lon: float, lat: float) -> float | None:
        """Send one coordinate to fgelev and return the elevation in metres.

        Returns None if the connection/process has died or the output
        cannot be parsed.
        """
        if self._sock is not None:
            return self._query_tcp(ob_id, lon, lat)
        return self._query_proc(ob_id, lon, lat)

    def _query_proc(self, ob_id: int, lon: float, lat: float) -> float | None:
        if self._proc is None or self._proc.poll() is not None:
            logger.error("fgelev process is not running.")
            return None
        try:
            self._proc.stdin.write(f"{ob_id} {lon} {lat}\n")
            self._proc.stdin.flush()
            line = self._proc.stdout.readline()
        except OSError as exc:
            logger.error("fgelev I/O error: %s", exc)
            return None
        if not line:
            stderr = self._proc.stderr.read(500) if self._proc.stderr else ""
            logger.error("fgelev closed stdout unexpectedly. stderr: %s", stderr)
            return None
        return _parse_line(line.strip())

    def _query_tcp(self, ob_id: int, lon: float, lat: float) -> float | None:
        try:
            self._sock_out.write(f"{ob_id} {lon} {lat}\n")
            self._sock_out.flush()
            line = self._sock_in.readline()
        except OSError as exc:
            logger.error("fgelev TCP I/O error: %s", exc)
            return None
        if not line:
            logger.error("fgelev service closed the connection unexpectedly.")
            return None
        return _parse_line(line.strip())


# ------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------

def _parse_line(line: str) -> float | None:
    """Parse a single "id:elevation" line from fgelev output."""
    if ":" not in line:
        logger.warning("Unexpected fgelev output: %r", line)
        return None
    _, elev_part = line.split(":", 1)
    try:
        return float(elev_part.strip())
    except ValueError:
        logger.warning("Could not parse elevation from fgelev output: %r", line)
        return None
