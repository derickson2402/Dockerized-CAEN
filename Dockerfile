################################################################################
#
# Base container which fixes CentOS EOL

FROM centos:8 AS caen-base

LABEL maintainer = "Dan Erickson (derickson2402@gmail.com)"
LABEL version = "v0.3"
LABEL release-date = "2022-02-02"
LABEL org.opencontainers.image.source = "https://github.com/derickson2402/Dockerized-CAEN"

ENV USER=1000 \
    GROUP=1000
VOLUME /code
RUN mkdir -p /usr/um

# CentOS has been deprecated in favor of CentOS stream, so update repo list to search archives
#
# https://forums.centos.org/viewtopic.php?f=54&t=78708
RUN rm -f /etc/yum.repos.d/CentOS-Linux-AppStream.repo \
    && sed -i \
        -e 's/mirrorlist.centos.org/vault.centos.org/' \
        -e 's/mirror.centos.org/vault.centos.org/' \
        -e 's/#baseurl/baseurl/' /etc/yum.repos.d/CentOS-Linux-BaseOS.repo \
    && dnf clean all \
    && dnf swap -y centos-linux-repos centos-stream-repos \
    && dnf install -y --nodocs wget bzip2 tar which

# Set bash as default
SHELL ["/bin/bash", "-c"]


################################################################################
#
# Development environment with basic tools installed, for testing new layers and
# configurations
 
FROM caen-base AS caen-dev

# Install default packages for developing these containers
RUN dnf update -y \
    && dnf --setopt=group_package_types=mandatory groupinstall --nodocs -y "Development Tools" \
    && dnf install --nodocs -y vim

CMD ["/bin/bash"]


################################################################################
#
# Experimental golang environment
 
FROM caen-base AS caen-golang

RUN wget https://dl.google.com/go/go1.16.12.linux-amd64.tar.gz -O /tmp/go.tar.gz \
    && tar -C /usr/um -xzf /tmp/go.tar.gz \
    && rm -rf /tmp/go.tar.gz /usr/local/go /usr/go /usr/bin/go \
    && ln -s /usr/um/go/bin/go /usr/bin/go

# Run the container in the user's project folder
WORKDIR /code
CMD ["/bin/bash"]


################################################################################
#
# Default container with all current tools and supported languages

FROM caen-base

# Install dev packages and tools
RUN yum --setopt=group_package_types=mandatory groupinstall --nodocs -y "Development Tools" \
    && yum install --nodocs -y perf valgrind \
    && yum clean all \
    && rm -rf /var/cache/yum \
    && rm -rf /var/lib/rpm/Packages

# Sym link expected location of CAEN compiler just in case
RUN mkdir -p /usr/um/gcc-6.2.0/bin/ \
    && ln -s /usr/bin/gcc /usr/um/gcc-6.2.0/bin/gcc \
    && ln -s /usr/bin/g++ /usr/um/gcc-6.2.0/bin/g++ \
    && echo "export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/code" >> /root/.bashrc

# Run the container in the user's project folder
WORKDIR /code
CMD ["/bin/bash"]

