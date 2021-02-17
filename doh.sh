#!/bin/bash
GO_VERSION="1.16"

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install --no-install-recommends --no-install-suggests -y wget curl ca-certificates rsync unzip git build-essential

architecture=""
case $(uname -m) in
    x86_64)  architecture="amd64" ;;
    aarch64)  architecture="arm64" ;;
esac

if [[ $architecture = "amd64" ]]; then
    wget -N https://dl.google.com/go/go$GO_VERSION.linux-amd64.tar.gz
	tar -xvf go*linux-amd64.tar.gz
	rm -rf go*linux-amd64.tar.gz
elif [[ $architecture = "arm64" ]]; then
    wget -N https://dl.google.com/go/go$GO_VERSION.linux-arm64.tar.gz
	tar -xvf go*linux-arm64.tar.gz
	rm -rf go*linux-arm64.tar.gz
fi

mkdir -p $HOME/gopath
mv -f go /usr/local
export GOROOT=/usr/local/go
export GOPATH=$HOME/gopath
export PATH="$GOPATH/bin:$GOROOT/bin:$PATH"

git clone https://github.com/m13253/dns-over-https
cd dns-over-https*
make && make install
