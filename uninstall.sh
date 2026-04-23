#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="$HOME/.local/share/docker-k8s-toggle"

PLUGIN_DIR=$(defaults read com.ameba.SwiftBar PluginDirectory 2>/dev/null || true)
if [[ -n "$PLUGIN_DIR" ]]; then
  removed=false
  for name in docker-k8s.2s.sh docker-k8s.strm.sh docker-k8s.30s.sh; do
    LINK="$PLUGIN_DIR/$name"
    if [[ -L "$LINK" ]]; then
      rm "$LINK"
      echo "✓ Removed: $LINK"
      removed=true
    fi
  done
  $removed || echo "No plugin symlink found in $PLUGIN_DIR"
else
  echo "SwiftBar plugin folder not configured — skipping symlink cleanup."
fi

if [[ -d "$INSTALL_DIR" ]]; then
  rm -rf "$INSTALL_DIR"
  echo "✓ Removed: $INSTALL_DIR"
fi
