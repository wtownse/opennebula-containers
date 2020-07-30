#!/bin/bash
if [ ! -f /etc/libvirt/init.one ]; then
  cp -rf /conf/libvirt/* /etc/libvirt/
  echo "initialized" > /etc/libvirt/init.one
fi
/libvirtd.sh
