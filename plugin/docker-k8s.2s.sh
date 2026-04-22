#!/usr/bin/env bash
# <bitbar.title>Docker Desktop Kubernetes Toggle</bitbar.title>
# <bitbar.version>v1.0</bitbar.version>
# <bitbar.author>Craig McElroy</bitbar.author>
# <bitbar.author.github>camcelroy</bitbar.author.github>
# <bitbar.desc>Toggle Docker Desktop's Kubernetes setting from the menu bar.</bitbar.desc>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
# <swiftbar.hideDisablePlugin>false</swiftbar.hideDisablePlugin>
set -euo pipefail

# SwiftBar symlinks this file into its plugin folder. Resolve through the
# symlink so the repo's lib/ and bin/ paths work regardless of install location.
SRC="${BASH_SOURCE[0]}"
while [[ -L "$SRC" ]]; do
  DIR=$(cd -P "$(dirname "$SRC")" && pwd)
  SRC=$(readlink "$SRC")
  [[ "$SRC" != /* ]] && SRC="$DIR/$SRC"
done
REPO=$(cd -P "$(dirname "$SRC")/.." && pwd)

# shellcheck source=../lib/state.sh
. "$REPO/lib/state.sh"

state=$(k8s_state)

# action is empty when toggling doesn't make sense (docker down, unknown state).
case "$state" in
  enabled)
    echo "| sfimage=circle.hexagongrid.fill color=#2496ED"
    label="K8s: enabled"; action="Stop K8s"
    ;;
  disabled)
    echo "| sfimage=circle.hexagongrid color=gray"
    label="K8s: disabled"; action="Start K8s"
    ;;
  starting)
    echo "| sfimage=arrow.triangle.2.circlepath color=#FFB000"
    label="K8s: starting…"; action="Stop K8s"
    ;;
  stopping)
    echo "| sfimage=arrow.triangle.2.circlepath color=#FFB000"
    label="K8s: stopping…"; action="Start K8s"
    ;;
  docker-not-running)
    echo "| sfimage=exclamationmark.triangle.fill color=orange"
    label="Docker not running"; action=""
    ;;
  *)
    echo "| sfimage=questionmark.circle color=gray"
    label="K8s: unknown"; action=""
    ;;
esac

echo "---"
echo "$label | font=Menlo"
echo "---"
if [[ -n "$action" ]]; then
  echo "$action | bash=$REPO/bin/toggle terminal=false refresh=true"
else
  echo "Toggle unavailable | color=gray"
fi
echo "Restart Docker | bash=$REPO/bin/restart-docker terminal=false refresh=true"
echo "Open K8s settings | href=docker-desktop://dashboard/open?path=settings/kubernetes"
echo "---"
echo "Run doctor | bash=$REPO/bin/doctor.sh terminal=true"
echo "Refresh | refresh=true"
