FROM debian:buster-slim
LABEL maintainer "JacyL4 - jacyl4@gmail.com"

ENV NGINX_VERSION 1.19.2

RUN set -x \
	&& export DEBIAN_FRONTEND=noninteractive \
	&& apt-get update \
	&& apt-get install --no-install-recommends --no-install-suggests -y ca-certificates wget curl unzip git build-essential cmake golang autoconf libtool tzdata libpcre3-dev zlib1g-dev libatomic-ops-dev \
	&& echo "Asia/Shanghai" > /etc/timezone \
	&& ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
	&& curl https://sh.rustup.rs -sSf | bash -s -- -y \
	&& export PATH="$HOME/.cargo/bin:$PATH" \
	&& mkdir -p /tmp/src \
	&& mkdir -p /etc/nginx \
	&& mkdir -p /etc/nginx/conf.d \
	&& mkdir -p /var/log/nginx \
	&& mkdir -p /var/cache/nginx/client_temp \
	&& mkdir -p /var/cache/nginx/proxy_temp \
	&& mkdir -p /var/cache/nginx/fastcgi_temp \
	&& mkdir -p /var/cache/nginx/scgi_temp \
	&& mkdir -p /var/cache/nginx/uwsgi_temp \
	&& cd /tmp/src \
	&& git clone --recursive https://github.com/cloudflare/quiche \
	&& cd /tmp/src \
	&& git clone https://github.com/cloudflare/zlib.git \
	&& cd /tmp/src/zlib \
	&& make -f Makefile.in distclean \
	&& cd /tmp/src \
	&& git clone https://github.com/google/ngx_brotli.git \
	&& cd /tmp/src/ngx_brotli \
	&& git submodule update --init \
	&& cd /tmp/src \
	&& wget https://ftp.pcre.org/pub/pcre/pcre-8.44.tar.gz \
	&& tar -zxvf pcre-8.44.tar.gz \
	&& cd /tmp/src \
	&& wget https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz \
	&& tar zxvf nginx-$NGINX_VERSION.tar.gz \
	&& sed -i 's/CFLAGS="$CFLAGS -g"/#CFLAGS="$CFLAGS -g"/' /tmp/src/nginx-$NGINX_VERSION/auto/cc/gcc \
	&& cd /tmp/src/nginx-$NGINX_VERSION \
	&& curl https://raw.githubusercontent.com/kn007/patch/master/nginx_with_quic.patch | patch -p1 \
	&& curl https://raw.githubusercontent.com/kn007/patch/master/Enable_BoringSSL_OCSP.patch | patch -p1 \
	&& ./configure \
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
		--with-http_v3_module \
		--with-http_v2_hpack_enc \
		--with-stream \
		--with-stream_realip_module \
		--with-stream_ssl_module \
		--with-stream_ssl_preread_module \
		--with-zlib=/tmp/src/zlib \
		--with-pcre=/tmp/src/pcre-8.44 \
		--with-pcre-jit \
		--with-quiche=/tmp/src/quiche \
		--with-openssl=/tmp/src/quiche/deps/boringssl \
		--with-cc-opt='-DTCP_FASTOPEN=23 -g -O2 -pipe -Wall -fexceptions -fstack-protector-strong --param=ssp-buffer-size=4 -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -fPIC' \
		--with-ld-opt='-Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,-z,now -Wl,--as-needed -pie' \
		--add-module=/tmp/src/ngx_brotli \
	&& make && make install \
	&& rustup self uninstall -y \
	&& rm -rf /tmp/* \
	&& apt-get remove --purge --auto-remove -y autoconf autotools-dev binutils binutils-common binutils-x86-64-linux-gnu build-essential bzip2 ca-certificates cmake cpp cpp-8 \
		curl dpkg-dev file g++ g++-8 gcc gcc-8 git git-man golang libasan5 libatomic1 libbinutils libcc1-0 libcurl3-gnutls libcurl4 libdpkg-perl liberror-perl libexpat1 libgcc-8-dev \
		libgdbm-compat4 libgdbm6 libgomp1 libgssapi-krb5-2 libisl19 libitm1 libk5crypto3 libkeyutils1 libkrb5-3 libkrb5support0 libldap-2.4-2 libldap-common liblsan0 libmagic-mgc \
		libmagic1 libmpc3 libmpfr6 libmpx2 libnghttp2-14 libpcre2-8-0 libperl5.28 libpsl5 libquadmath0 librtmp1 libsasl2-2 libsasl2-modules-db libsigsegv2 libssh2-1 libstdc++-8-dev libtool libtsan0 libubsan1 \
		m4 make openssl patch perl perl-modules-5.28 unzip wget xz-utils \
	&& apt-get clean all \
	&& rm -rf /var/lib/apt/lists/*

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]
