#!/bin/bash
GO_VERSION="1.16.5"

export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo apt-get install --no-install-recommends --no-install-suggests -y wget curl ca-certificates unzip git build-essential

if [[ $(dpkg --print-architecture) = "amd64" ]]; then
  wget --no-check-certificate --show-progress -cq https://dl.google.com/go/go$GO_VERSION.linux-amd64.tar.gz
  sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go*linux-amd64.tar.gz
  sudo rm -rf go*linux-amd64.tar.gz
elif [[ $(dpkg --print-architecture) = "arm64" ]]; then
  wget --no-check-certificate --show-progress -cq https://dl.google.com/go/go$GO_VERSION.linux-arm64.tar.gz
  sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go*linux-arm64.tar.gz
  sudo rm -rf go*linux-arm64.tar.gz
fi
export PATH=$PATH:/usr/local/go/bin

rm -rf dns-over-https*
git clone https://github.com/m13253/dns-over-https
cd dns-over-https*
make -j $(nproc --all)
