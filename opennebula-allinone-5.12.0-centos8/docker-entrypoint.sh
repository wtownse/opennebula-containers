#!/bin/bash
if [ ! -f /var/lib/one/.one/one_auth ]; then
  mkdir -p /var/lib/one/.one
  echo "oneadmin:${ONEPASSWORD}" > /var/lib/one/.one/one_auth
fi

if [ ! -f /var/lib/one/.ssh/config ]; then
mkdir -p /var/lib/one/.ssh
cat >/var/lib/one/.ssh/config << EOL
Host *
StrictHostKeyChecking no
UserKnownHostsFile /dev/null
Port ${SSH_PORT:=2022}
EOL
fi

if [ ! -f /var/lib/one/.ssh/id_rsa ]; then
sudo -u oneadmin yes | sudo -u oneadmin ssh-keygen -q -t rsa -N '' -f /var/lib/one/.ssh/id_rsa >/dev/null
fi

if [ ! -f /var/lib/one/init.one ]; then
  source /ctrl/oned-conf.sh
  echo "initialized" > /var/lib/one/init.one
  cp -au /var_lib_one/* /var/lib/one
  cp -au /usr_lib_one/* /usr/lib/one
  cp -au /usr_share_one/* /usr/share/one
  cp -au /conf/* /etc/one
fi

if [ ! -f /var/lib/one/sunstoneinit.one ]; then
  source /ctrl/sunstone-conf.sh
  echo "initialized" > /var/lib/one/sunstoneinit.one
  cp -au /var_lib_one/* /var/lib/one
  cp -au /usr_lib_one/* /usr/lib/one
  cp -au /usr_share_one/* /usr/share/one
  cp -au /conf/* /etc/one
fi

if [ -f /var/lock/one/one ]; then
  rm -rf /var/lock/one/one
fi

if [ ! -f /etc/one/oned.conf ]; then
  cp -rf /conf/one/* /etc/one/
  /ctrl/oned-conf.sh
fi

if [ ! -f /etc/one/sunstone-server.conf ]; then
  /ctrl/sunstone-conf.sh
fi

if [[ ! -f /etc/one/onegate/onegate-server.conf ]]; then
  /ctrl/onegate-conf.sh
fi

if [[ ! -f /etc/one/onegate/onegate-server.conf ]]; then
  /ctrl/oneflow-conf.sh
fi
case $1 in
     "oned") /wait-for-it.sh 127.0.0.1:3306 -t 0 -- /ctrl/one.sh
     ;;
     "sunstone") /wait-for-it.sh 127.0.0.1:2633 -t 0 -- /ctrl/sunstone.sh
     ;;
     "oneflow") /wait-for-it.sh 127.0.0.1:2633 -t 0 -- ruby /usr/lib/one/oneflow/oneflow-server.rb
     ;;
     "onegate") /wait-for-it.sh 127.0.0.1:2633 -t 0 -- ruby /usr/lib/one/onegate/onegate-server.rb
     ;;
     "node") /ctrl/libvirtd.sh
     ;;
     *) echo "$0 [oned|sunstone|oneflow|onegate|node]"
esac
