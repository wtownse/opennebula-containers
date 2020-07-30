# ------------------------------------------------------------------------------
# Common part
# ------------------------------------------------------------------------------

# === Stage 1 ===

FROM centos:7 as builder

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
    GIT_VERSION="${GIT_VERSION:-not known}"
    #DATE=$(date +'%a %b %d %Y')
RUN mkdir -p /tmp/{spkg,build,mobuild}

# Install build dependencies
RUN yum install -y epel-release
RUN yum update -y \
 && yum install -y npm rpm-build gcc-c++ libcurl-devel libxml2-devel xmlrpc-c-devel openssl-devel \
mysql-devel sqlite-devel openssh pkgconfig ruby scons sqlite-devel xmlrpc-c java-1.7.0-openjdk-devel \
ruby-devel createrepo wget make npm git augeas augeas-libs which m4 rpmbuild

# Download sources
COPY packages-release-5.10.4.tar.gz ./packages-release-5.10.4.tar.gz
RUN wget -q -O - "https://github.com/OpenNebula/one/archive/release-$VERSION.tar.gz" | tar -xvzf - \
 && mv /one-release-$VERSION /opennebula-$VERSION \
# && wget -q -O - "https://github.com/OpenNebula/packages/archive/release-$VERSION.tar.gz" | tar -xvzf - \
 && tar xvzf /packages-release-5.10.4.tar.gz && mv /packages-release-5.10.4 /packages-5.10.4 \
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
&& tar cvzf /opennebula-$VERSION.tar.gz /opennebula-$VERSION \
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

# ------------------------------------------------------------------------------
# Specific part
# ------------------------------------------------------------------------------

# Install opennebula-server(oned)
RUN mkdir -p /allrpms
COPY --from=builder /data/allrpms/opennebula-server* \
/data/allrpms/opennebula-5.10.4* \
/data/allrpms/opennebula-common-5.10.4* \
/data/allrpms/opennebula-ruby-5.10.4* /allrpms/
#RUN for F in "$(ls /allrpms/| grep rubygem )" ; do rm /allrpms/$F ; done
#RUN yum -y install createrepo && cd /allrpms && createrepo . \ 
#&& echo "[opennebula5.10.4]" > /etc/yum.repos.d/opennebula5.10.4.repo \
#&& echo "name=opennebula5.10.4" >> /etc/yum.repos.d/opennebula5.10.4.repo \
#&& echo "baseurl=file:///allrpms" >> /etc/yum.repos.d/opennebula5.10.4.repo \
#&& echo "gpgcheck=0" >> /etc/yum.repos.d/opennebula5.10.4.repo \
#&& echo "enabled=1" >> /etc/yum.repos.d/opennebula5.10.4.repo
RUN yum -y install epel-release && yum -y update && yum -y install /allrpms/*.rpm \
#&& rm -rf /allrpms && yum -y erase epel-release \
&& yum -y install centos-release-scl-rh ruby-devel gcc \
&& yum update && yum install -y rh-ruby25-ruby

RUN ["/bin/bash","-c","gem install ffi"]
RUN ["/bin/bash","-c","gem install ffi-rzmq"]
RUN ["/bin/bash","-c","gem install nokogiri"]
#RUN yum -y erase createrepo && yum -y clean all
# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------
COPY create-conf.sh ./create-conf.sh
COPY docker-entrypoint.sh ./docker-entrypoint.sh
COPY oned.conf /etc/one/oned.conf
COPY wait-for-it.sh ./wait-for-it.sh
COPY one.sh ./one.sh
RUN for l in oned sched onehem novnc; do ln -sf "/proc/1/fd/1" "/var/log/one/$l.log"; done
RUN chmod +x docker-entrypoint.sh && chmod +x wait-for-it.sh \
&& chmod +x one.sh && mkdir /conf && mkdir /init \
&& cp -rf /etc/one /conf/ && cp -rf /var/lib/one /init/ && cp -rf /var/lib/one/.one /init/one/ \
&& chown -R oneadmin:oneadmin /init \
&& chown -R oneadmin:oneadmin /var/lib/one \
&& chown -R oneadmin:oneadmin /usr/lib/one \
&& chown -R oneadmin:oneadmin /conf \
&& chown -R oneadmin:oneadmin /etc/one
EXPOSE 2633
USER oneadmin
VOLUME ["/usr/lib/one"]
ENTRYPOINT ["./docker-entrypoint.sh"]
#ENTRYPOINT ["/bin/bash"]
#ENTRYPOINT [ "/usr/lib/one/onehem/onehem-server.rb" ]
