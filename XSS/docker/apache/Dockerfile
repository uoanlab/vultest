FROM centos:latest

MAINTAINER Akasaka <redsloop.ko@gmail.com>

#ソースコードの置く場所
ENV SRC_DIR /usr/local/src

#apacheのバージョン
ENV APR_VERSION 1.6.3
ENV APR_UTIL_VERSION 1.6.1
ENV APACHE_VERSION 2.4.29

#phpのバージョン
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
    yum install -y perl && \
    yum install -y libxml2-devel 

#apacheユーザを作成
RUN useradd apache 

# APRをインストール
WORKDIR ${SRC_DIR}}
RUN wget http://ftp.yz.yamagata-u.ac.jp/pub/network/apache//apr/apr-${APR_VERSION}.tar.gz && \
    tar -xvzf apr-${APR_VERSION}.tar.gz && \
    rm apr-${APR_VERSION}.tar.gz
WORKDIR apr-${APR_VERSION}
RUN ./configure --prefix=/usr/local/apr && \
    make &&\
    make install

#APR-utilをインストール
WORKDIR ${SRC_DIR}
RUN wget http://ftp.jaist.ac.jp/pub/apache//apr/apr-util-${APR_UTIL_VERSION}.tar.gz && \
    tar -xvzf apr-util-${APR_UTIL_VERSION}.tar.gz && \
    rm apr-util-${APR_UTIL_VERSION}.tar.gz
WORKDIR apr-util-${APR_UTIL_VERSION}
RUN ./configure --prefix=/usr/local/apr-util \
    --with-apr=/usr/local/apr && \
    make && \
    make install

#apacheをインストール
WORKDIR ${SRC_DIR}
RUN wget http://ftp.jaist.ac.jp/pub/apache//httpd/httpd-${APACHE_VERSION}.tar.gz && \
    tar -xvzf httpd-${APACHE_VERSION}.tar.gz && \
    rm httpd-${APACHE_VERSION}.tar.gz
WORKDIR httpd-${APACHE_VERSION}
RUN ./configure --prefix=/usr/local/httpd \
    --with-apr=/usr/local/apr \
    --with-apr-util=/usr/local/apr-util \
    --enable-module=all \
    --enable-so \
    --with-openssl && \
    make && \
    make install

#httpd.confのコピー
COPY ./files/conf/httpd.conf /usr/local/httpd/conf/httpd.conf

#apacheの所有権をapacheユーザに付与
RUN chown -R apache:apache /usr/local/apr && \
    chown -R apache:apache /usr/local/apr-util && \
    chown -R apache:apache /usr/local/httpd

#ポートを解放
EXPOSE 80

#phpをインストール
WORKDIR ${SRC_DIR}
COPY ./files/source/php-${PHP_VERSION}.tar.gz ${SRC_DIR}
RUN tar -xvzf php-${PHP_VERSION}.tar.gz && \
    rm php-${PHP_VERSION}.tar.gz
WORKDIR php-${PHP_VERSION}
RUN ./configure --disable-debug \
    --with-apxs2=/usr/local/httpd/bin/apxs \
    --enable-trans-sid \
    --enable-so \
    --with-iconv \
    --enable-mbstring \
    --enable-zend-multibyte \
    --without-mysql \
    --with-pdo-mysql=mysqlnd \
    --with-mysqli && \
    make && \
    make install && \
    cp php.ini-development /usr/local/lib/php.ini

#XSSのファイルをコピー
COPY ./files/htdocs/xss.php /usr/local/httpd/htdocs/xss.php
CMD ["/usr/local/httpd/bin/apachectl", "-DFOREGROUND"]

