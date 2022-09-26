################################################################################
#
# Base container which fixes CentOS EOL

FROM centos:8 AS caen-base

# Prep base environment
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/code
VOLUME /code
RUN mkdir -p /usr/um

# CentOS has been deprecated in favor of CentOS stream, so update repo list to
# search archives:
# https://forums.centos.org/viewtopic.php?f=54&t=78708
# https://www.getpagespeed.com/server-setup/how-to-fix-dnf-after-centos-8-went-eol
RUN sed -i \
        -e 's/#baseurl/baseurl/g' \
        -e 's/mirror.centos.org/vault.epel.cloud/g' \
        -e 's/mirrorlist/#mirrorlist/g' \
        /etc/yum.repos.d/CentOS-Linux-* \
    && dnf clean all \
    && dnf swap -y centos-linux-repos centos-stream-repos \
    && dnf install -y --nodocs wget bzip2 tar make

# Set bash as default
SHELL ["/bin/bash", "-c"]


################################################################################
#
# Builder stage for compiling gcc-6.2.0 compiler

FROM caen-base as gcc-builder

# Install pre-requisite programs for compiling gcc-6.2.0
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
    && rm -f /tmp/gcc-6.2.0.tar.gz \
    && cd /tmp/gcc-6.2.0 \
    && /tmp/gcc-6.2.0/contrib/download_prerequisites

# glibc 7 introduced a different way of handling ucontext and sigalstack types,
# meaning that compilation of gcc 6 and the sanitizers will fail. gcc-7.4.0 also
# removed ustat.h for sanitizer_platform_limits_posix.cc, which was already
# deprecated so the headers simply need to be removed. See links below for
# description and workaround.
#
# Note that the build will fail if --enable-languages is not specified. Also note
# that gcc is not compiled with address sanitizers at the moment because there are
# still some bugs to squash, but the sed commands are left here as reference
#
# https://gcc.gnu.org/git/?p=gcc.git&a=commit;h=8774a9cf3435d41cd6a89e93c9d8c34b1c5edbcf
# https://stackoverflow.com/questions/46999900/how-to-compile-gcc-6-4-0-with-gcc-7-2-in-archlinux
# https://stackoverflow.com/questions/56096060/how-to-fix-the-gcc-compilation-error-sys-ustat-h-no-such-file-or-directory-i
# https://github.com/vmware/photon/blob/master/SPECS/gcc/libsanitizer-avoidustat.h-glibc-2.28.patch

WORKDIR /tmp/gcc-6.2.0
RUN sed -i \
        -e 's/struct ucontext/ucontext_t/' \
        ./libgcc/config/i386/linux-unwind.h \
    && sed -i \
        -e 's/struct sigaltstack/void/' \
        ./libsanitizer/sanitizer_common/sanitizer_linux.cc \
    && sed -i \
        -e '/struct sigaltstack;/d' \
        ./libsanitizer/sanitizer_common/sanitizer_linux.h \
    && sed -i \
        -e 's/struct sigaltstack/void/g' \
        ./libsanitizer/sanitizer_common/sanitizer_linux.h \
    && sed -i \
        -e 's/struct sigaltstack/stack_t/' \
        ./libsanitizer/sanitizer_common/sanitizer_stoptheworld_linux_libcdep.cc \
    && sed -i \
        's/__res_state/struct __res_state/g' \
        ./libsanitizer/tsan/tsan_platform_linux.cc \
    && sed -i \
        -e 's/sizeof(struct ustat)/32/' \
        -e '/ustat.h/d' \
        ./libsanitizer/sanitizer_common/sanitizer_platform_limits_posix.cc

# Configure the Makefile and compile
WORKDIR /tmp/objdir
RUN unset C_INCLUDE_PATH CPLUS_INCLUDE_PATH CFLAGS CXXFLAGS \
    && /tmp/gcc-6.2.0/configure \
    --with-pkgversion="GCC version 6.2.0 for derickson/Dockerized-CAEN" \
    --with-bugurl="https://github.com/derickson2402/Dockerized-CAEN/issues" \
    --with-changes-root-url="https://github.com/derickson2402/Dockerized-CAEN" \
    --prefix=/usr/um/gcc-6.2.0 \
    --enable-languages=c,c++,fortran \
    --disable-multilib \
    && make -j 4 \
    && make install \
    && rm -rf /tmp/gcc-6.2.0 /tmp/objdir


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

# Download and compile cppcheck. Note that /usr/share/Cppcheck has an
# uppercase 'C', as this is what CAEN has for some reason
RUN wget https://github.com/danmar/cppcheck/archive/2.4.tar.gz \
        -O /tmp/cppcheck-2.4.tar.gz \
    && tar -C /tmp -xzf /tmp/cppcheck-2.4.tar.gz \
    && rm -rf /tmp/cppcheck-2.4.tar.gz \
    && cd /tmp/cppcheck-2.4 \
    && FILESDIR=/usr/share/Cppcheck make install \
    && rm -rf /tmp/cppcheck-2.4


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
# Default container with all tools and supported languages

FROM caen-base

# Install dev packages and tools, clean dnf cache to save space
RUN dnf --setopt=group_package_types=mandatory \
        groupinstall --nodocs -y "Development Tools" \
    && dnf install --nodocs -y \
        perf \
        valgrind \
        git \
        vim \
        which \
    && dnf clean all \
    && rm -rf /var/cache/yum \
    && rm -rf /var/cache/dnf

# Sym link expected location of CAEN compiler just in case
RUN mkdir -p /usr/um/gcc-6.2.0/bin/ \
    && ln -s /usr/bin/gcc /usr/um/gcc-6.2.0/bin/gcc \
    && ln -s /usr/bin/g++ /usr/um/gcc-6.2.0/bin/g++

# Set up cppcheck
COPY --from=builder-cppcheck /usr/bin/cppcheck /usr/bin/cppcheck
COPY --from=builder-cppcheck /usr/share/Cppcheck /usr/share/Cppcheck

# Set up golang
COPY --from=builder-golang /usr/um/go /usr/um/go
RUN ln -s /usr/um/go/bin/go /usr/bin/go

# Copy and link our compiled gcc to the system default
COPY --from=gcc-builder /usr/um/gcc-6.2.0/ /usr/um/gcc-6.2.0/
RUN ln -s /usr/um/gcc-6.2.0/bin/gcc /usr/local/bin/gcc \
    && ln -s /usr/um/gcc-6.2.0/bin/g++ /usr/local/bin/g++ \
    && ln -s /usr/um/gcc-6.2.0/bin/gfortran /usr/local/bin/gfortran

# Give bash a pretty prompt
ENV PS1='\[\e[0;1;38;5;82m\]CAEN ~\[\e[0m\] '

# Run the container in the user's project folder
WORKDIR /code
CMD ["/bin/bash"]
