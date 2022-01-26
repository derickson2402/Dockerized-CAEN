# Dockerized-CAEN

This is a Docker container running the same debugging software on UofM CAEN servers, which can integrate into your Makefile for automatic testing on your local machine. As of 23 January 2022, the compiler version is 8.50 20210514, so there could be some minor inconsistancies between this container and the actual CAEN servers.

To use this container, you need to have Docker installed on your [macOS](https://docs.docker.com/desktop/mac/install/), [Windows](https://docs.docker.com/desktop/windows/install/), or [Linux](https://docs.docker.com/engine/install/) computer.

With Docker installed and running, simply put the ```caen``` script in your project folder and preface any of your commands with it, like such:

```bash
./caen <program> [args]
```

Note that the executables generated with ```./caen make``` will not be executable by your host machine, so run ```make clean``` before switching environments.

This container is currently under development, but the script does not check for updates automatically. To get the newest container version, run the following in a terminal with Docker running:

```bash
docker pull ghcr.io/derickson2402/dockerized-caen:latest
```

You can also integrate CAEN with your ```Makefile``` so that when you call ```make [job]``` it automatically runs in the container. Do this by replacing the ```CXX``` variable with the following:

```Makefile
CXX = ./caen g++
```

If you do not want to download the ```caen``` script, you can also just preface your commands with the following, but this is not recommended:

```bash
docker run --rm -it --pull -v "$(pwd):/code" ghcr.io/derickson2402/dockerized-caen:latest <valgrind|perf> <program> [args]
```

# Contributing

I started working on this project while taking EECS-281, in order to make debugging my programs easier. I am sharing this project online in hopes that others will find it useful, but note that I don't have much free time to develop this project.

With that said, if you have an idea that would make this project even better, feel free to log an issue or submit a Pull Request. I greatly appreciate any help on developing this project!

