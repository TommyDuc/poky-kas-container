Poky Kas Container
========================

This project is a repository that generates a Docker image using the poky-container and kas tools. The generated Docker image can be used for building and testing various software projects.

Background
---------------------

Poky is a reference distribution of the Yocto Project, an open-source project for building custom Linux-based operating systems. Poky provides a set of tools and recipes for building Linux distributions targeting various hardware architectures and use cases.

Poky-container is a tool for running Poky inside a Docker container, which allows developers to easily set up a consistent and isolated development environment.

KAS is a tool for automating the setup and configuration of Yocto Project builds. It provides a declarative configuration file format and a set of plugins for configuring the build environment.


Build container
---------------------

```bash
./build_image.sh ubuntu-18.04 2.6.2
```

Deploy container
---------------------

```bash
./deploy_image.sh ubuntu-18.04 2.6.2
```

Run container
---------------------
Here a very simple but usable scenario for using the container is described.
It is by no means the *only* way to run the container, but is a great starting
point.

* **Create a workdir or volume**
  * **Linux**

    The workdir you create will be used for the output created while using the container.
    For example a user could create a directory using the command
  
    ```bash
    mkdir -p /home/myuser/mystuff
    ```

    *It is important that you are the owner of the directory.* The owner of the
    directory is what determines the user id used inside the container. If you
    are not the owner of the directory, you may not have access to the files the
    container creates.

    For the rest of the Linux instructions we'll assume the workdir chosen was
    `/home/myuser/mystuff`.
    
  * **Windows/Mac**

    On Windows or Mac a workdir isn't needed. Instead the volume called *myvolume* will be used. This volume should have been created when following the instructions at https://github.com/crops/docker-win-mac-docs/wiki.


* **The docker command**
  * **Linux**

    Assuming you used the *workdir* from above, the command
    to run a container for the first time would be:

    ```bash
    docker run --rm -it -v /home/myuser/mystuff:/workdir dimonoff/crops/poky/kas:ubuntu-18.04-kas-2.6.2 --workdir=/workdir kas shell meta-custom/kas/kas-project.yml
    ```
    or, if you have SELinux in enforcing mode:
    ```bash
    docker run --rm -it -v /home/myuser/mystuff:/workdir:Z dimonoff/crops/poky/kas:ubuntu-18.04-kas-2.6.2 --workdir=/workdir kas shell meta-custom/kas/kas-project.yml
    ```
    
  * **Windows/Mac**
  
    ```bash
    docker run --rm -it -v myvolume:/workdir dimonoff/crops/poky/kas:ubuntu-18.04-kas-2.6.2 --workdir=/workdir kas shell meta-custom/kas/kas-projet.yml
    ```

  Let's discuss the options:
  * **_--workdir=/workdir_**: This causes the container to start in the directory
    specified. This can be any directory in the container. The container will also use the uid and gid
    of the workdir as the uid and gid of the user in the container.

  This should put you at a prompt similar to:
  ```bash
  pokyuser@3bbac563cacd:/workdir$
  ```

  At this point you should be able to follow the same instructions as described
  - https://kas.readthedocs.io/en/latest/userguide.html#usage
