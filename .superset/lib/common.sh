# Shared helpers for .superset/{setup,teardown,run}.sh. Source, don't execute.

WORKSPACE_PATH="${SUPERSET_WORKSPACE_PATH:-$PWD}"
ROOT_PATH="${SUPERSET_ROOT_PATH:-}"
# Worktree dir name is unique per workspace and is stable across setup/teardown.
WORKSPACE_KEY="$(basename "$WORKSPACE_PATH" | tr -c 'A-Za-z0-9_-' '-' | sed 's/-*$//')"
PROJECT_KEY="umami-v3"

PORTS_ENV="$WORKSPACE_PATH/.superset/ports.env"
ALLOC_DIR="${SUPERSET_HOME_DIR:-$HOME/.superset}/port-allocations/$PROJECT_KEY"
ALLOC_FILE="$ALLOC_DIR/$WORKSPACE_KEY"
LOCK_DIR="$ALLOC_DIR.lock"

# Each workspace gets a block of PORT_BLOCK ports starting at PORT_BASE_START.
PORT_BASE_START=20000
PORT_BLOCK=10
PORT_MAX_BLOCKS=200

# Lowercase, alnum + '-', for docker compose project names.
COMPOSE_PROJECT_NAME="$(printf '%s-%s' "$PROJECT_KEY" "$WORKSPACE_KEY" | tr 'A-Z' 'a-z' | tr -c 'a-z0-9-' '-' | sed 's/-*$//')"
export COMPOSE_PROJECT_NAME

log() { printf '[superset] %s\n' "$*"; }

port_in_use() { lsof -nP -iTCP:"$1" -sTCP:LISTEN >/dev/null 2>&1; }

with_lock() {
  mkdir -p "$(dirname "$LOCK_DIR")"
  local tries=0
  until mkdir "$LOCK_DIR" 2>/dev/null; do
    tries=$((tries + 1))
    # Break a stale lock after ~10s.
    if [ "$tries" -gt 100 ]; then rmdir "$LOCK_DIR" 2>/dev/null || true; fi
    sleep 0.1
  done
  "$@"; local rc=$?
  rmdir "$LOCK_DIR" 2>/dev/null || true
  return $rc
}

compose_file() {
  local f
  for f in compose.yaml compose.yml docker-compose.yaml docker-compose.yml; do
    [ -f "$WORKSPACE_PATH/$f" ] && { echo "$WORKSPACE_PATH/$f"; return 0; }
  done
  return 1
}

load_ports() {
  [ -f "$PORTS_ENV" ] || return 1
  set -a; . "$PORTS_ENV"; set +a
}
