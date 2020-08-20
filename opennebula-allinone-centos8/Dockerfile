# === Stage 1 ===
# ------------------------------------------------------------------------------
# Stage 1 - Opennebula rpm build
# ------------------------------------------------------------------------------

ARG RUBY_PATH=/usr
ARG RUBY_VERSION=2.5.5
ARG RUBY_CONFIGURE_OPTS=--with-jemalloc

FROM centos:8 as builder

ARG RUBY_PATH=/usr
ARG RUBY_VERSION=2.5.5
ARG RUBY_CONFIGURE_OPTS=--with-jemalloc

# Setup environment variables
ENV VERSION="5.10.4" \
    PKG_VERSION=1 \
    BUILD_DIR="/tmp/build" \
    BUILD_DIR_SPKG="/tmp/spkg" \
    MOCK_DIR_GEMS="/tmp/mobuild" \
    CONTACT="Unsupported Community Build" \
    GIT_VERSION="not known" \
    DISTRO=centos8 \
    GEMFILE_LOCK='CentOS8' \
    URL="opennebula-5.10.4.tar.gz" \
    PKG_VERSION="5.10.4" \
    SPEC="centos8.spec" \
    PACKAGES_DIR="/packages-5.10.4" \
    SOURCES_DIR="/packages-5.10.4/sources" \
    SOURCE="$(basename ${URL})" \
    PACKAGE="opennebula-5.10.4" \
    NAME="$(echo ${PACKAGE} | cut -d'-' -f1)" \
    CONTACT="${CONTACT:-Unsupported Community Build}" \
    BASE_NAME="${NAME}-${VERSION}-${PKG_VERSION}" \
    GEMS_RELEASE="${VERSION}_${PKG_VERSION}.${DIST_TAG}" \
    GIT_VERSION="${GIT_VERSION:-not known}" \
    RUBY_VERSION=${RUBY_VERSION}
    #DATE=$(date +'%a %b %d %Y')

RUN mkdir -p /tmp/{spkg,build,mobuild}

# Install build dependencies

RUN yum install -y epel-release
RUN yum install -y 'dnf-command(config-manager)' \
 && yum config-manager --set-enabled PowerTools
RUN yum update -y \
 && yum install -y npm rpm-build gcc-c++ libcurl-devel libxml2-devel xmlrpc-c-devel openssl-devel \
    mysql-devel sqlite-devel openssh pkgconfig python3-scons sqlite-devel xmlrpc-c java-1.8.0-openjdk-devel \
    createrepo wget make npm git augeas augeas-libs which m4 rpm-build ruby ruby-devel

RUN yum install -y gcc-c++ patch readline readline-devel zlib zlib-devel \   
    libyaml-devel libffi-devel openssl-devel make which \
    bzip2 autoconf automake libtool bison sqlite-devel python2 python2-devel

RUN echo "install: --no-document" > /etc/gemrc 


# Workaround tty check, see https://github.com/hashicorp/vagrant/issues/1673#issuecomment-26650102
RUN sed -i 's/^mesg n/tty -s \&\& mesg n/g' /root/.bash_profile


# Switch to a bash login shell 
SHELL ["/bin/bash", "-l", "-c"]

# Install Ruby and initialise bundler
RUN ruby --version \
 && gem --version \
 && gem install bundler


# Download sources
COPY packages-release-5.10.4.tar.gz ./packages-release-5.10.4.tar.gz
RUN wget -q -O - "https://github.com/OpenNebula/one/archive/release-5.10.4.tar.gz" | tar -xzf - \
 && mv /one-release-5.10.4 /opennebula-5.10.4 \
# && wget -q -O - "https://github.com/OpenNebula/packages/archive/release-5.10.4.tar.gz" | tar -xvzf - \
&& tar xzf /packages-release-5.10.4.tar.gz && mv /packages-release-5.10.4 /packages-5.10.4 \ 
&& gem install ronn

WORKDIR /opennebula-$VERSION

# Apply patches
RUN wget -q -O - "https://github.com/OpenNebula/one/pull/4585.diff" | patch -p1

# Build docs
RUN cd share/man \
 && ./build.sh

# Build Sunstone
RUN cd src/sunstone/public \
 && ./build.sh -d \
 && export PATH=$PATH:$PWD/node_modules/.bin \
 && ./build.sh \
 && rm -rf node_modules/

# Prepare sources
RUN tar -czf /opennebula-${VERSION}.tar.gz /opennebula-${VERSION} \
&& cp -r /packages-$VERSION/templates/$DISTRO/ /centos7 \
&& cp "${PACKAGES_DIR}/templates/${DISTRO}"/* "${BUILD_DIR_SPKG}" \
&& cd "${BUILD_DIR_SPKG}" \
&& wget -q http://downloads.opennebula.org/extra/xmlrpc-c.tar.gz \
&& cp "${SOURCES_DIR}/build_opennebula.sh" . \
&& cp "${SOURCES_DIR}/xml_parse_huge.patch" . \
&& cp -r "/$PACKAGE" . \
&& mkdir -p /data \
&& ln -s ${PACKAGES_DIR} /data/packages \
&& ln -s ${BUILD_DIR_SPKG} /data/source \
&& ln -s ${MOCK_DIR_GEMS} /data/build \
&& tar czf /opennebula-$VERSION.tar.gz /opennebula-$VERSION \
&& yes|cp /opennebula-$VERSION.tar.gz "/data/source/"

RUN echo '***** Building Ruby gems' >&2 \
      &&  '/data/packages/rubygems/build.sh' \
            "/data/source/$(basename ${URL})" \
            "/data/build" \
            "${GEMFILE_LOCK}" \
            "${VERSION}" \
            "${CONTACT}"

RUN for F in /data/build/opennebula-rubygem-*.rpm; do \
        _NAME=$(rpm -qp "${F}" --queryformat '%{NAME}\n') \
        _VERS=$(rpm -qp "${F}" --queryformat '%{VERSION}\n') \
        _REL=$(rpm -qp "${F}" --queryformat '%{RELEASE}\n') \

        RUBYGEMS_REQ="${RUBYGEMS_REQ}Requires: ${_NAME} = ${_VERS}-${_REL}"$'\n'; \
    done \
#< <(rpm -qp /data/build/opennebula-rubygem-*.rpm --queryformat '%{NAME} %{VERSION} %{RELEASE}\n') \
&&    cp /data/build/opennebula-rubygem-*.rpm "${BUILD_DIR}"

# Create build package spec based on target OS type
RUN cd "${BUILD_DIR_SPKG}" \
&& _BUILD_COMPONENTS_UC=${BUILD_COMPONENTS^^} \
&& m4 -D_VERSION_="${VERSION}" \
    -D_PKG_VERSION_="${PKG_VERSION}" \
    -D_CONTACT_="${CONTACT}" \
    -D_DATE_="$(date +'%a %b %d %Y')" \
    -D_RUBYGEMS_REQ_="${RUBYGEMS_REQ}" \
    -D_without_oca_java="1" \
    -D_with_oca_java_prebuilt="0" \
    ${_BUILD_COMPONENTS_UC:+ -D_WITH_${_BUILD_COMPONENTS_UC//[[:space:]]/_ -D_WITH_}_} \
    "${DISTRO}.spec.m4" >"${SPEC}" \
&& yum install -y java-11-openjdk-devel python2-wheel python3-devel python3-setuptools python3-wheel systemd-devel 
#&& yum install -y $(cat centos8.spec | grep BuildRequires | awk '{print $2}') \
RUN cd "${BUILD_DIR_SPKG}" \
&& sed -i 's/mv xmlrpc-c ../#mv xmlrpc-c ../g' build_opennebula.sh \
&& mkdir -p ~/rpmbuild/ \
&& rm -rf /root/rpmbuild/SOURCES \
&& rm -rf /root/rpmbuild/RPMS \
&& ln -s /data/source /root/rpmbuild/SOURCES \
&& ln -s /data/build /root/rpmbuild/RPMS
# Deps for Java-based packages are incorrect on CentOS8 so skip
RUN sed -i 's/    %define with_oca_java_prebuilt 1/    %define with_oca_java_prebuilt 0\n    %define with_oca_java 0/g' ${BUILD_DIR_SPKG}/${SPEC}
RUN rpmbuild -ba "${BUILD_DIR_SPKG}/${SPEC}" 
#&& yum install -y $(cat $BUILD_DIR_SPKG/$SPEC | grep BuildRequires | awk '{print $2}')
RUN mkdir -p /data/allrpms && find / -path /proc -prune -o -iname "opennebula*.rpm" -exec mv {} /data/allrpms \;

# === Stage 2 ===
# ------------------------------------------------------------------------------
# Stage 2 - Base image
# ------------------------------------------------------------------------------

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

# === Stage 3 ===
# ------------------------------------------------------------------------------
# Stage 3 - Ruby build
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

# === Stage 4 ===
# ------------------------------------------------------------------------------
# Stage 4 - Ruby base
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

# === Stage 5 ===
# ------------------------------------------------------------------------------
# Stage 5 - Opennebula install
# ------------------------------------------------------------------------------

FROM opennebula-ruby

ARG RUBY_VERSION=25
ENV RUBY_VERSION=${RUBY_VERSION}

RUN yum install -y epel-release
RUN yum install -y 'dnf-command(config-manager)' \
 && yum config-manager --set-enabled PowerTools

# Install opennebula
RUN mkdir -p /allrpms 
COPY --from=builder /data/allrpms/* /allrpms/
RUN yum -y install createrepo && cd /allrpms && createrepo . \ 
&& echo "[opennebula5.10.4]" > /etc/yum.repos.d/opennebula5.10.4.repo \
&& echo "name=opennebula5.10.4" >> /etc/yum.repos.d/opennebula5.10.4.repo \
&& echo "baseurl=file:///allrpms" >> /etc/yum.repos.d/opennebula5.10.4.repo \
&& echo "metadata_expire=-1" >> /etc/yum.repos.d/opennebula5.10.4.repo \
&& echo "gpgcheck=0" >> /etc/yum.repos.d/opennebula5.10.4.repo \
&& echo "enabled=1" >> /etc/yum.repos.d/opennebula5.10.4.repo
RUN yum -y install epel-release && yum -y update && yum -y install opennebula-sunstone \
opennebula-common* opennebula-rubygem-* opennebula-server opennebula-flow opennebula-gate \
opennebula-node-kvm centos-release-openstack-train \
&& yum install -y openvswitch libibverbs

RUN rm /etc/yum.repos.d/opennebula5.10.4.repo \
&& yum -y erase epel-release \
&& yum -y erase createrepo \
&& yum -y erase centos-release-scl \
&& yum -y clean all

 
RUN yum install -y gcc-c++ libcurl-devel libxml2-devel xmlrpc-c-devel openssl-devel \
    ruby-devel mysql-devel sqlite-devel pkgconfig python3-scons sqlite-devel xmlrpc-c \
    make git augeas augeas-libs which m4

RUN ruby --version \
 && gem --version \
 && gem install bundler

RUN gem install rqrcode rotp dalli ipaddress rbvmomi nokogiri sinatra xmlrpc \
ffi ffi-rzmq treetop parse-cron curb

# -------------------------------------------------------------------------------
# Configuration
# -------------------------------------------------------------------------------

COPY docker-entrypoint.sh ./docker-entrypoint.sh
COPY wait-for-it.sh ./wait-for-it.sh
COPY ctrl /ctrl
RUN chmod +x docker-entrypoint.sh && mkdir /var_lib_one && mkdir /conf && cp -au /etc/one /conf/ && mkdir /usr_share_one \
&& cp -rf /usr/share/one/* /usr_share_one/ && mkdir /usr_lib_one && cp -rf /usr/lib/one/* /usr_lib_one/ \
&& cp -rf /var/lib/one/* /var_lib_one/ && cp -rf /var/lib/one/.one /var_lib_one/ && chmod +x wait-for-it.sh \
&& chown -R oneadmin /var_lib_one && chown -R oneadmin /usr_lib_one && chown -R oneadmin /usr_share_one && chown -R oneadmin /conf \
&& chown -R oneadmin /var/lib/one && chown -R oneadmin /etc/one && chmod ugoa+rwx /ctrl/* && chown -R oneadmin:oneadmin /ctrl/

# Logging to /dev/stdout, do not daemonize novnc-server
RUN sed -i 's|^\(SUNSTONE_LOG *=\).*|\1 "/dev/stdout"|' /usr/lib/one/sunstone/sunstone-server.rb \
&& sed -i 's|^\(VNC_LOG *=\).*|\1 "/dev/stdout"|' /usr/bin/novnc-server \
&& sed -i '/cmd *=/a\ exec(cmd)' /usr/lib/one/ruby/OpenNebulaVNC.rb \
&& ln -s /usr/bin/python3 /usr/bin/python \
&& sed -i 's|^\(ONEFLOW_LOG *=\).*|\1 "/dev/stdout"|' /usr/lib/one/oneflow/oneflow-server.rb \
&& sed -i 's|^\(ONEGATE_LOG *=\).*|\1 "/dev/stdout"|' /usr/lib/one/onegate/onegate-server.rb

RUN cp -au /etc/libvirt /conf \
&& chmod +x /docker-entrypoint.sh \
&& echo "devpts /dev/pts devpts gid=5,mode=620 0 0" > /etc/fstab

EXPOSE 9869 5030 2474 29876 5900-6100 16509 2633
USER oneadmin

VOLUME ["/var/lib/libvirt"]

#ENTRYPOINT [ "/bin/bash" ]
ENTRYPOINT ["./docker-entrypoint.sh"]

