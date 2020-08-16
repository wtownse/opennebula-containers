#!/bin/bash
if [ -f /etc/one/oneflow-server.conf ]; then
rm /etc/one/oneflow-server.conf
fi

cat >/etc/one/oneflow-server.conf << EOL
:one_xmlrpc: ${ONEFLOW_OPENNEBULA_ENDPOINT}
:lcm_interval: 30
:host: 0.0.0.0
:port: 2474
:default_cooldown: 300
:shutdown_action: 'terminate'
:action_number: 1
:action_period: 60
:vm_name_template: '$ROLE_NAME_$VM_NUMBER_(service_$SERVICE_ID)'
:core_auth: cipher
:debug_level: 0
EOL

#echo "serveradmin:${ONEPASSWORD}" >> /var/lib/one/.one/oneflow_auth
