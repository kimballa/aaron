#!/usr/bin/env bash
#
# renew-gremblor-cert.sh
# This renews the vpn.gremblor.com certificate.
#
# You must poke a hole through the firewall
#   IPv4 Policy: Enable "www-80-port-forwarding"
#   Virtual IPs: ensure that test vip and test vip group point to this machine.
# You must then upload the cert to the fortigate yourself.
#   Upload as type 'certificate'
#   * provide fullchain.pem as the cert.
#   * provide privkey.pem as the private key; no password.
# Change: VPN > SSL-VPN Settings > Server Certificate
# Change: System > Settings > HTTPS Server Certificate
# Disable port 80 forwarding.

cd $HOME/src/ext/letsencrypt
./letsencrypt-auto certonly --standalone --expand --renew-by-default --agree-tos \
    --standalone-supported-challenges http-01 \
    -d vpn.gremblor.com

