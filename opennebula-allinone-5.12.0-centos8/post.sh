#!/bin/bash
### Post common
    chcon -t user_home_dir_t /var/lib/one 2>/dev/null || :
systemd-tmpfiles --create /usr/lib/tmpfiles.d/opennebula-common.conf || :

### Post Server

    if [ ! -e %{oneadmin_home}/.one/one_auth ]; then
        PASSWORD=$(echo $RANDOM$(date '+%s')|md5sum|cut -d' ' -f1)
        mkdir -p %{oneadmin_home}/.one
        /bin/chmod 700 %{oneadmin_home}/.one
        echo oneadmin:$PASSWORD > %{oneadmin_home}/.one/one_auth
        /bin/chown -R oneadmin:oneadmin %{oneadmin_home}/.one
        /bin/chmod 600 %{oneadmin_home}/.one/one_auth
    fi

    if [ ! -f "/var/lib/one/.ssh/id_rsa" ]; then
        su oneadmin -c "ssh-keygen -N '' -t rsa -f /var/lib/one/.ssh/id_rsa"
        if ! [ -f "/var/lib/one/.ssh/authorized_keys" ]; then
            cp -p /var/lib/one/.ssh/id_rsa.pub /var/lib/one/.ssh/authorized_keys
            /bin/chmod 600 /var/lib/one/.ssh/authorized_keys
        fi
    fi

### Post Node-kvm
if [ -e /etc/libvirt/qemu.conf ]; then
    cp -f /etc/libvirt/qemu.conf "/etc/libvirt/qemu.conf.$(date +'%Y-%m-%d_%H:%M:%%S')"
fi

if [ -e /etc/libvirt/libvirtd.conf ]; then
    cp -f /etc/libvirt/libvirtd.conf "/etc/libvirt/libvirtd.conf.$(date +'%Y-%m-%d_%H:%M:%%S')"
fi

AUGTOOL=$(augtool -A 2>/dev/null <<EOF
set /augeas/load/Libvirtd_qemu/lens Libvirtd_qemu.lns
set /augeas/load/Libvirtd_qemu/incl /etc/libvirt/qemu.conf
set /augeas/load/Libvirtd/lens Libvirtd.lns
set /augeas/load/Libvirtd/incl /etc/libvirt/libvirtd.conf
load

set /files/etc/libvirt/qemu.conf/user oneadmin
set /files/etc/libvirt/qemu.conf/group oneadmin
set /files/etc/libvirt/qemu.conf/dynamic_ownership 0

# Disable PolicyKit https://github.com/OpenNebula/one/issues/1768
set /files/etc/libvirt/libvirtd.conf/auth_unix_ro none
set /files/etc/libvirt/libvirtd.conf/auth_unix_rw none
set /files/etc/libvirt/libvirtd.conf/unix_sock_group oneadmin
set /files/etc/libvirt/libvirtd.conf/unix_sock_ro_perms 0770
set /files/etc/libvirt/libvirtd.conf/unix_sock_rw_perms 0770

save
EOF
)


### Post Sunstone

if [ ! -f /var/lib/one/sunstone/main.js ]; then
    touch /var/lib/one/sunstone/main.js
fi

chown oneadmin:oneadmin /var/lib/one/sunstone/main.js

