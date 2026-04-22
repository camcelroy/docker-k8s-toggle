#!/usr/bin/env bash
# Read-only state inspection via Docker Desktop's backend API. Sourced.

# shellcheck source=common.sh
. "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Live user-intent: is K8s supposed to be on?
# Reads /app/settings, which reflects the Docker Desktop app's in-memory
# setting (not settings-store.json on disk — that file lags reality).
# Echoes "true" | "false" | "unknown".
k8s_intent() {
  # /app/settings/flat returns a flat key=value map — simpler and more stable
  # than the grouped /app/settings response, which has no top-level kubernetes key.
  # Can't use `// "unknown"` — jq's // treats false as absent, which collapses
  # our "disabled" case into "unknown". Check for null explicitly.
  backend_curl GET /app/settings/flat 2>/dev/null \
    | jq -r 'if .kubernetesEnabled == null then "unknown" else (.kubernetesEnabled | tostring) end' 2>/dev/null \
    || echo "unknown"
}

# Cluster runtime state. Observed values include "running" and "disabled";
# transitional values (e.g. "starting") are inferred by combining with intent.
k8s_runtime_status() {
  backend_curl GET /kubernetes 2>/dev/null \
    | jq -r '.status // "unknown"' 2>/dev/null \
    || echo "unknown"
}

# Echoes one of: enabled | disabled | starting | stopping | docker-not-running | unknown
#
# Status is the primary signal — it takes distinct values (disabled, starting,
# running, stopping) and flips atomically when Docker Desktop begins a transition.
# Intent (kubernetesEnabled) only matters as a tiebreaker for the narrow window
# between user click and backend-begins-transitioning, during which status hasn't
# moved yet. Intent is also unreliable: in the disabled steady state the field
# is often *absent* from /app/settings/flat rather than set to false.
k8s_state() {
  if ! backend_up; then
    echo "docker-not-running"
    return
  fi
  local status intent
  status=$(k8s_runtime_status)
  intent=$(k8s_intent)

  case "$status" in
    running)
      if [[ "$intent" == "false" ]]; then echo "stopping"; else echo "enabled"; fi
      ;;
    disabled)
      if [[ "$intent" == "true" ]]; then echo "starting"; else echo "disabled"; fi
      ;;
    starting) echo "starting" ;;
    stopping) echo "stopping" ;;
    *)        echo "unknown" ;;
  esac
}
