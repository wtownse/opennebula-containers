# ------------------------------------------------------------------------------

# Common Stage 1
# ------------------------------------------------------------------------------

# === Stage 1 ===

FROM centos:7 as builder

ARG RUBY_VERSION=25

# Setup environment variables
ENV VERSION="5.10.4" \
    PKG_VERSION=1 \
    BUILD_DIR="/tmp/build" \
    BUILD_DIR_SPKG="/tmp/spkg" \
    MOCK_DIR_GEMS="/tmp/mobuild" \
    CONTACT="Unsupported Community Build" \
    GIT_VERSION="not known" \
    DISTRO=centos7 \
    GEMFILE_LOCK='CentOS7' \
    URL="opennebula-5.10.4.tar.gz" \
    PKG_VERSION="5.10.4" \
    SPEC="centos7.spec" \
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
RUN yum install -y epel-release centos-release-scl
RUN yum update -y && yum -y erase ruby \
 && yum install -y npm rpm-build gcc-c++ libcurl-devel libxml2-devel xmlrpc-c-devel openssl-devel \
    mysql-devel sqlite-devel openssh pkgconfig scons sqlite-devel xmlrpc-c java-1.7.0-openjdk-devel \
    createrepo wget make npm git augeas augeas-libs which m4 rpmbuild

RUN yum install -y gcc-c++ patch readline readline-devel zlib zlib-devel \   
    libyaml-devel libffi-devel openssl-devel make which \
    bzip2 autoconf automake libtool bison iconv-devel sqlite-devel 

RUN yum -y install rh-ruby${RUBY_VERSION} rh-ruby${RUBY_VERSION}-ruby-devel \
  && yum-config-manager --disable CentOS-SCLo-sc* \
# DISABLE THIS REPO AFTERWARDS AND REINSTATE REMAINDER OF ISNTAL SCRIPT FOR ON below
  && echo "install: --no-document" > /etc/gemrc \
  && echo "source scl_source enable rh-ruby${RUBY_VERSION} " >> /root/.bash_profile 

# Workaround tty check, see https://github.com/hashicorp/vagrant/issues/1673#issuecomment-26650102
RUN sed -i 's/^mesg n/tty -s \&\& mesg n/g' /root/.bash_profile

# Switch to a bash login shell to allow simple 'rvm' in RUN commands
SHELL ["/bin/bash", "-l", "-c"]

# Install Ruby but downgrade 'gem' to 2.x until we move to ON 5.11
RUN ruby --version \
 && gem --version \
 && gem install bundler
# Copy Ruby to overwrite system versions
RUN /usr/bin/cp -rf  /opt/rh/rh-ruby${RUBY_VERSION}/root/* /

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

RUN cd "${BUILD_DIR_SPKG}" \
&& _BUILD_COMPONENTS_UC=${BUILD_COMPONENTS^^} \
&& m4 -D_VERSION_="${VERSION}" \
    -D_PKG_VERSION_="${PKG_VERSION}" \
    -D_CONTACT_="${CONTACT}" \
    -D_DATE_="$(date +'%a %b %d %Y')" \
    -D_RUBYGEMS_REQ_="${RUBYGEMS_REQ}" \
    ${_BUILD_COMPONENTS_UC:+ -D_WITH_${_BUILD_COMPONENTS_UC//[[:space:]]/_ -D_WITH_}_} \
    "${DISTRO}.spec.m4" >"${SPEC}" \
&& yum install -y $(cat centos7.spec | grep BuildRequires | awk '{print $2}') \
&& sed -i 's/mv xmlrpc-c ../#mv xmlrpc-c ../g' build_opennebula.sh \
&& mkdir -p ~/rpmbuild/ \
&& rm -rf /root/rpmbuild/SOURCES \
&& rm -rf /root/rpmbuild/RPMS \
&& ln -s /data/source /root/rpmbuild/SOURCES \
&& ln -s /data/build /root/rpmbuild/RPMS
RUN rpmbuild -ba "${BUILD_DIR_SPKG}/${SPEC}" && yum install -y $(cat $BUILD_DIR_SPKG/$SPEC | grep BuildRequires | awk '{print $2}')
RUN mkdir -p /data/allrpms && find / -iname "opennebula*.rpm" -exec mv {} /data/allrpms \;
# === Stage 2 ===

FROM drecom/centos-ruby
##FROM centos:7

ARG RUBY_VERSION=25
ENV RUBY_VERSION=${RUBY_VERSION}

# ------------------------------------------------------------------------------
# Specific part
# ------------------------------------------------------------------------------

RUN yum install -y epel-release centos-release-scl
RUN yum -y --enablerepo centos-sclo-* install rh-ruby${RUBY_VERSION} rh-ruby${RUBY_VERSION}-ruby-devel \
 && yum-config-manager --disable CentOS-SCLo-sc* 
# Copy Ruby to overwrite system versions
RUN /usr/bin/cp -rf  /opt/rh/rh-ruby${RUBY_VERSION}/root/* /
#RUN ruby --version \
# && gem --version \
# && gem install bundler


# Install opennebula-onegate
RUN mkdir -p /allrpms 
#&& cp -r /data/allrpms/* /allrpms/
COPY --from=builder /data/allrpms/* /allrpms/
RUN yum -y install createrepo && cd /allrpms && createrepo . \ 
&& echo "[opennebula5.10.4]" > /etc/yum.repos.d/opennebula5.10.4.repo \
&& echo "name=opennebula5.10.4" >> /etc/yum.repos.d/opennebula5.10.4.repo \
&& echo "baseurl=file:///allrpms" >> /etc/yum.repos.d/opennebula5.10.4.repo \
&& echo "gpgcheck=0" >> /etc/yum.repos.d/opennebula5.10.4.repo \
&& echo "enabled=1" >> /etc/yum.repos.d/opennebula5.10.4.repo
RUN yum -y install opennebula-gate opennebula-rubygem-*
# opennebula-rubygems opennebula-ruby
#&& rm -rf /allrpms 
RUN rm /etc/yum.repos.d/opennebula5.10.4.repo \
 && yum -y erase epel-release \
 && yum -y erase centos-release-scl \
 && yum -y erase createrepo \
 && yum -y clean all
 
RUN yum install -y gcc-c++ libcurl-devel libxml2-devel xmlrpc-c-devel openssl-devel \
    mysql-devel sqlite-devel pkgconfig scons sqlite-devel xmlrpc-c \
    make npm git augeas augeas-libs which m4 

 # Copy Ruby to overwrite system versions
RUN /usr/bin/cp -rf  /opt/rh/rh-ruby${RUBY_VERSION}/root/* /
RUN gem install sinatra nokogiri treetop parse-cron ipaddress

#RUN yum autoremove -y libcurl-devel libxml2-devel xmlrpc-c-devel openssl-devel \
#    mysql-devel sqlite-devel sqlite-devel \
#    make npm git which m4

# -------------------------------------------------------------------------------
# Configuration
# -------------------------------------------------------------------------------
RUN mkdir /var/lib/one/.one
COPY create-conf.sh ./create-conf.sh
COPY docker-entrypoint.sh ./docker-entrypoint.sh
COPY wait-for-it.sh ./wait-for-it.sh
RUN chmod +x docker-entrypoint.sh && chmod +x wait-for-it.sh

RUN sed -i 's|^\(ONEFLOW_LOG *=\).*|\1 "/dev/stdout"|' /usr/lib/one/onegate/onegate-server.rb
EXPOSE 5030
#USER oneadmin
#ENTRYPOINT ["/bin/bash"]
ENTRYPOINT ["./docker-entrypoint.sh"]

