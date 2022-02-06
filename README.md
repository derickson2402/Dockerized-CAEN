# Dockerized-CAEN

[![Publish Latest](https://github.com/derickson2402/Dockerized-CAEN/actions/workflows/publish.yml/badge.svg)](https://github.com/derickson2402/Dockerized-CAEN/actions/workflows/publish.yml) [![Build test image](https://github.com/derickson2402/Dockerized-CAEN/actions/workflows/testing.yml/badge.svg)](https://github.com/derickson2402/Dockerized-CAEN/actions/workflows/testing.yml)

Tired of using ssh and Duo mobile when testing your code with CAEN? With this script, all you have to do is run:

```bash
./caen <program> [args]
```

This will run your command in an environment identical to CAEN Linux. For example, if you are working on a c++ project for EECS 281, you could use:

```bash
./caen make clean
./caen make my_program.cpp
./caen valgrind my_program.cpp
./caen perf my_program.cpp
```

## Installation

To use this script, you need to have Docker installed on your [macOS](https://docs.docker.com/desktop/mac/install/), [Windows](https://docs.docker.com/desktop/windows/install/), or [Linux](https://docs.docker.com/engine/install/) computer. With Docker installed, simply copy and paste the following command into a shell:

```bash
wget https://raw.githubusercontent.com/derickson2402/Dockerized-CAEN/main/caen -O /usr/local/bin/caen && chmod +x /usr/local/bin/caen
```

## How Does This Work?

This script runs your command inside of a Docker Container, which is like a virtual environment running Linux. This environment is set up with CentOS (a fork of the RHEL on CAEN) and all of the tools that you normally use on CAEN. That means that there should be no difference running a program in the container versus on actual CAEN servers, and that the Autograder compiler should work the same as in the container!

## Help! I Need A Program That's Not Installed!

Oops! Sorry about that! Please log an issue [here](https://github.com/derickson2402/Dockerized-CAEN/issues/new) with the name of said program and any special tools that might go along with it. I will add it as soon as I can! For a temporary workaround, see the section below on [hackery](#hackery).

## Useful Tips

If you want to use a different version of the container other than the default, you can specify the ```CAEN_VERSION``` environment variable before running the script like such:

```bash
CAEN_VERSION=dev caen my-program
```

This also works for optional arguements to the Docker engine, but this is not recommended as it could conflict with the other options used:

```bash
CAEN_ARGS="-e UID=1001" caen my-program
```

Executables generated with this container are compiled for CAEN servers and won't work on your host system. You should run your ```make clean``` script before switching back and forth, and then run ```make``` from the environment you want to use.

You can also integrate CAEN with your ```Makefile``` so that when you call ```make [job]``` it automatically runs in the container. Do this by replacing the ```CXX``` variable with the following:

```Makefile
CXX = ./caen g++
```

If you do not want to download the ```caen``` script, you can also just preface your commands with the following, but this is not recommended:

```bash
docker run --rm -it -v "$(pwd):/code" ghcr.io/derickson2402/dockerized-caen:latest <valgrind|perf> <program> [args]
```

## Hackery

You can specify the name of the container to use just like you can specify the tag:

```bash
CAEN_REPO_NAME=my-container-name caen my-program
```

If the container environment is not suiting your needs, you can always run the container manually and hack it into working. The problem is that the update won't survive a container restart, so change the normal script like so:

```bash
docker run -it --name caen-tainer -v "$(pwd):/code" ghcr.io/derickson2402/dockerized-caen:latest bash
```

The important part is to get rid of the ```--rm``` tag so the container isn't destroyed when it exits, and to give it a name to easily reference it with (you don't have to use ```caen-tainer```, but I thought it was funny :smile:). You should be able to jump back into the container with either of:

```bash
docker start -ai caen-tainer
docker exec -it caen-tainer <command>
```

## Contributing

I started working on this project while taking EECS-281, in order to make debugging my programs easier. I am sharing this project online in hopes that others will find it useful, but note that I don't have much free time to develop this project.

With that said, if you have an idea that would make this project even better, feel free to log an issue or submit a Pull Request. I greatly appreciate any help on developing this project!
