#!/bin/bash

/usr/bin/chmod 666 /dev/kvm &
sed -i 's/^#user/user/g' /etc/libvirt/qemu.conf &
/usr/sbin/virtlogd &
/usr/sbin/libvirtd

