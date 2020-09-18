#!/bin/bash
### Pre Common
groupadd -r -g 9869 oneadmin
    mkdir /var/lib/one || :
    chcon -t user_home_dir_t /var/lib/one 2>/dev/null || :
    cp /etc/skel/.bash* /var/lib/one
    /usr/sbin/useradd -r -m -d /var/lib/one \
        -u 9869 -g 9869 \
        -s /bin/bash oneadmin 2> /dev/null
    chown -R oneadmin:oneadmin /var/lib/one
if ! getent group disk | grep '\boneadmin\b' &>/dev/null; then
    usermod -a -G disk oneadmin
fi
mkdir -p /var/lib/one/sunstone
if [ ! -f /var/lib/one/sunstone/main.js ]; then
    touch /var/lib/one/sunstone/main.js
fi

