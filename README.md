# Box On Wheels: OCI containers for gnarly software

This repository is a collection of OCI ("Docker", if you prefer) containers
meant to run various (generally proprietary) software that can't be run on
Musl-based distributions such as Alpine or (some configurations of) Void. I use
these with [Distrobox](https://github.com/89luca89/distrobox) as somewhat of an
alternative to Flatpak without all the runtime bloat and (unnecessary/undesired
for my usecases) security features. Indeed, tight integration with my home
directory is a feature, not a bug.

Arch is used as a Glibc-having OS due to its general popularity: issues on Arch
tend to get fixed quickly as a function of sheer userbase. Relatedly, most
proprietary software runs well on Arch with little fuss, and the OS is
relatively easy to script in this context.

In general, if your distribution packages something out of this repo, use that
package instead, but if you're on Musl, they almost certainly do not.

## How to use

For now, these images aren't published anywhere, so you'll need to build them
before telling Distrobox (or whatever) to use them. I only test these with:

- Buildah as a builder
- Distrobox as an orchestrator
- Podman as a container manager
- crun as a container runtime

Any other configurations are untested and unsupported, but patches are welcome.
I presume these should run fairly well with Docker replacing steps 1, 3, and 4,
too.

### Building the base image

```sh
buildah bud -t oci.klar.sh/bow-base:latest -f Containerfile.base
```

### Building app images

For whichever app(s) you're interested in:

```sh
# Valid options are (or just `ls Containerfile.*` in this directory):
# discord, steam, zoom
APP_NAME=steam

buildah bud -t "oci.klar.sh/bow-${APP_NAME}:latest" -f "Containerfile.${APP_NAME}"
distrobox create \
    -n "${APP_NAME}" \
    --image oci.klar.sh/bow-${APP_NAME}:latest \
    --additional-flags "--runtime /usr/bin/crun --group-add keep-groups" \
    --home "${HOME}/.distrobox/${APP_NAME}"
```

> The `--additional-flags` bit is not optional when using rootless containers
> (eg. Podman)! Without it (and `crun`), you won't have access to your webcam
> in the containers, which may be a problem for Discord and Zoom depending on
> your usecase. I'm not certain, but I believe Docker (which runs a root-ish
> daemon) should be unaffected, and so the `--additional-flags` could be left
> off.

### Running Stuff

While Distrobox has the `export` command, I prefer to remix their scripts such
that typing the command name launches the app, rather than sends me into a
shell in the respective container. Here's my example files for how I handle
Discord:

```sh
#!/bin/sh
# ~/.local/bin/discord
#
# distrobox_binary
# name: discord
if [ -z "${CONTAINER_ID}" ]; then
	exec /usr/bin/distrobox-enter -n discord -- 		 /usr/local/bin/discord  "$@"
else
	exec /usr/local/bin/discord "$@"
fi
```

> N.B. in the above example, the `/usr/local/bin/discord` part is important, as
> there's a wrapper script in the BOW container which runs `betterdiscordctl`
> to ensure BetterDiscod is always installed. `/usr/bin/discord` is the raw
> Discord installation with no wrapper script, which isn't what I want.

```ini
# ~/.local/share/applications/discord
[Desktop Entry]
Name=Discord
Categories=Distrobox;System;Utility
Exec=/home/j/bin/discord
Icon=/home/j/.local/share/icons/distrobox/arch.png
Keywords=distrobox;
TryExec=/usr/bin/distrobox
Type=Application
```

## Contributing

Patches are welcome, but I hold myself to no obligation to merge them. Submit
them by email at [the SourceHut
repo](https://git.sr.ht/~klardotsh/box-on-wheels) or by pull request [at the
GitHub repo](https://github.com/klardotsh/box-on-wheels). Formally, the
SourceHut mirror is canonical; the repo is hosted on GitHub only for
discoverability.

## Legal Bullshit

See [COPYING](/COPYING) for the [Zero-Clause BSD
License](https://www.tldrlegal.com/license/bsd-0-clause-license), which is
maximally-permissive and as close as I can get to a public domain dedication
without pissing the EU and Fedora and a bunch of other entities off.

