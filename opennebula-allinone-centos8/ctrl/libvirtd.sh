#!/bin/bash
if [ ! -f /etc/libvirt/init.one ]; then
  cp -rf /conf/libvirt/* /etc/libvirt/
  echo "initialized" > /etc/libvirt/init.one
fi

/usr/bin/chmod 666 /dev/kvm &
sed -i 's/^#user/user/g' /etc/libvirt/qemu.conf &
/usr/sbin/virtlogd &
/usr/sbin/libvirtd

