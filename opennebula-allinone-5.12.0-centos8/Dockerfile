# === Stage 1 ===
# ------------------------------------------------------------------------------
# Stage 1 - Base image
# ------------------------------------------------------------------------------

ARG ONE_VERSION=5.12.0.1
ARG RUBY_PATH=/usr
ARG RUBY_VERSION=2.5.5
ARG RUBY_CONFIGURE_OPTS=--with-jemalloc

FROM centos:8 as base

RUN dnf install -y epel-release && dnf install -y 'dnf-command(config-manager)' \
&& dnf config-manager --set-enabled PowerTools

RUN yum install -y openssl-devel readline-devel zlib-devel \
    wget curl git vim bzip2 tar ImageMagick ImageMagick-devel \
    libffi-devel mysql mysql-devel libxslt-devel redis \
    python3 \
&&  yum groupinstall "Development Tools" -y \
&&  yum clean all

# node.js LTS install
RUN curl --silent --location https://rpm.nodesource.com/setup_12.x | bash - \
    && yum -y install nodejs \
    && npm -g up

# yarn install
RUN curl -o- -L https://yarnpkg.com/install.sh | bash

# pip install
RUN wget https://bootstrap.pypa.io/get-pip.py \
&&  python3 get-pip.py

# s3cmd install
RUN pip3 install s3cmd

# phantomjs install
ENV PHANTOMJS_VERSION 2.1.1
RUN wget -U "wget" --wait=5 https://github.com/Medium/phantomjs/releases/download/v${PHANTOMJS_VERSION}/phantomjs-${PHANTOMJS_VERSION}-linux-x86_64.tar.bz2 \
&&  tar xf phantomjs-${PHANTOMJS_VERSION}-linux-x86_64.tar.bz2 \
&&  mv     phantomjs-${PHANTOMJS_VERSION}-linux-x86_64/bin/phantomjs /usr/bin/phantomjs \
&&  rm -rf phantomjs-${PHANTOMJS_VERSION}-linux-x86_64 \
&&  rm     phantomjs-${PHANTOMJS_VERSION}-linux-x86_64.tar.bz2

# dockerize install
ENV DOCKERIZE_VERSION v0.6.0
RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
&&  tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
&&  rm dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz
ARG RUBY_PATH=/usr
ARG RUBY_VERSION=2.5.5
ARG RUBY_CONFIGURE_OPTS=--with-jemalloc
# === Stage 2 ===
# ------------------------------------------------------------------------------
# Stage 2 - Ruby build
# ------------------------------------------------------------------------------


FROM base AS rubybuild
ARG RUBY_PATH
ARG RUBY_VERSION
ARG RUBY_CONFIGURE_OPTS
RUN echo "RUBY_VERSION:${RUBY_VERSION} RUBY_PATH:${RUBY_PATH} RUBY_CONFIGURE_OPTS:${RUBY_CONFIGURE_OPTS}"
RUN git clone git://github.com/rbenv/ruby-build.git $RUBY_PATH/plugins/ruby-build \
&&  $RUBY_PATH/plugins/ruby-build/install.sh
RUN yum -y install jemalloc-devel
RUN RUBY_CONFIGURE_OPTS=$RUBY_CONFIGURE_OPTS ruby-build $RUBY_VERSION $RUBY_PATH/

# === Stage 3 ===
# ------------------------------------------------------------------------------
# Stage 3 - Ruby install
# ------------------------------------------------------------------------------

FROM centos:8 AS opennebula-ruby
ARG RUBY_PATH
ENV PATH $RUBY_PATH/bin:$PATH
RUN dnf install -y epel-release \
&& dnf install -y 'dnf-command(config-manager)' \
&& dnf config-manager --set-enabled PowerTools
RUN yum -y install \
        jemalloc-devel \
        make \
        gcc \
        git \
        openssl-devel \
        zlib-devel \
        mysql-devel \
        redis \
        sqlite-devel \
        bzip2

COPY --from=rubybuild $RUBY_PATH $RUBY_PATH
RUN gem update --system
CMD [ "irb" ]

# ------------------------------------------------------------------------------
# Stage 4 - opennebula install
# ------------------------------------------------------------------------------

ARG ONE_VERSION=5.12.0.1
ARG BUILD_DIR="/tmp/build"

FROM opennebula-ruby

ARG ONE_VERSION
ARG BUILD_DIR="/tmp/build"
# Install build dependencies

RUN yum install -y epel-release
RUN yum install -y 'dnf-command(config-manager)' \
 && yum config-manager --set-enabled PowerTools \
 && yum -y install centos-release-openstack-train
RUN yum update -y \
 && yum install -y rpm-build gcc-c++ libcurl-devel libxml2-devel xmlrpc-c-devel openssl-devel \
    mysql-devel sqlite-devel openssh pkgconfig sqlite-devel xmlrpc-c java-1.8.0-openjdk-devel \
    createrepo wget make git augeas augeas-libs which m4 rpm-build ruby ruby-devel \
    patch readline readline-devel zlib zlib-devel openldap-devel \
    libyaml-devel libffi-devel openssl-devel libpq-devel libnsl2-devel \
    bzip2 autoconf automake libtool bison python2-setuptools python2-wheel \
    systemd-devel libvncserver-devel gnutls-devel libjpeg-turbo-devel \
    python3-devel python3-rpm-macros python3-scons python3-setuptools python3-wheel \
    cronie ipset libvirt nfs-utils openssh-clients openssh-server pciutils qemu-img \
    qemu-kvm rsync glibc-common shadow-utils sudo openssl openssh genisoimage \
    openvswitch libibverbs \
&& npm install -g bower
RUN echo "install: --no-document" > /etc/gemrc

# Workaround tty check, see https://github.com/hashicorp/vagrant/issues/1673#issuecomment-26650102
RUN sed -i 's/^mesg n/tty -s \&\& mesg n/g' /root/.bash_profile

# Switch to a bash login shell
SHELL ["/bin/bash", "-l", "-c"]
# Install Ruby and initialise bundler
RUN ruby --version \
 && gem --version \
 && gem install bundler

#RUN wget -q -O - "https://github.com/OpenNebula/one/archive/release-$ONE_VERSION.tar.gz" | tar -xzf - \
RUN git clone --depth 1 -b release-5.12.0.1 https://github.com/OpenNebula/one.git \ 
 && mv /one /opennebula-$ONE_VERSION \
 && mkdir -p $BUILD_DIR \
 && export BUILD_DIR=$BUILD_DIR

COPY build_opennebula.sh /build_opennebula.sh
COPY xmlrpc-c.tar.gz /xmlrpc-c.tar.gz
COPY xml_parse_huge.patch /xml_parse_huge.patch
COPY pre.sh /pre.sh
COPY post.sh /post.sh
RUN dnf -y erase xmlrpc-c xmlrpc-c-devel && chmod +x /pre.sh && chmod +x /post.sh \
&& /pre.sh
RUN cd / && tar xvzf xmlrpc-c.tar.gz && cd xmlrpc-c && patch -p1 < /xml_parse_huge.patch && ./configure --enable-libxml2-backend \
 && echo 'MUST_BUILD_SHLIB = NO'   >> config.mk \
 && echo 'MUST_BUILD_SHLIBLE = NO' >> config.mk \
 && echo 'SHARED_LIB_TYPE = NONE'  >> config.mk \
 && make && make install
# && cd /opennebula-$ONE_VERSION

RUN set -e -o pipefail \
 && set -x \
 && BUILD_DIR="${PWD}" \
 && export CXXFLAGS=${CXXFLAGS:--fPIC} \
 && export CFLAGS=${CFLAGS:--Wno-error} \
 && echo '***** Compilation Flags' >&2 \
 && echo "- CFLAGS='${CFLAGS}'" >&2 \
 && echo "- CXXFLAGS='${CXXFLAGS}'" >&2 \
 && echo "- CPPFLAGS='${CPPFLAGS}'" >&2 \
 && echo "- LDFLAGS='${LDFLAGS}'" >&2 \
 && export PATH=$PWD/install/bin:$PATH \
 && cd "/opennebula-$ONE_VERSION" \
 && "${SCONS:-scons-3}" -j2 \
    mysql=yes \
    postgresql=yes \
    xmlrpc="${BUILD_DIR}/../xmlrpc-c/install" \
    new_xmlrpc=yes \
    "$@"

RUN /post.sh && cd /opennebula-$ONE_VERSION \
 && ./install.sh \
 && dnf install -y redhat-lsb-core \
 && /opennebula-$ONE_VERSION/share/install_gems/install_gems --yes \
 && gem install ronn \
 && gem cleanup openssl \
 && pushd /opennebula-$ONE_VERSION/share/man \
 && ./build.sh \
 && popd \
 && pushd /opennebula-$ONE_VERSION/src/sunstone/public \
 && ./build.sh -d \
 && popd \
 && chown -R oneadmin:oneadmin /usr/share/one \
 && chown -R oneadmin:oneadmin /var/lib/one \
 && chown -R oneadmin:oneadmin /usr/lib/one \
 && chown -R oneadmin:oneadmin /etc/one \
 && chown -R oneadmin:oneadmin /var/log/one \
 && cd / \
 && rm -rf /opennebula-5.12.0.1 /xmlrpc-c /xml_parse_huge.patch /xmlrpc-c.tar.gz /build_opennebula.sh /post.sh /pre.sh
# && pushd /opennebula-$ONE_VERSION/src/oca/java \
# && ./build.sh -d \
# && popd


# -------------------------------------------------------------------------------
# Configuration
# -------------------------------------------------------------------------------

COPY docker-entrypoint.sh ./docker-entrypoint.sh
COPY wait-for-it.sh ./wait-for-it.sh
COPY ctrl /ctrl
COPY css.patch /css.patch
RUN patch -p0 -d/ < /css.patch && rm /css.patch

RUN chmod +x docker-entrypoint.sh && mkdir /var_lib_one && mkdir /conf && cp -rf /etc/one/* /conf/ && mkdir /usr_share_one \
&& cp -rf /usr/share/one/* /usr_share_one/ && mkdir /usr_lib_one && cp -rf /usr/lib/one/* /usr_lib_one/ \
&& cp -rf /var/lib/one/* /var_lib_one/ && chmod +x wait-for-it.sh \
&& chown -R oneadmin:oneadmin /var_lib_one \
&& chown -R oneadmin:oneadmin /usr_lib_one \
&& chown -R oneadmin:oneadmin /usr_share_one \
&& chown -R oneadmin:oneadmin /conf \
&& chown -R oneadmin:oneadmin /var/lib/one \
&& chown -R oneadmin:oneadmin /etc/one \
&& chown -R oneadmin:oneadmin /usr/share/one \
&& chown -R oneadmin:oneadmin /usr/lib/one \
&& chown -R oneadmin:oneadmin /var/lock/one \
&& mkdir -p /var/run/sshd \
&& chmod ugoa+rwx /ctrl/* \
&& chown -R oneadmin:oneadmin /ctrl/

# Logging to /dev/stdout, do not daemonize novnc-server
RUN sed -i 's|^\(SUNSTONE_LOG *=\).*|\1 "/dev/stdout"|' /usr/lib/one/sunstone/sunstone-server.rb \
&& sed -i 's|^\(VNC_LOG *=\).*|\1 "/dev/stdout"|' /usr/bin/novnc-server \
&& sed -i '/cmd *=/a\ exec(cmd)' /usr/lib/one/ruby/OpenNebulaVNC.rb \
&& ln -s /usr/bin/python3 /usr/bin/python \
&& sed -i 's|^\(ONEFLOW_LOG *=\).*|\1 "/dev/stdout"|' /usr/lib/one/oneflow/oneflow-server.rb \
&& sed -i 's|^\(ONEGATE_LOG *=\).*|\1 "/dev/stdout"|' /usr/lib/one/onegate/onegate-server.rb

RUN cp -au /etc/libvirt /conf \
&& chmod +x /docker-entrypoint.sh \
&& echo "devpts /dev/pts devpts gid=5,mode=620 0 0" > /etc/fstab \
&& sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd \
&& ssh-keygen -A \
&& rm -rf /run/nologin

EXPOSE 9869 5030 2474 29876 5900-6100 16509 2633 2022
USER oneadmin

VOLUME ["/var/lib/libvirt"]

#ENTRYPOINT [ "/bin/bash" ]
ENTRYPOINT ["./docker-entrypoint.sh"]

