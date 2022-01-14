FROM centos:8

LABEL maintainer="Dan Erickson (derickson2402@gmail.com)"

ENV USER=1000 \
    GROUP=1000

VOLUME /code

RUN yum install --nodocs -y \
    valgrind \
    perf \
    gcc \
    && yum clean all \
    && rm -rf /var/cache/yum \
    && rm -rf /var/lib/rpm/Packages

