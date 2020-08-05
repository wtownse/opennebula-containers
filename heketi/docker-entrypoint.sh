#!/bin/bash
if [ ! -f /etc/heketi/heketi.json ]; then
  cp /conforig/heketi.json /etc/heketi/heketi.json
fi
/usr/bin/heketi-start.sh
