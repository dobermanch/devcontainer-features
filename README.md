# devcontainer-features

A small set of [dev container features](https://containers.dev/implementors/features/)
for things most of my repos would otherwise copy into their own `devcontainer.json`.

| Feature | What it does |
|---|---|
| `idle-shutdown` | Stops the container once nobody has been connected for 30 minutes (option `minutes`) |
| `host-ssh` | Mounts the host's `~/.ssh` read-only as the container user's `~/.ssh` |
| `host-claude` | Mounts the host's `~/.claude` as the container user's `~/.claude` |
| `vscode-base` | Extensions and settings every repo wants, Claude Code included |

They are separate because a repo does not always want all of them: one that
keeps its own keys in a `~/.ssh` volume, for example, must not get the host's.
Mounts cannot be switched off by an option, so each mount is its own feature.

## Using them in a repo

Below, `<registry>/<namespace>` stands for wherever the features are published
(see [Publishing](#publishing)), e.g. `ghcr.io/<owner>/devcontainer-features`.

```jsonc
{
  "name": "my-repo",
  "image": "mcr.microsoft.com/devcontainers/base:jammy",
  "runArgs": ["--name", "my-repo"],
  "remoteUser": "vscode",
  "shutdownAction": "stopContainer",
  "features": {
    "<registry>/<namespace>/vscode-base:1": {},
    "<registry>/<namespace>/host-ssh:1": {},
    "<registry>/<namespace>/host-claude:1": {},
    "<registry>/<namespace>/idle-shutdown:1": {}
  },
  "customizations": {
    "vscode": {
      // Added to vscode-base's list; settings here win over its settings
      "extensions": ["golang.go"]
    }
  }
}
```

`:1` follows every 1.x release. Pin `:1.0.0` for a repo that must not change
under you.

If the registry is private, run `docker login <registry>` once on the machine
that runs Docker (the remote host, for VS Code over Remote-SSH), with a token
that can read packages.

### What stays in each repo

Features cannot set these, so every repo keeps them:

- `runArgs` (`--name`, resource limits), `remoteUser`, `shutdownAction`
- the image or Dockerfile, and which Docker it gets: docker-in-docker,
  docker-outside-of-docker or none differ per repo, so no feature here picks one
- repo-specific mounts, `containerEnv`, lifecycle scripts and extensions

## The features

### idle-shutdown

A dev container left running costs the Docker host memory for nothing, and
VS Code does not reliably stop it: `shutdownAction` is skipped on a crash, a
sleeping laptop or a dropped link, and over Remote-SSH it was seen not to fire
at all. This watchdog runs inside the container and stops it itself.

It starts from the feature's entrypoint on every container start, whoever
starts the container (VS Code, Portainer, `docker start`), and checks once a
minute for a session:

- a VS Code window: an established connection to the VS Code server's port
- an interactive `docker exec -it` shell
- an SSH login, for containers running sshd

With none for the configured minutes it stops PID 1, which stops the container.
Stopped is not removed: volumes and the container's own files are kept, and
reopening the folder starts it again. Expect the stop up to two minutes after
the timeout, since it checks once a minute.

| Setting | |
|---|---|
| `"minutes": "10"` | Feature option: idle minutes before stopping, `0` disables. Default 30 |
| `IDLE_SHUTDOWN_MINUTES` | In `containerEnv`: overrides the option. `remoteEnv` is not seen at container start |
| `touch /tmp/stay-awake` | Keeps the container up while you are away, for a long job. `rm` it after |

Its log is `/var/log/idle-shutdown.log`, one line each time the session count
changes (`vscode=1 terminals=0 ssh=0`). Not in `/tmp`: docker-in-docker mounts
a fresh tmpfs there after the watchdog starts.

### host-ssh, host-claude

The mount source is `${localEnv:USERPROFILE}${localEnv:HOME}`: Windows sets the
first, Linux the second, so exactly one resolves. A shell that sets both on
Windows (git-bash launching VS Code) concatenates them into a path that does
not exist and the mount fails.

A mount target can't name the container user: mounts are resolved before the
container exists, so `${containerEnv:HOME}` reaches Docker unexpanded and an
option is never substituted into a feature's mounts. So each mounts at a fixed
path (`/mnt/host-ssh`, `/mnt/host-claude`), and `install.sh` links it into
`$_REMOTE_USER_HOME`, the one place the user is known. Any `remoteUser` works;
the link dangles during the image build and resolves once the container starts.

`host-claude` also mounts the directory at the host's own path
(`${localEnv:HOME}/.claude`). Claude Code writes absolute host paths into its
config (`"installLocation": "/home/<you>/.claude/plugins/local"` for a plugin
marketplace added from a local directory), and container Claude reads them
through `~/.claude` and opens them as written. On Windows `HOME` is unset and
the target is a harmless `/.claude`.

The mounts are written in the string form on purpose. The object form
(`{"type": "bind", ..., "readonly": true}`) is accepted, but the CLI drops
`readonly`, and `~/.ssh` would come through writable.

### vscode-base

Extensions and settings only; nothing is installed in the image. VS Code merges
a repo's own `customizations` on top: its extensions are added to these, and
its settings win where both set the same one.

## Developing

Everything runs the devcontainer CLI from a container (`scripts/devcontainer`),
so the only requirement is Docker.

```bash
make test                     # every feature, with scenarios
make test-idle-shutdown       # one feature
```

Without `make`, the same thing:

```bash
scripts/devcontainer features test --project-folder . \
  --base-image mcr.microsoft.com/devcontainers/base:jammy [-f idle-shutdown]
```

Tests live in `test/<feature>/`: `test.sh` runs against the feature with
default options, and each entry in `scenarios.json` runs the script of the same
name. They build real containers on the host's Docker.

To change a feature, edit it under `src/`, bump `version` in its
`devcontainer-feature.json` (patch for fixes, minor for additions, major for
anything a repo would have to change for), run `make test`, then publish.

## Publishing

```bash
docker login <registry>       # token that can write packages
make publish REGISTRY=<registry> NAMESPACE=<namespace>
# or: scripts/devcontainer features publish --registry <registry> \
#       --namespace <namespace> ./src
```

For GitHub Container Registry that is `REGISTRY=ghcr.io` and
`NAMESPACE=<owner>/devcontainer-features`. `REGISTRY` and `NAMESPACE` default to
the values in the `Makefile`.

Publishes every feature in `src/` whose version is not in the registry yet,
tagged `1`, `1.0`, `1.0.0` and `latest`. The image names are nested
(`<namespace>/<feature>`); a registry that does not accept nested names needs a
single-segment `NAMESPACE`.
