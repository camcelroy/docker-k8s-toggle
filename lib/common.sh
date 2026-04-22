#!/usr/bin/env bash
# Shared helpers. Sourced, never executed directly.
# Intentionally does not set shell options — leave that to the caller.

# SwiftBar and Launch Services don't inherit a login shell, so PATH is explicit.
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"

# Docker Desktop's backend HTTP API. Undocumented but stable across 4.x.
# If the socket path drifts, bin/doctor.sh will surface it.
BACKEND_SOCK="$HOME/Library/Containers/com.docker.docker/Data/backend.sock"

# Cheap liveness check — don't just stat the socket; it can linger briefly
# after Docker Desktop exits. /ping verifies the backend is actually serving.
backend_up() {
  curl -sS --unix-socket "$BACKEND_SOCK" --max-time 2 \
    http://localhost/ping >/dev/null 2>&1
}

# Wrapper for backend calls. Emits response body on stdout; errors go to stderr.
# Usage: backend_curl GET /kubernetes
#        backend_curl POST /kubernetes/start
backend_curl() {
  local method=$1 path=$2
  curl -sS --unix-socket "$BACKEND_SOCK" --max-time 5 \
    -X "$method" -H "Content-Length: 0" \
    "http://localhost$path"
}

# Kept for restart_docker's "wait for Docker to fully exit" loop, where the
# socket disappears before the process does.
docker_running() {
  pgrep -qx "Docker Desktop" || pgrep -qx Docker
}
