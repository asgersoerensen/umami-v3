#!/usr/bin/env bash
# Paradev workspace setup: copy untracked files from the root repo, reserve
# per-workspace ports, install dependencies, start backing services.
set -euo pipefail
cd "${SUPERSET_WORKSPACE_PATH:-$(git rev-parse --show-toplevel)}"
. .superset/lib/common.sh
. .superset/lib/ports.sh

# 1. Copy untracked files from the root checkout --------------------------------
# - every untracked, non-ignored file (e.g. local docs/specs not yet committed)
# - ignored env files (.env, .env.local, apps/*/.env, ...)
# Existing files in the workspace are never overwritten.
copy_from_root() {
  if [ -z "$ROOT_PATH" ] || [ "$ROOT_PATH" = "$WORKSPACE_PATH" ] || [ ! -d "$ROOT_PATH" ]; then
    log "No separate root repo (SUPERSET_ROOT_PATH unset or same as workspace); skipping copy."
    return 0
  fi
  local list rel n=0
  list="$(
    {
      git -C "$ROOT_PATH" ls-files --others --exclude-standard
      git -C "$ROOT_PATH" ls-files --others --ignored --exclude-standard -- \
        '.env' '.env.*' '*/.env' '*/.env.*' '.superset/config.local.json'
    } | grep -vE '(^|/)(node_modules|\.venv|venv|__pycache__|\.next|dist|build|\.dolt|\.beads)/' \
      | grep -vE '(\.lock$|\.db$|^\.beads)' | sort -u
  )"
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    [ -f "$ROOT_PATH/$rel" ] || continue
    [ -e "$WORKSPACE_PATH/$rel" ] && continue
    mkdir -p "$(dirname "$WORKSPACE_PATH/$rel")"
    cp -p "$ROOT_PATH/$rel" "$WORKSPACE_PATH/$rel"
    log "copied $rel"
    n=$((n + 1))
  done <<< "$list"
  log "Copied $n untracked file(s) from $ROOT_PATH"
}
copy_from_root

# If there's still no .env but an example exists, seed it.
if [ ! -f .env ] && [ -f .env.example ]; then
  cp .env.example .env
  log "created .env from .env.example"
fi

# 2. Reserve ports and point .env at them ---------------------------------------
reserve_ports
log "Ports: APP_PORT=$APP_PORT DB_PORT=$DB_PORT WEB_PORT=$WEB_PORT"

set_env_var() { # key value file — replace in place (first wins for some loaders) or append
  local key=$1 val=$2 file=$3
  if grep -qE "^${key}=" "$file"; then
    sed -i '' -E "s|^${key}=.*|${key}=${val}|" "$file" 2>/dev/null || sed -i -E "s|^${key}=.*|${key}=${val}|" "$file"
  else
    printf '%s=%s\n' "$key" "$val" >> "$file"
  fi
}
if [ -f .env ]; then
  set_env_var PORT "$APP_PORT" .env
  set_env_var DB_PORT "$DB_PORT" .env
  # Repoint a local Postgres URL (localhost/127.0.0.1, any port) at this workspace's DB port.
  if grep -qE '^DATABASE_URL=.*@(localhost|127\.0\.0\.1)(:[0-9]+)?/' .env; then
    sed -i '' -E "s#^(DATABASE_URL=.*@(localhost|127\.0\.0\.1))(:[0-9]+)?/#\1:${DB_PORT}/#" .env 2>/dev/null \
      || sed -i -E "s#^(DATABASE_URL=.*@(localhost|127\.0\.0\.1))(:[0-9]+)?/#\1:${DB_PORT}/#" .env
  fi
fi

# 3. Install dependencies --------------------------------------------------------
if [ -f pyproject.toml ]; then
  log "uv sync"
  uv sync
elif [ -f requirements.txt ]; then
  log "pip install -r requirements.txt (into .venv)"
  [ -d .venv ] || uv venv
  uv pip install -r requirements.txt
fi

install_node() { # dir
  local d=$1
  [ -f "$d/package.json" ] || return 0
  log "installing node deps in $d"
  if   [ -f "$d/pnpm-lock.yaml" ]; then (cd "$d" && pnpm install --frozen-lockfile)
  elif [ -f "$d/bun.lock" ] || [ -f "$d/bun.lockb" ]; then (cd "$d" && bun install --frozen-lockfile)
  elif [ -f "$d/yarn.lock" ]; then (cd "$d" && yarn install --frozen-lockfile)
  elif [ -f "$d/package-lock.json" ]; then (cd "$d" && npm ci)
  else (cd "$d" && npm install)
  fi
}
install_node .
for d in web frontend apps/web; do install_node "$d"; done

# 4. Backing services (Postgres via docker compose), on this workspace's DB_PORT --
if cf="$(compose_file)"; then
  if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    log "docker compose up ($COMPOSE_PROJECT_NAME, DB_PORT=$DB_PORT)"
    DB_PORT="$DB_PORT" docker compose -f "$cf" -p "$COMPOSE_PROJECT_NAME" up -d --wait
    if [ -f manage.py ]; then
      log "running migrations"
      set -a; . "$PORTS_ENV"; set +a
      uv run python manage.py migrate --noinput
    fi
  else
    log "WARNING: $cf found but Docker isn't running; skipped starting services."
  fi
fi

log "Setup complete."
