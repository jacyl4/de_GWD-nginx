#!/bin/bash
NGINX_VERSION="1.21.0"
GO_VERSION="1.16.5"
PCRE_VERSION="8.45"

export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo apt-get install --no-install-recommends --no-install-suggests -y ca-certificates wget curl unzip git build-essential cmake autoconf libtool libpcre3-dev zlib1g-dev libatomic-ops-dev

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

wget https://ftp.pcre.org/pub/pcre/pcre-$PCRE_VERSION.tar.gz
tar -zxvf pcre-$PCRE_VERSION.tar.gz
cd pcre-$PCRE_VERSION
./configure
make -j $(nproc --all) && make install
cd ..

git clone --dep 1 https://boringssl.googlesource.com/boringssl
cd boringssl && mkdir build && cd build && cmake .. && make -j $(nproc --all) && cd ..
mkdir -p .openssl/lib && cd .openssl && cp -R ../include . && cd ..
sudo cp build/crypto/libcrypto.a build/ssl/libssl.a .openssl/lib
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
  --with-pcre=../pcre-$PCRE_VERSION \
  --with-pcre-jit \
  --with-openssl=../boringssl \
  --with-cc-opt='-g -O2 -fPIE -Wdate-time -fstack-protector-strong -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -flto -fuse-ld=gold --param=ssp-buffer-size=4 -DTCP_FASTOPEN=23 -I ../boringssl/.openssl/include/' \
  --with-ld-opt='-Wl,-Bsymbolic-functions -fPIE -pie -Wl,-z,relro -Wl,-z,now -Wl,--as-needed -L ../boringssl/.openssl/lib/' \
  --add-module=../ngx_brotli

sudo touch ../boringssl/.openssl/include/openssl/ssl.h
make -j $(nproc --all)

cp objs/nginx ../
