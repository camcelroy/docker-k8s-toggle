# docker-k8s-toggle

macOS SwiftBar menu bar plugin that shows whether Docker Desktop's built-in
Kubernetes is on or off, and lets you toggle it in one click — without
restarting Docker.

**Requires:** macOS, Docker Desktop, [SwiftBar](https://github.com/swiftbar/SwiftBar),
`jq`.

## Why

Docker Desktop's built-in Kubernetes (kubeadm or kind backend) keeps containers
running continuously, which prevents Resource Saver mode from engaging. Turning
K8s off when not in use is the fix. The official way is Settings → Kubernetes →
uncheck → Apply & Restart, which is several clicks. This makes it one.

## What you get

- Menu bar icon that reflects current state at a glance:
  - Filled hex grid (blue): Kubernetes enabled
  - Outline hex grid (gray): Kubernetes disabled
  - Triangle (orange): Docker Desktop not running
- One-click toggle that flips the setting and restarts Docker
- One-click "Restart Docker" and "Open Docker Desktop" for the Kubernetes pane

## Install

Prereqs (all via Homebrew):

| | what | why |
|---|---|---|
| `brew install --cask swiftbar` | the menu bar host | runs the plugin |
| `brew install jq` | JSON editor | reads + flips the Kubernetes key in `settings-store.json` |
| Docker Desktop | | the thing we're toggling — install from docker.com if you don't have it |

Launch SwiftBar once and pick a plugin folder when it prompts (e.g.
`~/.config/swiftbar`). This step is required — `install.sh` will refuse to run
until SwiftBar knows where its plugin folder lives. Then:

```sh
git clone https://github.com/camcelroy/docker-k8s-toggle.git
cd docker-k8s-toggle
./install.sh            # or: make install
```

This symlinks `plugin/docker-k8s.30s.sh` into SwiftBar's plugin folder, so edits
to the repo take effect without reinstalling.

Uninstall:

```sh
./uninstall.sh          # or: make uninstall
```

## How it works

Docker Desktop exposes an HTTP API over a Unix socket at:

```
~/Library/Containers/com.docker.docker/Data/backend.sock
```

The plugin talks to that socket for everything:

- **Read intent**: `GET /app/settings/flat` → `.kubernetesEnabled`
- **Read cluster state**: `GET /kubernetes` → `.status` (e.g. `running`, `disabled`)
- **Start K8s**: `POST /kubernetes/start` (no body, no restart, ~30–60s to fully come up)
- **Stop K8s**: `POST /kubernetes/stop` (no body, no restart, near-instant)

Menu bar state is derived by cross-referencing intent against cluster status:

| intent | status | → shown as |
|---|---|---|
| true | running | enabled |
| true | anything else | starting… |
| false | running | stopping… |
| false | anything else | disabled |

This gives you true transitional states during spin-up/spin-down, and no
Docker restart is required — Docker Desktop handles the cluster lifecycle on
its own.

### Why not read `settings-store.json`?

An earlier version of this tool did. Turns out that file is a stale cache, not
the live source of truth — Docker Desktop keeps settings in memory and only
sometimes writes them to disk. On this machine it read `KubernetesEnabled:
false` while the backend correctly reported K8s was running. The backend API
is the authoritative source.

## Known gotchas

**The backend API is undocumented.** Docker Desktop could rename endpoints,
change response shapes, or move the socket at any release. The endpoint list
is enumerable via `curl --unix-socket <sock> http://localhost/` — start there
if things break. Schema-drift example already observed in this repo:
`/app/settings` returns a grouped object without a top-level `kubernetes` key,
but `/app/settings/flat` exposes it as `kubernetesEnabled`. The flat variant
has been more stable and is what this plugin uses.

**Process name drift.** `lib/common.sh` matches both `Docker Desktop` (4.x+
GUI process) and the bare `Docker` (older releases) when waiting for a quit in
`restart_docker`. This doesn't affect toggle, only the "Restart Docker" menu
item.

**First launch: SwiftBar hasn't been told where its plugin folder lives.**
`install.sh` will refuse to run until you've launched SwiftBar once and picked
a folder. Open SwiftBar, let it prompt, then re-run.

**SwiftBar refresh cadence.** The plugin filename is `docker-k8s.30s.sh`, so
SwiftBar re-runs it every 30 seconds. After you click Toggle or Restart, the
wrappers fire `swiftbar://refreshplugin?name=docker-k8s` so the menu bar
updates immediately instead of waiting for the next tick.

**"Open Kubernetes settings" uses an undocumented URL scheme**
(`docker-desktop://dashboard/open?path=settings/kubernetes`). Docker Desktop
registers the `docker-desktop://` scheme and the path query-string lands on a
specific pane. Because it's undocumented, future Docker Desktop updates may
change or remove it — if the menu item stops working, fall back to plain
`open -a Docker` and click through Settings → Kubernetes manually.

## Debug tips

Run `./bin/doctor.sh` (or `make doctor`). It reports: prereq status, Docker
backend socket availability, live K8s intent + runtime status, resolved menu
bar state, and the SwiftBar plugin folder + symlink status.

To see the plugin output directly without SwiftBar in the loop:

```sh
./plugin/docker-k8s.2s.sh
```

## Development

Extra prereq for linting:

```sh
brew install shellcheck
```

```sh
make lint       # shellcheck everything
make doctor     # same as bin/doctor.sh
```

CI runs the same `make lint` on PRs and pushes to `master`.

## License

MIT — see [LICENSE](LICENSE).
