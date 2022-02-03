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
# Builder stage for compiling gcc-6.2.0 compiler

FROM caen-base as gcc-builder

# Install pre-requisite programs for compiling gcc-6.2.0
# https://forums.centos.org/viewtopic.php?f=54&t=78708 because of CentOS deprecation
RUN dnf update -y && dnf install -y --nodocs \
    gcc-c++ \
    libgcc \
    glibc-devel \
    epel-release \
    bzip2 \
    wget \
    flex \
    git \
    openssh \
    make \
    && dnf -y --nodocs --enablerepo=powertools install glibc-static libstdc++-static

# Download the archive from GNU server. Source directory will be /tmp/gcc-6.2.0/,
# object directory will be /tmp/objdir, and install directory will be /usr/um/gcc-6.2.0/
RUN mkdir -p /usr/um/gcc-6.2.0/ /tmp/objdir/ /tmp/gcc-6.2.0/ && cd /tmp \
    && wget https://ftp.gnu.org/gnu/gcc/gcc-6.2.0/gcc-6.2.0.tar.gz \
    && tar -xvf /tmp/gcc-6.2.0.tar.gz -C /tmp/ \
    && cd /tmp/gcc-6.2.0 \
    && /tmp/gcc-6.2.0/contrib/download_prerequisites

# glibc 7 introduced a different way of handling ucontext and sigalstack types,
# meaning that compilation of gcc 6 and the sanitizers will fail. gcc-7.4.0 also
# removed ustat.h for sanitizer_platform_limits_posix.cc, which was already
# deprecated so the headers simply need to be removed. See links below for
# description and workaround.
#
# https://gcc.gnu.org/git/?p=gcc.git&a=commit;h=8774a9cf3435d41cd6a89e93c9d8c34b1c5edbcf
# https://stackoverflow.com/questions/46999900/how-to-compile-gcc-6-4-0-with-gcc-7-2-in-archlinux
# https://stackoverflow.com/questions/56096060/how-to-fix-the-gcc-compilation-error-sys-ustat-h-no-such-file-or-directory-i
# https://github.com/vmware/photon/blob/master/SPECS/gcc/libsanitizer-avoidustat.h-glibc-2.28.patch

WORKDIR /tmp/gcc-6.2.0
RUN sed -i 's/struct ucontext/ucontext_t/' ./libgcc/config/i386/linux-unwind.h \
    && sed -i 's/struct sigalstack/void/' ./libsanitizer/sanitizer_common/sanitizer_linux.cc \
    && sed -i 's/struct sigalstack/void/' ./libsanitizer/sanitizer_common/sanitizer_linux.h \
    && sed -i '/struct sigalstack/d' ./libsanitizer/sanitizer_common/sanitizer_linux.h \
    && sed -i 's/struct sigalstack/stack_t' ./libsanitizer/sanitizer_common/sanitizer_stoptheworld_linux_libcdep.cc \
    && sed -i 's/__res_state/struct __res_state/' ./libsanitizer/tsan/tsan_platform_linux.cc \
    && sed -i 's/sizeof(struct ustat)/32/' ./libsanitizer/sanitizer_common/sanitizer_platform_limits_posix.cc

# Configure the Makefile and compile
WORKDIR /tmp/objdir
RUN unset C_INCLUDE_PATH CPLUS_INCLUDE_PATH CFLAGS CXXFLAGS \
    && /tmp/gcc-6.2.0/configure \
    --with-pkgversion="GCC version 6.2.0 for derickson/Dockerized-CAEN" \
    --with-bugurl="https://github.com/derickson2402/Dockerized-CAEN/issues" \
    --with-changes-root-url="https://github.com/derickson2402/Dockerized-CAEN" \
    --prefix=/usr/um/gcc-6.2.0 \
    --enable-languages=default \
    && make -j 4 \
    && make install


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

# Copy and link our compiled gcc to the system default
COPY --from=gcc-builder /usr/um/gcc-6.2.0/ /usr/um/gcc-6.2.0/
RUN ln -s /usr/um/gcc-6.2.0/bin/gcc /usr/bin/gcc \
    && ln -s /usr/um/gcc-6.2.0/bin/g++ /usr/bin/g++ \
    && ln -s /usr/um/gcc-6.2.0/bin/gfortran /usr/bin/gfortran \
    && echo "export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/code" >> /root/.bashrc

# Run the container in the user's project folder
WORKDIR /code
CMD ["/bin/bash"]
