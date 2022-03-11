# Dockerized-CAEN

[![Publish Latest](https://github.com/derickson2402/Dockerized-CAEN/actions/workflows/publish.yml/badge.svg)](https://github.com/derickson2402/Dockerized-CAEN/actions/workflows/publish.yml) [![Build test image](https://github.com/derickson2402/Dockerized-CAEN/actions/workflows/testing.yml/badge.svg)](https://github.com/derickson2402/Dockerized-CAEN/actions/workflows/publish-dev.yml)

Tired of using ssh and Duo mobile when testing your code with CAEN? With this script, all you have to do is run:

```bash
caen <program> [args]
```

This will run your command in an environment identical to CAEN Linux. For example, if you are working on a C++ project for EECS 281, you could use:

```bash
caen make clean
caen make my_program.cpp < input.txt
caen valgrind my_program.cpp
caen perf record my_program.cpp
```

Or maybe you are writing a program in Go, you might want to use:

```bash
caen go build my_program.go
caen ./my_program
```

## Installation

To use this script, you need to have Docker installed on your [macOS](https://docs.docker.com/desktop/mac/install/), [Windows](https://docs.docker.com/desktop/windows/install/), or [Linux](https://docs.docker.com/engine/install/) computer. With Docker installed, simply run the following command in a shell:

```bash
sudo /bin/bash -c 'wget \
https://raw.githubusercontent.com/derickson2402/Dockerized-CAEN/main/caen \
-O /usr/local/bin/caen && chmod +x /usr/local/bin/caen'
```

## How Does This Work?

This script runs your command inside of a Docker Container, which is like a virtual environment running Linux. This environment is set up with CentOS (a fork of the RHEL on CAEN) and all of the tools that you normally use on CAEN. That means that there should be no difference running a program in the container versus on actual CAEN servers, and that the Autograder compiler should work the same as in the container!

## Help! I Need A Program That's Not Installed!

Oops! Sorry about that! Please log an issue [here](https://github.com/derickson2402/Dockerized-CAEN/issues/new) with the name of said program and any special tools that might go along with it. I will add it as soon as I can! For a temporary workaround, see the section below on [hackery](#hackery).

## Useful Tips

Executables generated with this container are compiled for CAEN servers and won't work on your host system. You should run your ```make clean``` script before switching back and forth, and then run ```make``` from the environment you want to use.

There are a few environment variables that you can use to change the behavior of the container. You can either use ```export VARIABLE=value``` to make the settings stick around until you close your shell, or you can use ```VARIABLE=value caen ...``` to just use it once. The currently supported variables are given below:

Variable Name | Default Value | Description
--------------|---------------|------------
CAEN_VERSION  | latest        | Container tag to use, either of the form ```v0.5```, or a branch name like ```dev``` or ```feature-example```
CAEN_ARGS     | --            | Optional arguments to pass to the ```docker run``` command. Be careful with these, they will likely collide with existing options
CAEN_USER     | your-uid:your-gid | Defaults to your current ```UID:GID```. You can specify just ```UID``` or both, just need to use the number

For example, temporarily run a command as a different user:

```bash
CAEN_USER=65535 caen my-program
```

Or use a different version until you close your shell:

```bash
export CAEN_VERSION=dev
caen ls
caen my-program
```

## Contributing

I started working on this project while taking EECS-281, in order to make debugging my programs easier. I am sharing this project online in hopes that others will find it useful, but note that I don't have much free time to develop this project.

With that said, if you have an idea that would make this project even better, feel free to log an issue or submit a Pull Request. I greatly appreciate any help on developing this project!

If you are developing locally, it might be helpful to know that you can specify the name of the container to use just like you can specify the tag:

```bash
CAEN_REPO_NAME=my-container-name caen my-program
```
