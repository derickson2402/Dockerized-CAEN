# Dockerized-CAEN

This is a Docker container running the same debugging software on UofM CAEN servers, which can integrate into your Makefile for automatic testing on your local machine

To use this container, you need to have Docker installed on your [macOS](https://docs.docker.com/desktop/mac/install/), [Windows](https://docs.docker.com/desktop/windows/install/), or [Linux](https://docs.docker.com/engine/install/) computer.

With Docker installed and running, replace the ```CXX``` variable in your ```Makefile``` with the following:

```Makefile
CXX         = ./caen g++
```

Now when you run ```make``` commands, the compiler in the container will be used. If you want to use ```Valgrind```, ```Perf```, or another supported CAEN program, simply preface the command with the following:

```bash
./caen <program> [args]
```

```bash
docker run --rm -it --pull -v "$(pwd):/code" ghcr.io/derickson2402/dockerized-caen:latest <valgrind|perf> <program> [args]
```
# Contributing

I started working on this project while taking EECS-281, in order to make debugging my programs easier. I am sharing this project online in hopes that others will find it useful, but note that I don't have much free time to develop this project.

With that said, if you have an idea that would make this project even better, feel free to log an issue or submit a Pull Request. I greatly appreciate any help on developing this project!

