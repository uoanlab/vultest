FROM centos:latest

MAINTAINER Akasaka <redsloop.ko@gmail.com>

ENV SRC_DIR /usr/local/src
ENV APR_VERSION 1.6.3
ENV APR_UTIL_VERSION 1.6.1
ENV APACHE_VERSION 2.4.29
ENV PHP_VERSION 7.2.5

RUN yum update -y && \
    yum install -y gcc && \
    yum install -y make && \
    yum install -y pcre && \
    yum install -y pcre-devel && \
    yum install -y wget && \
    yum install -y zlib-devel && \
    yum install -y openssl-devel && \
    yum install -y expat-devel && \
    yum install -y libxml2-devel && \
    yum install -y perl

#APRをインストール
WORKDIR ${SRC_DIR}
RUN wget http://ftp.yz.yamagata-u.ac.jp/pub/network/apache//apr/apr-${APR_VERSION}.tar.gz && \
    tar -xvzf apr-${APR_VERSION}.tar.gz && \
    rm apr-${APR_VERSION}.tar.gz
WORKDIR apr-${APR_VERSION}
RUN ./configure --prefix=/opt/apr && \
    make && \
    make install

#APR-Utilをインストール
WORKDIR ${SRC_DIR}
RUN wget http://ftp.jaist.ac.jp/pub/apache//apr/apr-util-${APR_UTIL_VERSION}.tar.gz && \
    tar -xvzf apr-util-${APR_UTIL_VERSION}.tar.gz && \
    rm apr-util-${APR_UTIL_VERSION}.tar.gz 
WORKDIR apr-util-${APR_UTIL_VERSION} 
RUN ./configure --prefix=/opt/apr-util --with-apr=/opt/apr && \
    make && \
    make install

#apacheをインストール
WORKDIR ${SRC_DIR}
RUN wget https://archive.apache.org/dist/httpd/httpd-${APACHE_VERSION}.tar.gz&& \
    tar -xvzf httpd-${APACHE_VERSION}.tar.gz && \
    rm httpd-${APACHE_VERSION}.tar.gz
WORKDIR httpd-${APACHE_VERSION}
RUN ./configure --prefix=/opt/httpd --with-apxs2=/opt/httpd/bin/apxs --enable-rewrite=shared --enable-speling=shared  --enable-so --with-apr=/opt/apr --with-apr-util=/opt/apr-util && \
    make && \
    make install
RUN ln -sn /dev/stdout /opt/httpd/logs/access_log && \
    ln -sn /dev/stderr /opt/httpd/logs/error_log

#PHPをインストール
WORKDIR ${SRC_DIR}
RUN wget http://jp2.php.net/get/php-${PHP_VERSION}.tar.gz/from/this/mirror && \
    mv mirror php-${PHP_VERSION}.tar.gz && \
    tar -xvzf php-${PHP_VERSION}.tar.gz && \
    rm php-${PHP_VERSION}.tar.gz
WORKDIR php-${PHP_VERSION}
RUN ./configure --prefix=/opt/php --enable-so --enable-mbstring=ja --enable-zend-multibyte --without-mysql --with-mysqli && \
    make && \
    make install

EXPOSE 80
CMD ["/opt/httpd/bin/apachectl", "-DFOREGROUND"]

