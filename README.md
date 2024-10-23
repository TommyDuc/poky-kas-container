# Poky Kas Container

This project is a repository that generates a Docker image using the
poky-container and kas tools. The generated Docker image can be used for
building and testing various software projects.

## Background

Poky is a reference distribution of the Yocto Project, an open-source project
for building custom Linux-based operating systems. Poky provides a set of tools
and recipes for building Linux distributions targeting various hardware
architectures and use cases.

Poky-container is a tool for running Poky inside a Docker container, which
allows developers to easily set up a consistent and isolated development
environment.

KAS is a tool for automating the setup and configuration of Yocto Project
builds. It provides a declarative configuration file format and a set of plugins
for configuring the build environment.

## Preliminary steps

### Entering the reproducible environment

```bash
$ nix develop
# ..
```

Any further commands are assumed to be run within this reproducible environment.

The above requires that [`nix` is installed][nix-install] and that the [flakes
feature is enabled][nix-flake-enabled].

Alternatively, you can have a look at [`flake.nix`][nix-flake] and manually
install the listed dependencies (not recommanded).

[nix-install]: https://nixos.org/download
[nix-flake-enabled]: https://nixos.wiki/wiki/Flakes#Enable_flakes_permanently_in_NixOS
[nix-flake]: ./flake.nix

### Configure the build

Make sure the [`.env` file](./.env) exists:

```bash
$ just init
# ..
```

Then, make sure that the version of each target component is as expected in the
`.env` file:

```bash
$ cat ./.env
DISTRO_CROPS_POKY="ubuntu-XX.YY"
KAS_VERSION="X.Y"
IMAGE_SUFFIX="-rev1"
```

A couple of things to know:

 -  `DISTRO_CROPS_POKY`: This corresponds to a distribution supported by
    upstream [crops/poky-container][repo-poky-container] and effectively refers
    to the [*tag* of the *base container image*][crops-poky-tags] we build upon.

 -  `KAS_VERSION`: This corresponds to the [*version* of the pypi kas
    package][kas-package-versions] that will be installed in our image via `pip3
    install`.

 -  `IMAGE_SUFFIX`: Can be used as a mean to differentiate between image
    releases when the based distro and kas remain unchanged but the image's
    configuration actually is (e.g.: adding a extra package, changing a
    configuration file, etc.).

Note that at any time, you can *reset* your `.env` file from the versioned
[`.env.example` template][dotenv-template] as follow:

```bash
$ just reset
# ..
```

[dotenv-template]: ./.env.example

### Login to the target container image repository

```bash
$ just login
# ..
```

## Build the container image

```bash
$ just image
# ..
```

This will be using [`podman`][podman].

In case you prefer to use `docker`, you can set the `cli_exe` var as follow:

```bash
$ just cli_exe=docker image
# ..
```

Same principle applies for other tasks.

[podman]: https://podman.io/

## Publish the container image

```bash
$ just image-publish
# ..
```

## Run the container

Basically should be as simple as:

```bash
$ just run
# ..
```

### Advanced

Here a very simple but usable scenario for using the container. It is by no
means the *only* way to run the container, but is a great starting point.

#### Create a workdir or volume

##### Linux

The workdir you create will be used for the output created while using the
container. For example a user could create a directory using the command

```bash
$ mkdir -p /home/myuser/mystuff
# ..
```

*It is important that you are the owner of the directory.* The owner of the
directory is what determines the user id used inside the container. If you are
not the owner of the directory, you may not have access to the files the
container creates.

For the rest of the Linux instructions we'll assume the workdir chosen was
`/home/myuser/mystuff`.

##### Windows/Mac

On Windows or Mac a workdir isn't needed. Instead the volume called *myvolume*
will be used. This volume should have been created when following the
instructions at https://github.com/crops/docker-win-mac-docs/wiki.


#### The `docker` command

##### Linux

Assuming you used the *workdir* from above, the command
to run a container for the first time would be:

```bash
$ docker run --rm -it \
  -v /home/myuser/mystuff:/workdir \
  --workdir=/workdir \
  dimonoff/poky-kas-container:MY_IMAGE_TAG_HERE \
  kas shell meta-custom/kas/kas-project.yml
```

or, if you have SELinux in enforcing mode:

```bash
$ docker run --rm -it \
  -v /home/myuser/mystuff:/workdir:Z \
  --workdir=/workdir \
  dimonoff/poky-kas-container:MY_IMAGE_TAG_HERE \
  kas shell meta-custom/kas/kas-project.yml
# ..
```

##### Windows/Mac
  
```bash
$ docker run --rm -it \
  -v myvolume:/workdir \
  --workdir=/workdir \
  dimonoff/poky-kas-container:MY_IMAGE_TAG_HERE \
  kas shell meta-custom/kas/kas-projet.yml
# ..
```

#### The docker command's options

 -  `--workdir=/workdir`: This causes the container to start in the directory
    specified. This can be any directory in the container. The container will
    also use the uid and gid of the workdir as the uid and gid of the user in
    the container.

    This should put you at a prompt similar to:

    ```bash
    pokyuser@3bbac563cacd:/workdir$
    ```

#### The `podman` command

A backward compatible substitute for `docker`. You usually only have to change
`docker` for `podman`.

We're currently using `podman` in our `justfile` as it don't require any daemon
installation on your system and as such can be simply brough about by
`flake.nix`.

More details [here][podman].

##### Known issues

###### Error: open /etc/containers/policy.json: no such file or directory

In case your on nixos, it is as simple as enabling the
`virtualisation.containers.enable` option in your `configuration.nix`:

```nix
{...}:
{
    virtualisation.containers.enable = true
}
```

For other systems refer to [podman instructions][podman-install-cfg-file]. The
gist of it is to create a [default `/etc/containers/policy.json` policy
file][podman-def-policy]

[podman-install-cfg-file]: https://podman.io/docs/installation#configuration-files
[podman-def-policy]: https://podman.io/docs/installation#policyjson

###### The uid:gid for "/workdir" is "0:0". The uid and gid must be non-zero

If you observe something like this:

```bash
$ just run
# ..
The uid:gid for "/workdir" is "0:0". The uid and gid must be non-zero.
Please check to make sure the "volume" or "bind" specified using either
"-v" or "--mount" to docker, exists and has a non-zero uid:gid.
error: Recipe `run` failed on line 55 with exit code 1
```

You'll have to add the following option to your `podman run` command:

 -  `--userns=keep-id:uid=1000,gid=100`

    This make sure that when we mount some host filesystem in the container, the
    uid and gid of the files will be remapped to the user `pokyuser` (at uid
    `1000`) and group `users` (at gid `100`).

    More details [here][podman-userns].

[podman-userns]: https://docs.podman.io/en/v4.4/markdown/options/userns.container.html


#### Final word

At this point you should be able to follow the same instructions as
described in the [`kas` user guide][kas-useguide].


[kas-useguide]: https://kas.readthedocs.io/en/latest/userguide.html#usage

## License

Licensed under GNU General Public License, Version 2.0 [LICENSE](./LICENSE).

Please note that license was inherited from the [`poky-container`
repository][repo-poky-container] this work is based upon.

[repo-poky-container]: https://github.com/crops/poky-container
