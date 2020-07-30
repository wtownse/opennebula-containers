# ------------------------------------------------------------------------------

# Common Stage 1
# ------------------------------------------------------------------------------

# === Stage 1 ===

FROM centos:8 as builder

ARG RUBY_VERSION=25

ARG RUBY_VERSION=25

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

##FROM drecom/centos-ruby

FROM centos:8

ARG RUBY_VERSION=25
ENV RUBY_VERSION=${RUBY_VERSION}

# ------------------------------------------------------------------------------
# Specific part
# ------------------------------------------------------------------------------


RUN yum install -y epel-release
RUN yum install -y 'dnf-command(config-manager)' \
 && yum config-manager --set-enabled PowerTools

# Install opennebula-sunstone
RUN mkdir -p /allrpms 
#&& cp -r /data/allrpms/* /allrpms/
COPY --from=builder /data/allrpms/* /allrpms/
RUN yum -y install createrepo && cd /allrpms && createrepo . \ 
&& echo "[opennebula5.10.4]" > /etc/yum.repos.d/opennebula5.10.4.repo \
&& echo "name=opennebula5.10.4" >> /etc/yum.repos.d/opennebula5.10.4.repo \
&& echo "baseurl=file:///allrpms" >> /etc/yum.repos.d/opennebula5.10.4.repo \
&& echo "metadata_expire=-1" >> /etc/yum.repos.d/opennebula5.10.4.repo \
&& echo "gpgcheck=0" >> /etc/yum.repos.d/opennebula5.10.4.repo \
&& echo "enabled=1" >> /etc/yum.repos.d/opennebula5.10.4.repo
RUN yum -y install epel-release && yum -y update && yum -y install opennebula-sunstone \
opennebula-common* opennebula-rubygem-* \
&& yum -y install opennebula-rubygem* \
#&& rm -rf /allrpms && rm /etc/yum.repos.d/opennebula5.10.4.repo \
&& rm -rf /allrpms && yum -y erase epel-release
#&& yum -y erase createrepo && yum -y clean all

 
RUN yum install -y gcc-c++ libcurl-devel libxml2-devel xmlrpc-c-devel openssl-devel \
    mysql-devel sqlite-devel pkgconfig python3-scons sqlite-devel xmlrpc-c \
    make npm git augeas augeas-libs which m4 ruby ruby-devel rpm-build zlib-devel

RUN ruby --version \
 && gem --version \
 && gem install bundler

RUN gem install rqrcode rotp dalli ipaddress rbvmomi nokogiri sinatra

RUN rm /etc/yum.repos.d/opennebula5.10.4.repo \
 && yum -y erase epel-release \
 && yum -y erase centos-release-scl \
 && yum -y erase createrepo \
 && yum -y clean all

RUN yum autoremove -y libcurl-devel libxml2-devel xmlrpc-c-devel openssl-devel \
    mysql-devel sqlite-devel sqlite-devel \
    make npm git which m4 ruby-devel

# -------------------------------------------------------------------------------
# Configuration
# -------------------------------------------------------------------------------
RUN mkdir /var/lib/one/.one
COPY create-conf.sh ./create-conf.sh
COPY docker-entrypoint.sh ./docker-entrypoint.sh
COPY wait-for-it.sh ./wait-for-it.sh
COPY sunstone.sh ./sunstone.sh
RUN chmod +x docker-entrypoint.sh && mkdir /init && mkdir /conf && cp -rf /etc/one/* /conf/ && mkdir /share && cp -rf /usr/share/one/* /share \
&& cp -rf /var/lib/one /init/ && cp -rf /var/lib/one/.one /init/one/ && chmod +x wait-for-it.sh && chmod +x sunstone.sh \
&& chown -R oneadmin /init && chown -R oneadmin /conf \
&& chown -R oneadmin /var/lib/one && chown -R oneadmin /etc/one

# Logging to /dev/stdout, do not daemonize novnc-server
RUN sed -i 's|^\(SUNSTONE_LOG *=\).*|\1 "/dev/stdout"|' /usr/lib/one/sunstone/sunstone-server.rb \
&& sed -i 's|^\(VNC_LOG *=\).*|\1 "/dev/stdout"|' /usr/bin/novnc-server \
&& sed -i '/cmd *=/a\ exec(cmd)' /usr/lib/one/ruby/OpenNebulaVNC.rb
EXPOSE 9869
EXPOSE 29876
#ENTRYPOINT [ "/bin/bash" ]
USER oneadmin
ENTRYPOINT ["./docker-entrypoint.sh"]

