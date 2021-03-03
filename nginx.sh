#!/bin/bash
NGINX_VERSION="1.19.7"
GO_VERSION="1.16"

export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo apt-get install --no-install-recommends --no-install-suggests -y ca-certificates wget curl unzip git build-essential cmake autoconf libtool libpcre3-dev zlib1g-dev libatomic-ops-dev


if [[ $(dpkg --print-architecture) = "amd64" ]]; then
  wget -N https://dl.google.com/go/go$GO_VERSION.linux-amd64.tar.gz
  tar -xvf go*linux-amd64.tar.gz
  rm -rf go*linux-amd64.tar.gz
elif [[ $(dpkg --print-architecture) = "arm64" ]]; then
  wget -N https://dl.google.com/go/go$GO_VERSION.linux-arm64.tar.gz
  tar -xvf go*linux-arm64.tar.gz
  rm -rf go*linux-arm64.tar.gz
fi

sudo mv -f go /usr/local
export GOROOT=/usr/local/go
export GOPATH=$HOME/work
export PATH="$GOPATH/bin:$GOROOT/bin:$PATH"


wget https://github.com/jemalloc/jemalloc/releases/download/5.2.1/jemalloc-5.2.1.tar.bz2
tar jxf jemalloc-5.2.1.tar.bz2
cd jemalloc-5.2.1
./configure
make && make install
echo '/usr/local/lib' >/etc/ld.so.conf.d/local.conf
ldconfig
cd ..

git clone --dep 1 https://boringssl.googlesource.com/boringssl
cd boringssl && mkdir build && cd build && cmake .. && make && cd ..
mkdir -p .openssl/lib && cd .openssl && cp -R ../include . && cd ..
sudo cp build/crypto/libcrypto.a build/ssl/libssl.a .openssl/lib
cd ..

wget https://ftp.pcre.org/pub/pcre/pcre-8.44.tar.gz
tar -zxvf pcre-8.44.tar.gz
cd pcre-8.44
./configure
make && make install
cd ..

git clone https://github.com/cloudflare/zlib.git
cd zlib
make -f Makefile.in distclean
cd ..

git clone https://github.com/google/ngx_brotli.git
cd ngx_brotli
git submodule update --init
cd ..

sudo mkdir -p "/etc/nginx/conf.d"
sudo mkdir -p /var/log/nginx
sudo mkdir -p /var/cache/nginx/client_temp
sudo mkdir -p /var/cache/nginx/proxy_temp
sudo mkdir -p /var/cache/nginx/fastcgi_temp
sudo mkdir -p /var/cache/nginx/scgi_temp
sudo mkdir -p /var/cache/nginx/uwsgi_temp

wget https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz
tar zxvf nginx-$NGINX_VERSION.tar.gz
mv -f nginx-$NGINX_VERSION buildNginx
sed -i 's/CFLAGS="$CFLAGS -g"/#CFLAGS="$CFLAGS -g"/' buildNginx/auto/cc/gcc
cd buildNginx
curl https://raw.githubusercontent.com/kn007/patch/master/nginx.patch | patch -p1
curl https://raw.githubusercontent.com/kn007/patch/master/Enable_BoringSSL_OCSP.patch | patch -p1
./configure \
  --prefix=/etc/nginx \
  --sbin-path=/usr/sbin/nginx \
  --conf-path=/etc/nginx/nginx.conf \
  --error-log-path=/var/log/nginx/error.log \
  --http-log-path=/var/log/nginx/access.log \
  --pid-path=/run/nginx.pid \
  --lock-path=/run/nginx.lock \
  --http-client-body-temp-path=/var/cache/nginx/client_temp \
  --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
  --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
  --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
  --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
  --user=www-data \
  --group=www-data \
  --with-compat \
  --with-file-aio \
  --with-threads \
  --with-libatomic \
  --with-mail \
  --with-mail_ssl_module \
  --with-http_realip_module \
  --with-http_ssl_module \
  --with-http_addition_module \
  --with-http_sub_module \
  --with-http_dav_module \
  --with-http_stub_status_module \
  --with-http_flv_module \
  --with-http_mp4_module \
  --with-http_gunzip_module \
  --with-http_slice_module \
  --with-http_gzip_static_module \
  --with-http_auth_request_module \
  --with-http_random_index_module \
  --with-http_secure_link_module \
  --with-http_degradation_module \
  --with-http_v2_module \
  --with-http_v2_hpack_enc \
  --with-stream \
  --with-stream_realip_module \
  --with-stream_ssl_module \
  --with-stream_ssl_preread_module \
  --with-zlib=../zlib \
  --with-pcre=../pcre-8.44 \
  --with-pcre-jit \
  --with-openssl=../boringssl \
  --with-cc-opt='-DTCP_FASTOPEN=23 -g -O3 -pipe -Wall -fexceptions -fstack-protector-strong --param=ssp-buffer-size=4 -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -fPIC' \
  --with-ld-opt='-Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,-z,now -Wl,--as-needed -pie -ljemalloc' \
  --add-module=../ngx_brotli

sudo touch ../boringssl/.openssl/include/openssl/ssl.h
make -j $(nproc --all)
