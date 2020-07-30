#!/bin/bash

if [ -f /etc/one/sunstone-server.conf ]; then
rm /etc/one/sunstone-server.conf
fi
cat >/etc/one/sunstone-server.conf << EOL
:tmpdir: /var/tmp
:one_xmlrpc: ${SUNSTONE_OPENNEBULA_ENDPOINT}
:host: 0.0.0.0
:port: ${SUNSTONE_PORT}
:sessions: memcache
:memcache_host: ${SUNSTONE_MEMCACHE}
:memcache_port: ${SUNSTONE_MEMCACHE_PORT}
:memcache_namespace: opennebula.sunstone
:env: 'prod'
:debug_level: 3
:auth: opennebula
:core_auth: cipher
:remote_version: http://downloads.opennebula.org/latest
:vnc_proxy_port: 29876
:vnc_proxy_support_wss: no
:vnc_proxy_cert:
:vnc_proxy_key:
:vnc_proxy_ipv6: false
:vnc_request_password: false
:lang: en_US
:table_order: desc
:marketplace_url: http://marketplace.opennebula.systems/
:oneflow_server: ${SUNSTONE_ONEFLOW_ENDPOINT}
:mode: 'mixed'
:routes:
    - oneflow
EOL
