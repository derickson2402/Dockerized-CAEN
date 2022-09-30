# Dockerized-CAEN

[![Publish Latest](https://github.com/derickson2402/Dockerized-CAEN/actions/workflows/publish.yml/badge.svg)](https://github.com/derickson2402/Dockerized-CAEN/actions/workflows/publish.yml) [![Build test image](https://github.com/derickson2402/Dockerized-CAEN/actions/workflows/testing.yml/badge.svg)](https://github.com/derickson2402/Dockerized-CAEN/actions/workflows/publish-dev.yml)

Tired of using ssh and Duo mobile when testing your code with CAEN?
Love using VS Code on your own laptop?
Use this project and you'll never have an issue again!

# Installation

Before using, you will need Docker Desktop installed (
[macOS](https://docs.docker.com/desktop/mac/install/),
[Windows](https://docs.docker.com/desktop/windows/install/),
[Linux](https://docs.docker.com/engine/install/)
).
Now copy the file ```devcontainer.json``` into your repository as ```.devcontainer/devcontainer.json```.
You can do this automatically by running the following:

```bash
/bin/bash -c 'mkdir .devcontainer && wget https://raw.githubusercontent.com/derickson2402/Dockerized-CAEN/main/devcontainer.json -O .devcontainer/devcontainer.json'
```

Great!
Now when you open your project in VS Code, it will ask if you want to open the project in the container.
This will reopen the window and say ```Dev Container: CAEN``` in the bottom left corner.
Everything you do is now running in a CAEN environment!
If you don't see the prompt, you can also open the command palette and run ```Remote-Containers: Reopen in Container```.
Happy coding!

## How Does This Work?

Great question!
It uses a [Docker Container](https://www.docker.com/resources/what-container/), which is like a virtual environment running Linux.
This environment is set up with CentOS (the free version of RHEL on CAEN) and all of the tools that you normally use on CAEN.
That means that there is no difference running a program in the container versus on actual CAEN servers.
It also means that the Autograder compiler works the same as in the container!

## Need A Program That's Not Installed?

There's a simple solution to that!
The ```devcontainer.json``` file contains instructions for installing more tools.
You can also log an issue [here](https://github.com/derickson2402/Dockerized-CAEN/issues/new) with the name of said program and any special tools that might go along with it.
I will add it as a default as soon as I can!

# ```caen``` script for macOS users

Programming on macOS and just want to use CAEN tools on the command line?
You can use the ```caen``` script to use the devcontainer from a terminal (however you cannot use custom tools this way).
You can run commands like this and it will execute in CAEN:

```bash
caen [program] [args]
```

To use this script, you need to have Docker installed (see above).
With Docker installed, simply run the following command to download the script:

```bash
sudo /bin/bash -c 'wget \
https://raw.githubusercontent.com/derickson2402/Dockerized-CAEN/main/caen \
-O /usr/local/bin/caen && chmod +x /usr/local/bin/caen'
```

## Script Tips

You can run ```caen bash``` to start a new bash shell in the container!
This can be handy if you have a lot of commands to run, or if you are having issues with redirecting stdin, stdout, or stderr, or you are trying to use piping.

There are a few environment variables that you can use to change the behavior of the container.
To permanently set an option, add it to a file in your home directory ```~/.caen.conf```.
To set an option just for the current workspace, you can set them in the file ```$(pwd)/.caen.conf```.
You can also use ```export VARIABLE=value``` to make the settings stick around just until you close your shell, or you can use ```VARIABLE=value caen ...``` to just use it once.
The currently supported variables are given below:

Variable Name | Default Value | Description
--------------|---------------|------------
CAEN_VERSION  | latest        | Container tag to use, either of the form ```v0.5```, or a branch name like ```dev``` or ```feature-example```
CAEN_ARGS     | --            | Optional arguments to pass to the ```docker run``` command. Be careful with these, they will likely collide with existing options
CAEN_USER     | your-uid:your-gid | Defaults to your current ```UID:GID```. You can specify just ```UID``` or both, just need to use the number
CAEN_REPO_NAME | ghcr.io/derickson2402/dockerized-caen | Can be changed for locally testing new containers

# Contributing

I started working on this project while taking EECS-281, in order to make debugging my programs easier.
I am sharing this project online in hopes that others will find it useful, but note that I don't have much free time to develop this project.

With that said, if you have an idea that would make this project even better, feel free to log an issue or submit a Pull Request.
I greatly appreciate any help on developing this project!
