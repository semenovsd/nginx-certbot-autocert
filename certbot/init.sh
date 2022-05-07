#!/bin/sh
set -ex

# Set variables
SSL_PATH="/etc/letsencrypt/live/${DOMAIN_NAME_OR_IP}"
RSA_KEY_SIZE=4096
CERTBOT_DIR="/var/www/certbot"

echo "Waiting for nginx..."
while ! nc -z nginx 80; do
  sleep 1
done
echo "Nginx started"

if openssl verify -CAfile "${SSL_PATH}/chain.pem" "${SSL_PATH}/cert.pem"; then
  echo "Verification for $DOMAIN_NAME_OR_IP OK"
else
  echo "Verification for $DOMAIN_NAME_OR_IP failed"

  echo "### TEST Creating ssl certs for $DOMAIN_NAME_OR_IP to $CERTBOT_DIR..."
  if certbot certonly --dry-run --agree-tos --webroot -w "$CERTBOT_DIR" --email "$DOMAIN_ADMIN_EMAIL" -d "$DOMAIN_NAME_OR_IP"; then
    echo "Test successful"

    echo "### Backup dummy certificate for $DOMAIN_NAME_OR_IP ..."
    mkdir /etc/letsencrypt/backup || true
    mkdir /etc/letsencrypt/backup/live || true
    mkdir /etc/letsencrypt/backup/archive || true
    mkdir /etc/letsencrypt/backup/renewal || true
    cp -rf "/etc/letsencrypt/live/${DOMAIN_NAME_OR_IP}/" "/etc/letsencrypt/backup/live/"
    cp -rf "/etc/letsencrypt/archive/${DOMAIN_NAME_OR_IP}/" "/etc/letsencrypt/backup/archive/" || true
    cp -f "/etc/letsencrypt/renewal/${DOMAIN_NAME_OR_IP}.conf" "/etc/letsencrypt/backup/renewal/${DOMAIN_NAME_OR_IP}.conf" || true
    echo "### Backup done ..."

    echo "### Deleting dummy certificate for $DOMAIN_NAME_OR_IP ..."
    rm -Rf "/etc/letsencrypt/live/${DOMAIN_NAME_OR_IP}" || true
    rm -Rf "/etc/letsencrypt/archive/${DOMAIN_NAME_OR_IP}" || true
    rm -Rf "/etc/letsencrypt/renewal/${DOMAIN_NAME_OR_IP}.conf" || true
    echo "Dummy certificate deleted"

    echo "### Try create ssl certs for $DOMAIN_NAME_OR_IP ..."
    if certbot certonly --webroot -w "$CERTBOT_DIR" --email "$DOMAIN_ADMIN_EMAIL" -d "$DOMAIN_NAME_OR_IP" --rsa-key-size "$RSA_KEY_SIZE" --agree-tos --non-interactive --force-renewal; then
      echo "### Certs for $DOMAIN_NAME_OR_IP created success!"

      echo "### Change owner uid for certs ..."
      chown -R $UID:$GID "/etc/letsencrypt/live"
      chown -R $UID:$GID "/etc/letsencrypt/archive"
      chown -R $UID:$GID "/etc/letsencrypt/renewal"
      echo "### Certs UID changed to $UID:$GID"
    else
      echo "### Certs for $DOMAIN_NAME_OR_IP created FILED!"
      echo "### Make backup dummy certificate for $DOMAIN_NAME_OR_IP ..."
      cp -rf "/etc/letsencrypt/backup/live/${DOMAIN_NAME_OR_IP}" "/etc/letsencrypt/live/"
      cp -rf "/etc/letsencrypt/backup/archive/${DOMAIN_NAME_OR_IP}" "/etc/letsencrypt/archive/" || true
      cp -f "/etc/letsencrypt/backup/renewal/${DOMAIN_NAME_OR_IP}.conf" "/etc/letsencrypt/renewal/${DOMAIN_NAME_OR_IP}.conf" || true
      echo "### Backup done ..."
    fi
  else
    echo "### Test failed..."
  fi
fi

trap exit TERM

while :; do
# TODO interval restart with auto recreate certs if it expire
  echo "### Sleep next 72h"
  sleep 72h & wait ${!}
done
