#!/bin/bash
source ./create-conf.sh

./wait-for-it.sh one:2633 -t 0 -- ruby /usr/lib/one/oneflow/onegate-server.rb
