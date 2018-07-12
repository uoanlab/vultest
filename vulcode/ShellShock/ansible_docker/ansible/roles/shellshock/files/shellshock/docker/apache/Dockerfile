FROM akasaka/centos:6.4

MAINTAINER Akasaka <redsloop.ko@gmail.com>

ENV SRC_DIR /usr/local/src
ENV APACHE_VERSION 2.2.15

RUN yum install -y gcc && \
    yum install -y make && \
    yum install -y pcre && \
    yum install -y pcre-devel && \
    yum install -y wget && \
    yum install -y zlib-devel && \
    yum install -y openssl-devel && \
    yum install -y expat-devel

#apacheをインストール
WORKDIR ${SRC_DIR}
RUN wget https://archive.apache.org/dist/httpd/httpd-${APACHE_VERSION}.tar.gz&& \
    tar -xvzf httpd-${APACHE_VERSION}.tar.gz && \
    rm httpd-${APACHE_VERSION}.tar.gz
WORKDIR httpd-${APACHE_VERSION}
RUN ./configure --prefix=/opt/httpd --enable-so --enable-mods-shared="all" --with-openssl && \
    make && \
    make install
RUN ln -sn /dev/stdout /opt/httpd/logs/access_log && \
    ln -sn /dev/stderr /opt/httpd/logs/error_log

EXPOSE 80
CMD ["/opt/httpd/bin/apachectl", "-DFOREGROUND"]

