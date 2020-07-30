#!/bin/bash
ruby /usr/lib/one/sunstone/sunstone-server.rb
/usr/sbin/logrotate -f /etc/logrotate.d/opennebula-novnc -s /var/lib/one/.logrotate.status
sleep 2
/usr/bin/novnc-server start
