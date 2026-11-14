#!/usr/bin/env bash
# macOS + Homebrew: one dedicated Ollama embedding service on 0.0.0.0:2222.
# No custom plist, cron job, or persistent watchdog loop.
set -Eeuo pipefail

MODEL="qwen3-embedding:4b"
HOST="0.0.0.0:2222"
LOCAL_URL="http://127.0.0.1:2222"
MODELS_DIR="${HOME}/.ollama/embedding-service-models"

# Match Homebrew's own selection of the user config directory.
if [[ -n "${XDG_CONFIG_HOME:-}" ]]; then
  CONFIG_DIR="$XDG_CONFIG_HOME/homebrew"
elif [[ -n "${HOMEBREW_XDG_CONFIG_HOME:-}" ]]; then
  CONFIG_DIR="$HOMEBREW_XDG_CONFIG_HOME/homebrew"
else
  CONFIG_DIR="$HOME/.homebrew"
fi
ENV_FILE="$CONFIG_DIR/services/ollama.env"

# Make Homebrew discoverable on Apple Silicon and Intel Macs.
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

say() { printf '\n==> %s\n' "$*"; }
warn() { printf 'WARNING: %s\n' "$*" >&2; }
die() {
  printf '\nERROR: %s\n' "$*" >&2
  exit 1
}

require_macos_and_brew() {
  [[ "$(uname -s)" == "Darwin" ]] || die "This script is for macOS only."
  [[ "${EUID}" -ne 0 ]] || die "Run this as your normal macOS user, not sudo."
  command -v brew >/dev/null 2>&1 || die "Install Homebrew first: https://brew.sh"
  command -v curl >/dev/null 2>&1 || die "curl is required."
  command -v lsof >/dev/null 2>&1 || die "lsof is required."
}

# Homebrew service .env overrides were added in Homebrew 6.0.15.
brew_supports_service_env() {
  local version major minor patch
  version="$(brew --version | head -n 1)"
  [[ "$version" =~ ([0-9]+)\.([0-9]+)\.([0-9]+) ]] || return 1
  major="${BASH_REMATCH[1]}"
  minor="${BASH_REMATCH[2]}"
  patch="${BASH_REMATCH[3]}"
  ((10#$major > 6)) ||
    ((10#$major == 6 && 10#$minor > 0)) ||
    ((10#$major == 6 && 10#$minor == 0 && 10#$patch >= 15))
}

ensure_homebrew() {
  if ! brew_supports_service_env; then
    say "Updating Homebrew (service environment files require version 6.0.15+)..."
    brew update || die "Homebrew update failed."
    brew_supports_service_env || die "Homebrew is too old. Please upgrade Homebrew and rerun."
  fi
  if ! brew list --formula ollama >/dev/null 2>&1; then
    say "Installing Ollama via Homebrew..."
    brew install ollama
  fi
}

# Only stop listeners that are recognizably Ollama. Never kill arbitrary PIDs.
stop_ollama_listener_on_port() {
  local port="$1" pid command_name name pids
  pids="$(lsof -nP -tiTCP:"$port" -sTCP:LISTEN 2>/dev/null | sort -u || true)"
  [[ -n "$pids" ]] || return 0

  for pid in $pids; do
    command_name="$(ps -p "$pid" -o comm= 2>/dev/null || true)"
    name="${command_name##*/}"
    case "$name" in
    ollama | Ollama)
      say "Stopping old Ollama PID $pid on port $port..."
      kill "$pid" 2>/dev/null || die "Could not stop PID $pid (permissions?)."
      ;;
    *)
      if [[ "$port" == "2222" ]]; then
        die "Port 2222 is owned by PID $pid ($command_name), not Ollama. Refusing to kill it."
      fi
      warn "Port 11434 belongs to a non-Ollama process (PID $pid); leaving it alone."
      ;;
    esac
  done
}

stop_existing_instances() {
  say "Stopping any previous Homebrew Ollama service..."
  brew services stop ollama >/dev/null 2>&1 || true

  # Stop the separate Ollama desktop application, if it is running.
  if pgrep -x Ollama >/dev/null 2>&1; then
    say "Quitting Ollama.app to avoid competing servers..."
    osascript -e 'tell application "Ollama" to quit' >/dev/null 2>&1 || true
    sleep 2
  fi

  stop_ollama_listener_on_port 11434
  stop_ollama_listener_on_port 2222
  sleep 2

  local still
  still="$(lsof -nP -tiTCP:2222 -sTCP:LISTEN 2>/dev/null || true)"
  [[ -z "$still" ]] || die "Port 2222 is still occupied by PID(s): $still. Check lsof -nP -iTCP:2222 -sTCP:LISTEN"
}

write_service_env() {
  local tmp
  mkdir -p "$CONFIG_DIR/services" "$MODELS_DIR"
  tmp="$(mktemp "${ENV_FILE}.XXXXXX")"

  # Keep any existing unrelated settings, e.g. a previously configured HTTPS_PROXY.
  # Only replace values managed by this script.
  if [[ -f "$ENV_FILE" ]]; then
    cp -p "$ENV_FILE" "${ENV_FILE}.backup" || true
    awk '
      !/^[[:space:]]*(OLLAMA_HOST|OLLAMA_KEEP_ALIVE|OLLAMA_MAX_LOADED_MODELS|OLLAMA_MODELS|OLLAMA_NO_CLOUD|OLLAMA_NUM_PARALLEL)[[:space:]]*=/ {
        print
      }
    ' "$ENV_FILE" >"$tmp"
  fi

  cat >>"$tmp" <<EOF
OLLAMA_HOST=$HOST
OLLAMA_KEEP_ALIVE=-1
OLLAMA_MAX_LOADED_MODELS=1
OLLAMA_NUM_PARALLEL=1
OLLAMA_NO_CLOUD=1
OLLAMA_MODELS=$MODELS_DIR
EOF

  # Optional: HTTPS_PROXY=http://127.0.0.1:2080 ./script install
  # This is for the SERVER'S outbound model downloads, not the listening port.
  if [[ -n "${HTTPS_PROXY:-}" ]]; then
    awk '!/^[[:space:]]*HTTPS_PROXY[[:space:]]*=/' "$tmp" >"${tmp}.new"
    mv "${tmp}.new" "$tmp"
    printf 'HTTPS_PROXY=%s\n' "$HTTPS_PROXY" >>"$tmp"
    if [[ -n "${NO_PROXY:-}" ]]; then
      awk '!/^[[:space:]]*NO_PROXY[[:space:]]*=/' "$tmp" >"${tmp}.new"
      mv "${tmp}.new" "$tmp"
      printf 'NO_PROXY=%s,localhost,127.0.0.1\n' "$NO_PROXY" >>"$tmp"
    else
      if ! grep -q '^NO_PROXY=' "$tmp"; then
        printf 'NO_PROXY=localhost,127.0.0.1\n' >>"$tmp"
      fi
    fi
  fi

  chmod 600 "$tmp"
  mv "$tmp" "$ENV_FILE"
  say "Service configuration: $ENV_FILE"
  grep -E '^(OLLAMA_HOST|OLLAMA_KEEP_ALIVE|OLLAMA_MAX_LOADED_MODELS|OLLAMA_MODELS|OLLAMA_NO_CLOUD)=' "$ENV_FILE"
}

is_ready() {
  curl --noproxy '*' --connect-timeout 2 --max-time 3 -fsS \
    "$LOCAL_URL/api/version" >/dev/null 2>&1
}

wait_for_server() {
  local attempt
  say "Checking Ollama at $LOCAL_URL..."
  for attempt in $(seq 1 30); do
    if is_ready; then
      say "Server is responding on port 2222."
      lsof -nP -iTCP:2222 -sTCP:LISTEN || true
      return 0
    fi
    sleep 1
  done

  warn "Ollama did not start on 2222. Current listeners:"
  lsof -nP -iTCP:11434 -iTCP:2222 -sTCP:LISTEN >&2 || true
  warn "Homebrew services status:"
  brew services list >&2 || true
  warn "Service logs: $(brew --prefix)/var/log/ollama.log"
  warn "Check service env: $ENV_FILE"
  die "Ollama never became available at $LOCAL_URL"
}

start_service() {
  say "Starting Homebrew Ollama service (automatic startup at macOS login)..."
  brew services restart ollama
  wait_for_server
}

pull_model() {
  local attempt
  say "Pulling $MODEL (up to 3 attempts for transient network interruptions)..."
  for attempt in 1 2 3; do
    if OLLAMA_HOST="127.0.0.1:2222" NO_PROXY="localhost,127.0.0.1" \
      ollama pull "$MODEL"; then
      say "Model downloaded."
      return 0
    fi
    warn "Download attempt $attempt failed."
    if [[ "$attempt" != 3 ]]; then sleep 5; fi
  done
  die "Model pull failed. Check network/VPN or set HTTPS_PROXY=http://PROXY_IP:PORT when running this script."
}

warmup_model() {
  say "Loading $MODEL into memory indefinitely..."
  curl --noproxy '*' --max-time 240 -fsS "$LOCAL_URL/api/embed" \
    -H 'Content-Type: application/json' \
    -d '{"model":"qwen3-embedding:4b","input":"warmup","keep_alive":-1}' \
    >/dev/null || die "Embedding warmup failed. Is the model pulled?"

  say "Loaded models:"
  OLLAMA_HOST="127.0.0.1:2222" ollama ps
  if ! OLLAMA_HOST="127.0.0.1:2222" ollama ps | grep -Fq "$MODEL"; then
    die "Warmup returned but model not shown as resident."
  fi
}

show_status() {
  say "Service:"
  brew services list | grep -E '(^Name|ollama)' || true
  say "Service configuration:"
  if [[ -f "$ENV_FILE" ]]; then
    grep -E '^(OLLAMA_HOST|OLLAMA_KEEP_ALIVE|OLLAMA_MAX_LOADED_MODELS|OLLAMA_MODELS|OLLAMA_NO_CLOUD)=' "$ENV_FILE" || true
  else
    warn "Missing: $ENV_FILE"
  fi
  say "Listeners:"
  lsof -nP -iTCP:2222 -iTCP:11434 -sTCP:LISTEN || true
  if is_ready; then
    say "API version:"
    curl --noproxy '*' -fsS "$LOCAL_URL/api/version"
    printf '\n'
    say "Loaded models:"
    OLLAMA_HOST="127.0.0.1:2222" ollama ps || true
    say "Available models:"
    OLLAMA_HOST="127.0.0.1:2222" ollama list || true
  else
    warn "Ollama is not answering on $LOCAL_URL"
  fi
}

uninstall_config() {
  say "Stopping the Homebrew service..."
  brew services stop ollama || true
  if [[ -f "$ENV_FILE" ]]; then
    local tmp
    tmp="$(mktemp "${ENV_FILE}.XXXXXX")"
    awk '
      !/^[[:space:]]*(OLLAMA_HOST|OLLAMA_KEEP_ALIVE|OLLAMA_MAX_LOADED_MODELS|OLLAMA_MODELS|OLLAMA_NO_CLOUD|OLLAMA_NUM_PARALLEL)[[:space:]]*=/ {
        print
      }
    ' "$ENV_FILE" >"$tmp"
    chmod 600 "$tmp"
    mv "$tmp" "$ENV_FILE"
  fi
  say "Removed managed service settings. Models are preserved in $MODELS_DIR."
  say "Homebrew Ollama remains installed."
}

main() {
  require_macos_and_brew
  case "${1:-install}" in
  install)
    ensure_homebrew
    stop_existing_instances
    write_service_env
    start_service
    pull_model
    warmup_model
    show_status
    say "DONE. Remote clients: http://<MAC_LAN_IP>:2222"
    warn "This API has no authentication. Restrict inbound port 2222 to trusted networks."
    warn "After a reboot, Homebrew starts Ollama at login; the model loads on first request. Use '$0 warmup' to preload it immediately."
    ;;
  restart)
    ensure_homebrew
    stop_existing_instances
    write_service_env
    start_service
    warmup_model
    ;;
  pull)
    wait_for_server
    pull_model
    ;;
  warmup)
    wait_for_server
    warmup_model
    ;;
  status)
    show_status
    ;;
  stop)
    brew services stop ollama
    ;;
  uninstall)
    uninstall_config
    ;;
  *)
    printf 'Usage: %s [install|restart|pull|warmup|status|stop|uninstall]\n' "$0" >&2
    exit 2
    ;;
  esac
}

main "$@"
