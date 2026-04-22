#!/usr/bin/env bash
# Diagnostic report. Run this when the menu bar icon goes weird after a
# Docker Desktop update, or before filing issues against yourself.
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../lib/state.sh
. "$HERE/../lib/state.sh"

ok()   { printf "  \033[32m✓\033[0m %s\n" "$1"; }
warn() { printf "  \033[33m!\033[0m %s\n" "$1"; }
fail() { printf "  \033[31m✗\033[0m %s\n" "$1"; }

echo "docker-k8s-toggle doctor"
echo "========================"
echo

echo "Prerequisites:"
if command -v jq >/dev/null 2>&1; then
  ok "jq: $(jq --version)"
else
  fail "jq not found (brew install jq)"
fi
if command -v curl >/dev/null 2>&1; then
  ok "curl: $(curl --version | head -1 | awk '{print $1, $2}')"
else
  fail "curl not found (should ship with macOS)"
fi
if [[ -d "/Applications/SwiftBar.app" || -d "$HOME/Applications/SwiftBar.app" ]]; then
  ok "SwiftBar installed"
else
  fail "SwiftBar not found (brew install --cask swiftbar)"
fi
if [[ -d "/Applications/Docker.app" ]]; then
  ok "Docker Desktop installed"
else
  fail "Docker Desktop not found"
fi
echo

echo "Docker Desktop backend:"
if [[ -S "$BACKEND_SOCK" ]]; then
  ok "Socket present: $BACKEND_SOCK"
else
  fail "Socket missing: $BACKEND_SOCK"
fi
if backend_up; then
  ok "Backend responding (GET /ping)"
else
  warn "Backend not responding — Docker Desktop may not be running"
fi
echo

if backend_up; then
  echo "Kubernetes — live from backend API:"
  ok "Intent (/app/settings/flat → kubernetesEnabled): $(k8s_intent)"
  ok "Runtime status (/kubernetes → status): $(k8s_runtime_status)"
  progress=$(backend_curl GET /kubernetes 2>/dev/null | jq -r '.content.progressMessage // empty' 2>/dev/null || true)
  if [[ -n "$progress" ]]; then
    ok "Progress message: $progress"
  fi
  echo
  echo "Resolved state: $(k8s_state)"
else
  echo "Kubernetes: (backend unreachable — skipping)"
fi
echo

echo "SwiftBar plugin folder:"
plugin_dir=$(defaults read com.ameba.SwiftBar PluginDirectory 2>/dev/null || true)
if [[ -n "$plugin_dir" ]]; then
  ok "PluginDirectory: $plugin_dir"
  symlink="$plugin_dir/docker-k8s.2s.sh"
  if [[ -L "$symlink" ]]; then
    ok "Symlinked: $symlink -> $(readlink "$symlink")"
  elif [[ -e "$symlink" ]]; then
    warn "Present but not a symlink: $symlink"
  else
    warn "Plugin not installed (run ./install.sh)"
  fi
  for legacy in "$plugin_dir/docker-k8s.30s.sh" "$plugin_dir/docker-k8s.strm.sh"; do
    if [[ -L "$legacy" ]]; then
      warn "Legacy symlink still present: $legacy — run ./install.sh to clean up"
    fi
  done
else
  warn "SwiftBar has no plugin folder configured yet — launch SwiftBar first"
fi
