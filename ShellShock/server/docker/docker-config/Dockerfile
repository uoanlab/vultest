FROM local/centos:6.4

MAINTAINER Kohei Akasaka <redsloop.ko@gmail.com>

RUN ["yum", "install", "-y", "httpd"]

ADD ./files/test.cgi /var/www/cgi-bin/

RUN ["chmod", "755", "/var/www/cgi-bin/test.cgi"]

CMD ["/usr/sbin/httpd", "-D", "FOREGROUND"]

