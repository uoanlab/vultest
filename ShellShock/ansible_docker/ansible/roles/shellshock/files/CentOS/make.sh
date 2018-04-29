#!/bin/sh 
cat /usr/local/src/docker/CentOS/centos-64.tar.xz | sudo docker import - akasaka/centos:6.4
