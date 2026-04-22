#!/usr/bin/env bash
set -euo pipefail

PLUGIN_DIR=$(defaults read com.ameba.SwiftBar PluginDirectory 2>/dev/null || true)
if [[ -z "$PLUGIN_DIR" ]]; then
  echo "SwiftBar plugin folder not configured — nothing to uninstall."
  exit 0
fi

removed=false
for name in docker-k8s.2s.sh docker-k8s.strm.sh docker-k8s.30s.sh; do
  LINK="$PLUGIN_DIR/$name"
  if [[ -L "$LINK" ]]; then
    rm "$LINK"
    echo "✓ Removed: $LINK"
    removed=true
  fi
done
$removed || echo "Not installed in $PLUGIN_DIR"
