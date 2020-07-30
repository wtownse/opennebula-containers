#!/bin/bash

#cp -rf /share/* /usr/share/one/
#cp -rf /init/one/* /var/lib/one/
#cp -rf /conf/* /etc/one/
source ./create-conf.sh

./wait-for-it.sh 127.0.0.1:2633 -t 0 -- /sunstone.sh
