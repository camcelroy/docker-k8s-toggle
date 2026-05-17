#!/usr/bin/env bash
# Install the SwiftBar plugin.
#
# Default: copies plugin/, lib/, bin/ into ~/.local/share/docker-k8s-toggle,
#          then symlinks the plugin into SwiftBar's plugin folder. The repo
#          clone is not referenced at runtime and can be deleted afterward.
# --dev:   symlinks SwiftBar at this repo instead, so edits take effect live.
#          Deleting or moving the repo will break the menubar — use for
#          development, not for everyday installs.
set -euo pipefail

DRY_RUN=false
DEV=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --dev) DEV=true ;;
    -h|--help)
      cat <<EOF
Usage: $0 [--dev] [--dry-run]
  Default: copies files into ~/.local/share/docker-k8s-toggle; repo clone
           can be deleted after install.
  --dev:   symlinks SwiftBar directly at this repo for live edits.
EOF
      exit 0
      ;;
    *)
      echo "Unknown arg: $arg" >&2
      exit 2
      ;;
  esac
done

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
INSTALL_DIR="$HOME/.local/share/docker-k8s-toggle"

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

if $DEV; then
  ROOT="$REPO"
else
  # Wipe and repopulate so an old install can't leak stale lib/bin files.
  run rm -rf "$INSTALL_DIR"
  run mkdir -p "$INSTALL_DIR"
  run cp -R "$REPO/plugin" "$INSTALL_DIR/"
  run cp -R "$REPO/lib"    "$INSTALL_DIR/"
  run cp -R "$REPO/bin"    "$INSTALL_DIR/"
  ROOT="$INSTALL_DIR"
fi

PLUGIN_SRC="$ROOT/plugin/docker-k8s.2s.sh"
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
if $DEV; then
  echo "  dev mode: live edits in $REPO take effect on the next 2s refresh."
else
  echo "  copy in $INSTALL_DIR — the repo clone is no longer needed."
fi
echo
echo "If SwiftBar is running, it should pick up the plugin within 2s."
echo "To force a reload: SwiftBar menu -> Refresh all."
