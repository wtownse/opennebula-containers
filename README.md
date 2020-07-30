# opennebula-containers
Contains docker build files for containerizing system controller components.

Requires:

Packages:
- pciutils
- ruby
- docker-ce
- docker-ce-cli
- containerd.io
- docker-compose
- libvirt-client

Permissions:
- create oneadmin user with id 9869 and home /var/lib/one
- configure oneadmin with keyless ssh to host via ip and hostname
- grant ownership to oneadmin user to the following directories
  - /var/log/one
  - /var/lib/one
  - /usr/lib/one
  - /usr/share/one

Centos 7 host Example:

- yum install -y libvirt-client
- yum install -y pciutils
- yum install -y yum-utils
- yum-config-manager --add-repo  https://download.docker.com/linux/centos/docker-ce.repo
- yum install -y docker-ce docker-ce-cli containerd.io
- yum install -y ruby
- curl -L "https://github.com/docker/compose/releases/download/1.26.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
- chmod +x /usr/local/bin/docker-compose
- systemctl start docker
- systemctl enable docker
- useradd -m -d /var/lib/one -u 9869 oneadmin
- chown -R oneadmin:oneadmin /var/log/one /usr/lib/one /usr/share/one

Redeploy:
- delete /var/lib/one/* to overwrite installation.
- rm -rf /var/lib/one/*

Credentials:
- defaults to oneadmin:opennebula
