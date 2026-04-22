#!/usr/bin/env bash
# Symlink the SwiftBar plugin into SwiftBar's plugin folder.
set -euo pipefail

DRY_RUN=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    -h|--help)
      echo "Usage: $0 [--dry-run]"
      echo "  Symlinks plugin/docker-k8s.2s.sh into SwiftBar's plugin folder."
      exit 0
      ;;
    *)
      echo "Unknown arg: $arg" >&2
      exit 2
      ;;
  esac
done

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PLUGIN_SRC="$REPO/plugin/docker-k8s.2s.sh"

run() {
  if $DRY_RUN; then
    printf "DRY-RUN: %s\n" "$*"
  else
    "$@"
  fi
}

if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq is required. Install with: brew install jq" >&2
  exit 1
fi

if [[ ! -d "/Applications/SwiftBar.app" && ! -d "$HOME/Applications/SwiftBar.app" ]]; then
  echo "ERROR: SwiftBar not found. Install with: brew install --cask swiftbar" >&2
  exit 1
fi

PLUGIN_DIR=$(defaults read com.ameba.SwiftBar PluginDirectory 2>/dev/null || true)
if [[ -z "$PLUGIN_DIR" ]]; then
  echo "ERROR: SwiftBar plugin folder not configured." >&2
  echo "Launch SwiftBar once, pick a plugin folder when prompted, then re-run." >&2
  exit 1
fi
if [[ ! -d "$PLUGIN_DIR" ]]; then
  echo "ERROR: SwiftBar plugin folder does not exist: $PLUGIN_DIR" >&2
  exit 1
fi

LINK="$PLUGIN_DIR/docker-k8s.2s.sh"

# Remove stale symlinks from previous iterations of this plugin's filename.
for legacy in "$PLUGIN_DIR/docker-k8s.30s.sh" "$PLUGIN_DIR/docker-k8s.strm.sh"; do
  if [[ -L "$legacy" ]]; then
    run rm "$legacy"
    echo "Removed legacy symlink: $legacy"
  fi
done

if [[ -e "$LINK" && ! -L "$LINK" ]]; then
  echo "ERROR: $LINK exists and is not a symlink. Move it aside and re-run." >&2
  exit 1
fi

if [[ -L "$LINK" && "$(readlink "$LINK")" != "$PLUGIN_SRC" ]]; then
  run rm "$LINK"
fi

if [[ ! -L "$LINK" ]]; then
  run ln -s "$PLUGIN_SRC" "$LINK"
fi

echo "✓ Installed: $LINK -> $PLUGIN_SRC"
echo
echo "If SwiftBar is running, it should pick up the plugin within 2s."
echo "To force a reload: SwiftBar menu -> Preferences -> Refresh All."
