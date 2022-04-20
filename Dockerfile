FROM debian:buster as builder
WORKDIR /root/

RUN apt-get update && apt-get install -y build-essential libpcre3 libpcre3-dev \
    zlib1g zlib1g-dev libssl-dev libgd-dev libxml2 libxml2-dev uuid-dev wget

RUN wget -q -O - https://nginx.org/download/nginx-1.20.2.tar.gz | tar xz

WORKDIR /root/nginx-1.20.2

RUN ./configure \
    --prefix=/var/www/html \
    --sbin-path=/usr/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --http-log-path=/var/log/nginx/access.log \
    --error-log-path=/var/log/nginx/error.log \
    --with-pcre  \
    --lock-path=/var/lock/nginx.lock \
    --pid-path=/var/run/nginx.pid \
    --with-http_ssl_module \
    --with-http_image_filter_module=dynamic \
    --modules-path=/etc/nginx/modules \
    --with-http_v2_module \
    --with-stream=dynamic \
    --with-http_addition_module \
    --with-http_mp4_module \
    --with-http_auth_request_module

ARG threads=4
RUN make -j ${threads}


FROM debian:buster-slim

RUN apt-get update && \
    apt-get install -y make libssl1.1 && apt-get clean

RUN useradd -M -c "Nginx User" www
# clean 69,3
COPY --from=builder /root/nginx-1.20.2 /nginx
WORKDIR /nginx

RUN make install && \
    cd .. && \
    rm -r /nginx

# RUN mkdir -p /nginx/logs && \
#     chown -R nginx:nginx /var/log/nginx* /var/www /var/run/ /nginx

# USER nginx
RUN mkdir -p /var/www/logs
WORKDIR /
CMD ["nginx", "-g", "daemon off;"]
