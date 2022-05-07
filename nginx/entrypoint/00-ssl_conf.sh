#!/bin/sh -x
set -ex

## The worker processes in the nginx image run as the user nginx with group
## nginx. This is where we override their respective uid and guid to something
## else that lines up better with file permissions.
## Customization of the nginx user and group ids in the image. It's 101:101 in
## the base image. Here we use 33 which is the user id and group id for www-data
## on Ubuntu, Debian, etc.
nginx_uid=$UID
nginx_gid=$GID

# download recommended TLS params
if [ ! -e "/etc/letsencrypt/conf/options-ssl-nginx.conf" ] || [ ! -e "/etc/letsencrypt/conf/ssl-dhparams.pem" ]; then
  echo "### Downloading recommended TLS parameters ..."
  mkdir -p "/etc/letsencrypt/conf"
  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > "/etc/letsencrypt/conf/options-ssl-nginx.conf"
  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > "/etc/letsencrypt/conf/ssl-dhparams.pem"
  echo "TLS parameters downloaded"
fi

if [ ! -e "/etc/letsencrypt/live/${DOMAIN_NAME_OR_IP}/privkey.pem" ] || [ ! -e "/etc/letsencrypt/live/${DOMAIN_NAME_OR_IP}/fullchain.pem" ]; then
  echo "### Creating self-signed certificate for ${DOMAIN_NAME_OR_IP} ..."
  SSL_PATH="/etc/letsencrypt/live/${DOMAIN_NAME_OR_IP}"
  mkdir -p "/etc/letsencrypt/live/${DOMAIN_NAME_OR_IP}"

  echo "### Install openssl ..."
  apk upgrade --update-cache --available \
    && apk add openssl \
    && rm -rf /var/cache/apk/*
  echo "### Openssl installed ..."

  echo "### Try creat ssl cert ..."
  openssl req -x509 -nodes -sha256 -newkey rsa:4096 -days 365  \
    -keyout "${SSL_PATH}/privkey.pem" \
    -out "${SSL_PATH}/fullchain.pem" \
    -subj "/C=US/ST=Oregon/L=Portland/O=Company Name/OU=Org/CN=${DOMAIN_NAME_OR_IP}"
  echo "Certificate for ${DOMAIN_NAME_OR_IP} created"

  echo "### Change owner uid for certs ..."
  chown -R $UID:$GID "/etc/letsencrypt/live/${DOMAIN_NAME_OR_IP}" && \
  chown -R $UID:$GID "/etc/letsencrypt/archive/${DOMAIN_NAME_OR_IP}" && \
  chown $UID:$GID "/etc/letsencrypt/renewal/${DOMAIN_NAME_OR_IP}.conf"
  echo "### Certs UID changed to $UID:$GID"

else
  echo "Certificate for ${DOMAIN_NAME_OR_IP} exist"
fi

echo "SSL CONFIGURATION DONE"
