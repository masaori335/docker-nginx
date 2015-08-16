 .PHONY: cert-setup image fetch patch configure build conf-setup run

IMAGE_NAME = masaori/docker-nginx:1.9.3-http2

cert-setup:
	if [ ! -e server.key ]; then \
		openssl genrsa 2024 > server.key && \
		openssl req -new -key server.key > server.csr && \
		openssl x509 -req -days 3650 -signkey server.key < server.csr > server.pem; \
	fi; 

image: cert-setup
	@docker build -t $(IMAGE_NAME) .
	@docker images

fetch:
	@docker run -i -t  -v $(PWD):/opt $(IMAGE_NAME) /bin/sh -c '\
		wget http://nginx.org/download/nginx-1.9.3.tar.gz && \
	    wget http://nginx.org/patches/http2/patch.http2.txt && \
		tar zxvf nginx-1.9.3.tar.gz'

patch:
	@docker run -i -t  -v $(PWD):/opt $(IMAGE_NAME) /bin/sh -c '\
		cd nginx-1.9.3 && \
		patch -p1 --dry-run < ../patch.http2.txt && \
		patch -p1 < ../patch.http2.txt'

configure:
	@docker run -i -t  -v $(PWD):/opt $(IMAGE_NAME) /bin/sh -c '\
		cd nginx-1.9.3 && \
		./configure --prefix=/opt/nginx \
					--with-http_ssl_module \
					--with-http_v2_module \
					--with-debug \
					--with-cc-opt="-I/usr/local/ssl/include" \
					--with-ld-opt="-L/usr/local/ssl/lib"'

build:
	@docker run -i -t  -v $(PWD):/opt $(IMAGE_NAME) /bin/sh -c '\
		cd nginx-1.9.3 && \
	    make && \
	    make install'

conf-setup:
	@cp server.pem ./nginx/conf/server.pem && \
	 cp server.key ./nginx/conf/server.key && \
	 cp nginx.conf ./nginx/conf/nginx.conf

all:: image fetch patch configure build conf-setup

run:
	@docker run -i -t -P -v $(PWD):/opt $(IMAGE_NAME)

