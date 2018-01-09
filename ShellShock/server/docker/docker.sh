#!/bin/sh

#CentOSでDockerを動かす
sudo yum update

sudo tee /etc/yum.repos.d/docker.repo <<-'EOF'
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/$releasever/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF

sudo yum install docker-engine

sudo service docker start

#CentOS（バージョン6.4）のベースイメージを作成
cat centos-64.tar.xz | sudo docker import - local/centos:6.4

#コンテナの作成と実行
sudo docker build -t redsloop/shellshock:latest ./docker-config/Dockerfile

sudo docker run -d -p 8080:80 redsloop/shellshock:latest

