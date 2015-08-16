FROM masaori/docker-openssl:1.0.2d

WORKDIR /opt

RUN apt-get install -y \
    libpcre3-dev

EXPOSE 80 443
