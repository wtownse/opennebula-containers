#!/bin/bash
source ./create-conf.sh

./wait-for-it.sh 127.0.0.1:2633 -t 0 -- ruby /usr/lib/one/oneflow/oneflow-server.rb
