################################################################################
#
# Base container which fixes CentOS EOL

FROM centos:8 AS caen-base

LABEL maintainer = "Dan Erickson (derickson2402@gmail.com)"
LABEL version = "v0.5"
LABEL release-date = "2022-02-06"
LABEL org.opencontainers.image.source = "https://github.com/derickson2402/Dockerized-CAEN"

# Prep base environment
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
    && dnf install -y --nodocs wget bzip2 tar make

# Set bash as default
SHELL ["/bin/bash", "-c"]


################################################################################
#
# Development environment with basic tools installed, used for builder layers
# and for testing
 
FROM caen-base AS caen-dev

# Install default packages for developing these containers
RUN dnf update -y \
    && dnf --setopt=group_package_types=mandatory groupinstall --nodocs -y "Development Tools" \
    && dnf install --nodocs -y vim

CMD ["/bin/bash"]


################################################################################
#
# Builder container for compiling cppcheck
 
FROM caen-dev AS builder-cppcheck

# Download and compile cppcheck
RUN wget https://github.com/danmar/cppcheck/archive/2.4.tar.gz \
        -O /tmp/cppcheck-2.4.tar.gz \
    && tar -C /tmp -xzf /tmp/cppcheck-2.4.tar.gz \
    && rm -rf /tmp/cppcheck-2.4.tar.gz \
    && cd /tmp/cppcheck-2.4 && make \
    && mv /tmp/cppcheck-2.4/cppcheck /usr/um/cppcheck


################################################################################
#
# Builder container for compiling cppcheck
 
FROM caen-dev AS builder-golang

# Download and install golang
RUN wget https://dl.google.com/go/go1.16.12.linux-amd64.tar.gz \
        -O /tmp/go.tar.gz \
    && tar -C /usr/um -xzf /tmp/go.tar.gz \
    && rm -rf /tmp/go.tar.gz /usr/local/go /usr/go /usr/bin/go


################################################################################
#
# Default container with all current tools and supported languages

FROM caen-base

# Install dev packages and tools
RUN dnf --setopt=group_package_types=mandatory \
        groupinstall --nodocs -y "Development Tools" \
    && dnf install --nodocs -y perf valgrind \
    && dnf clean all \
    && rm -rf /var/cache/yum \
    && rm -rf /var/lib/rpm/Packages

# Sym link expected location of CAEN compiler just in case
RUN mkdir -p /usr/um/gcc-6.2.0/bin/ \
    && ln -s /usr/bin/gcc /usr/um/gcc-6.2.0/bin/gcc \
    && ln -s /usr/bin/g++ /usr/um/gcc-6.2.0/bin/g++ \
    && echo "export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/code" >> /root/.bashrc

# Set up cppcheck
COPY --from=builder-cppcheck /usr/um/cppcheck /usr/um/cppcheck
RUN ln -s /usr/um/cppcheck /usr/bin/cppcheck

# Set up golang
COPY --from=builder-golang /usr/um/go /usr/um/go
RUN ln -s /usr/um/go/bin/go /usr/bin/go

# Run the container in the user's project folder
WORKDIR /code
CMD ["/bin/bash"]
