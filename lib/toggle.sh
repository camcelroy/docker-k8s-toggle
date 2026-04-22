#!/usr/bin/env bash
# Mutating actions — flip K8s via the backend API. Sourced.

# shellcheck source=common.sh
. "$(dirname "${BASH_SOURCE[0]}")/common.sh"
# shellcheck source=state.sh
. "$(dirname "${BASH_SOURCE[0]}")/state.sh"

# Toggle Kubernetes live via POST /kubernetes/{start,stop}. No Docker restart,
# no settings-store.json edits — Docker Desktop handles the lifecycle itself.
# Feedback comes from the menu bar icon updating, not from a notification.
toggle_k8s() {
  if ! backend_up; then
    return 1
  fi

  local state
  state=$(k8s_state)
  case "$state" in
    enabled|starting)  backend_post_fire /kubernetes/stop ;;
    disabled|stopping) backend_post_fire /kubernetes/start ;;
    *) return 1 ;;
  esac
}

# Fire-and-forget POST. Docker Desktop's /kubernetes/{start,stop} hold the
# HTTP response open for tens of seconds while the cluster transitions, which
# would block the caller and trip set -e under the usual backend_curl timeout.
# The request is acted on as soon as it lands — we don't need the response.
backend_post_fire() {
  local path=$1
  (curl -sS --unix-socket "$BACKEND_SOCK" --max-time 120 \
    -X POST -H "Content-Length: 0" \
    "http://localhost$path" >/dev/null 2>&1 &) 2>/dev/null
}

# Kept for the "Restart Docker" menu item — quits and relaunches Docker.app.
# Not part of the toggle path anymore.
restart_docker() {
  osascript -e 'quit app "Docker"' >/dev/null 2>&1 || true
  local i
  for ((i = 0; i < 20; i++)); do
    if ! docker_running; then break; fi
    sleep 1
  done
  open -a Docker
}
