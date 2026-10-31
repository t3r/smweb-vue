# fgsmdb — FlightGear Scenemodels Database Tools

Command-line tools for the FlightGear scenemodels database.

## Installation

```bash
pip install fgsmdb
```

Or install from source:

```bash
cd fgsmdb
pip install .
```

For development:

```bash
cd fgsmdb
pip install -e .
```

## Configuration

Copy `.env.example` to `.env` and fill in your values:

```bash
cp .env.example .env
```

| Variable | Description | Default |
|----------|-------------|---------|
| `PGURI` | PostgreSQL connection URI (required) | — |
| `FGELEV_PATH` | Path to the fgelev binary (local mode) | `/usr/local/bin/fgelev` |
| `FGELEV_DOCKER_IMAGE` | Docker image to run fgelev in (Docker mode) | — |
| `FGELEV_TCP_HOST` | Hostname of a remote fgelev TCP service (TCP mode) | — |
| `FGELEV_TCP_PORT` | Port of the remote fgelev TCP service | `9000` |
| `FG_ROOT` | FlightGear data root — not needed in TCP mode | `/app/data` |
| `FG_SCENERY` | Local scenery path (Terrain, Airports, etc.) — not needed in TCP mode | `./fgscenery` |
| `FG_SCENERY_EXPORT` | Working directory for exported files | `./export` |
| `GROUNDNETS_PATH` | Path to groundnets git repository | `./groundnets` |
| `MIN_UPDATES` | Minimum pending updates to trigger export | `1` |
| `SYNC_TARGETS` | Comma-separated rsync target URIs | — |
| `CDN_INVALIDATE_CMD` | Shell command to run after distribution | — |

For remote distribution, rsync uses your `~/.ssh/config` for host aliases,
usernames, and identity files.

### fgelev modes

The `gndelev` step needs to reach a running fgelev binary. Three modes are
supported; the first one configured wins:

**TCP service (recommended for server deployments)**

Run the fgelev Docker image as a persistent service, for example in a
Docker Compose stack:

```yaml
services:
  fgelev:
    build:
      context: ./export/fgelev
    restart: unless-stopped
    ports:
      - "127.0.0.1:9000:9000"
    volumes:
      - ${FG_ROOT}:/fg/root:ro
      - ${FG_SCENERY}:/fg/scenery:ro
    environment:
      FG_ROOT: /fg/root
      FG_SCENERY: /fg/scenery
```

Then point fgsmdb at the service — no local terrain data needed:

```ini
FGELEV_TCP_HOST=fgelev    # service name in Compose, or any hostname/IP
FGELEV_TCP_PORT=9000      # default, can be omitted
```

The service speaks the same line-oriented protocol as the local binary
(`id lon lat\n` in, `id:elevation\n` out) via socat on port 9000.
fgelev's terrain-tile cache persists for the lifetime of the connection,
which covers the entire export run.

**Docker run (one-shot container per export run)**

```ini
FGELEV_DOCKER_IMAGE=fgelev:latest
FG_ROOT=/path/to/fg/data
FG_SCENERY=/path/to/scenery
```

fgsmdb will call `docker run --rm --interactive` with fg_root and
fg_scenery bind-mounted read-only into the container.

**Local binary**

```ini
FGELEV_PATH=/usr/local/bin/fgelev
FG_ROOT=/path/to/fg/data
FG_SCENERY=/path/to/scenery
```

## Usage

```bash
# Run the export pipeline
python3 -m fgsmdb export

# Or use the installed command
fgsmdb export
```

### Export Command

Exports the scenemodels database to a TerraSync-compatible file tree.

```bash
# Full pipeline (all steps except distribute)
python3 -m fgsmdb export

# With a specific .env file
python3 -m fgsmdb export --env-file /path/to/.env

# Run specific steps only
python3 -m fgsmdb export --steps sanitize,export,mkdiridx

# Include distribution to mirrors
python3 -m fgsmdb export --steps sanitize,gndelev,export,mkdiridx,upload,distribute

# Skip the pending-updates threshold check
python3 -m fgsmdb export --skip-check

# Override the minimum updates threshold
python3 -m fgsmdb export --min-updates 10

# Enable verbose (debug) logging
python3 -m fgsmdb export -v
```

### Pipeline Steps

| Step | Description |
|------|-------------|
| `sanitize` | Fix data integrity: update tile numbers, nullify zero elevation offsets |
| `gndelev` | Compute ground elevation for new objects using fgelev (local binary, Docker, or TCP service) |
| `export` | Export shared/per-hemisphere models and generate .stg files from the database |
| `mkdiridx` | Create `.dirindex` files for TerraSync and the Airports archive |
| `upload` | Sync exported files to the local scenery tree (hash-based, copies only changes) |
| `distribute` | Rsync scenery to remote mirror servers (parallel) |

By default, all steps except `distribute` are run. Distribution must be explicitly
requested via `--steps`.

Before any steps execute, the pipeline calls `fn_update_statistics()` and checks
whether the number of objects pending ground elevation meets the configured threshold.
Use `--skip-check` to bypass this gate.

### Command Line Options

```
python3 -m fgsmdb export [-h] [--env-file ENV_FILE] [--steps STEPS] [--all]
                         [--skip-check] [--min-updates N] [-v]

Options:
  --env-file ENV_FILE   Path to .env file (default: auto-detect)
  --steps STEPS         Comma-separated steps: sanitize, gndelev, export,
                        mkdiridx, upload, distribute
  --all                 Run all steps (same as default, without distribute)
  --skip-check          Skip the pending-updates threshold check
  --min-updates N       Override the MIN_UPDATES threshold from .env
  -v, --verbose         Enable debug logging
  -h, --help            Show help message
```

## Output Structure

```
fgscenery/
├── .dirindex
├── Airports_archive.tgz
├── SharedModels.txz
├── Airports/
│   ├── .dirindex
│   └── ...
├── Models/
│   ├── .dirindex
│   └── <group_path>/
├── Objects/
│   ├── .dirindex
│   └── <e|w>NNN<n|s>NN/
│       └── <e|w>NNN<n|s>NN/
│           ├── <tile>.stg
│           └── <model_files>
└── Terrain/
    └── .dirindex
```

## License

GNU General Public License v2.0 — see [LICENCE](../LICENCE).
