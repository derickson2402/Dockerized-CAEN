FROM centos:8

LABEL maintainer="Dan Erickson (derickson2402@gmail.com)"

ENV USER=1000 \
    GROUP=1000

VOLUME /code

RUN yum --setopt=group_package_types=mandatory groupinstall --nodocs -y "Development Tools" \
    && yum install --nodocs -y perf valgrind \
    && yum clean all \
    && rm -rf /var/cache/yum \
    && rm -rf /var/lib/rpm/Packages

RUN mkdir -p /usr/um/gcc-6.2.0/bin/ \
    && ln -s /usr/bin/gcc /usr/um/gcc-6.2.0/bin/gcc \
    && ln -s /usr/bin/g++ /usr/um/gcc-6.2.0/bin/g++ \
    && echo "export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/code" >> /root/.bashrc


SHELL ["/bin/bash", "-c"]

WORKDIR /code

CMD ["/bin/bash"]

