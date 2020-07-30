#!/bin/bash

if [ ! -f /var/lib/one/sunstoneinit.one ]; then
  cp -rf /usr_share_one/* /usr/share/one/
  cp -rf /var_lib_one/* /var/lib/one/
  cp -rf /usr_lib_one/* /usr/lib/one/
  cp -rf /conf/* /etc/one/
  echo "initialized" > /var/lib/one/sunstoneinit.one
fi
if [ ! -f /etc/one/sunstone-server.conf ]; then
  cp -rf /conf/* /etc/one/
fi
source ./create-conf.sh
source ./vncproxy.sh
./wait-for-it.sh 127.0.0.1:2633 -t 0 -- /sunstone.sh
