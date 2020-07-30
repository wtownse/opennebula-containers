#!/bin/bash

if [ ! -f /var/lib/one/init.one ]; then
  cp -rf /init/one /var/lib/
  cp -rf /init/one/.one /var/lib/one/.one
  cp -rf /conf/* /etc/one/
  source ./create-conf.sh
  echo "initialized" > /var/lib/one/init.one
fi
if [ ! -f /etc/one/oned.conf ]; then
  cp -rf /conf/one/* /etc/one/
fi
if [ -f /var/lock/one/one ]; then
  rm -rf /var/lock/one/one
fi
#/bin/bash
./wait-for-it.sh 127.0.0.1:3306 -t 0 -- /one.sh
