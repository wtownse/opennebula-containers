#!/bin/bash

if [ "${DISTRO}" = 'centos7' ]; then
    MOCK_CFG='epel-7-x86_64'
    DIST_TAG='el7'
    GEMFILE_LOCK='CentOS7'
elif [ "${DISTRO}" = 'centos8' ]; then
    MOCK_CFG='epel-8-x86_64'
    DIST_TAG='el8'
    GEMFILE_LOCK='CentOS8'
else
    echo "ERROR: Invalid target '${DISTRO}'" >&2
    exit 1
fi
VERSION=5.10.4
URL="opennebula-$VERSION.tar.gz"
PKG_VERSION=$VERSION

SPEC="${DISTRO}.spec"
BUILD_DIR=$(mktemp -d)
BUILD_DIR_SPKG=$(mktemp -d)
MOCK_DIR_GEMS=$(mktemp -d)
PACKAGES_DIR=/packages-$VERSION
SOURCES_DIR="${PACKAGES_DIR}/sources"

SOURCE=$(basename "${URL}")
PACKAGE=opennebula-$VERSION

NAME=$(echo "${PACKAGE}" | cut -d'-' -f1) # opennebula
VERSION=$(echo "${PACKAGE}" |cut -d'-' -f2) # 1.9.90
CONTACT=${CONTACT:-Unsupported Community Build}
BASE_NAME="${NAME}-${VERSION}-${PKG_VERSION}"
GEMS_RELEASE="${VERSION}_${PKG_VERSION}.${DIST_TAG}"
GIT_VERSION=${GIT_VERSION:-not known}
DATE=$(date +'%a %b %d %Y')

cp "${PACKAGES_DIR}/templates/${DISTRO}"/* "${BUILD_DIR_SPKG}"

cd "${BUILD_DIR_SPKG}"

# extra sources
wget -q http://downloads.opennebula.org/extra/xmlrpc-c.tar.gz
cp "${SOURCES_DIR}/build_opennebula.sh" .
cp "${SOURCES_DIR}/xml_parse_huge.patch" .
cp "/$PACKAGE" .
mkdir -p /data
ln -s ${PACKAGES_DIR} /data/packages
ln -s ${BUILD_DIR_SPKG} /data/source
ln -s ${MOCK_DIR_GEMS} /data/build
cd /
tar cvzf /opennebula-$VERSION.tar.gz /opennebula-$VERSION
yes|cp /opennebula-$VERSION.tar.gz "/data/source/"

echo '***** Building Ruby gems' >&2
        '/data/packages/rubygems/build.sh' \
            "/data/source/${SOURCE}" \
            "/data/build" \
            "${GEMFILE_LOCK}" \
            "${VERSION}" \
            "${CONTACT}"

    for F in /data/build/opennebula-rubygem-*.rpm; do
        _NAME=$(rpm -qp "${F}" --queryformat '%{NAME}\n')
        _VERS=$(rpm -qp "${F}" --queryformat '%{VERSION}\n')
        _REL=$(rpm -qp "${F}" --queryformat '%{RELEASE}\n')

        RUBYGEMS_REQ="${RUBYGEMS_REQ}Requires: ${_NAME} = ${_VERS}-${_REL}"$'\n'
    done < <(rpm -qp /data/build/opennebula-rubygem-*.rpm --queryformat '%{NAME} %{VERSION} %{RELEASE}\n')
    cp /data/build/opennebula-rubygem-*.rpm "${BUILD_DIR}"
echo "${RUBYGEMS_REQ}"
#    rm -rf "${MOCK_DIR_GEMS}"
# process template
cd "${BUILD_DIR_SPKG}"
_BUILD_COMPONENTS_UC=${BUILD_COMPONENTS^^}
m4 -D_VERSION_="${VERSION}" \
    -D_PKG_VERSION_="${PKG_VERSION}" \
    -D_CONTACT_="${CONTACT}" \
    -D_DATE_="${DATE}" \
    -D_RUBYGEMS_REQ_="${RUBYGEMS_REQ}" \
    ${_BUILD_COMPONENTS_UC:+ -D_WITH_${_BUILD_COMPONENTS_UC//[[:space:]]/_ -D_WITH_}_} \
    "${DISTRO}.spec.m4" >"${SPEC}"
yum install -y $(cat centos7.spec | grep BuildRequires | awk '{print $2}')
sed -i 's/mv xmlrpc-c ../#mv xmlrpc-c ../g' build_opennebula.sh
rm -rf /root/rpmbuild/SOURCES
rm -rf /root/rpmbuild/RPMS
ln -s /data/source /root/rpmbuild/SOURCES
ln -s /data/build /root/rpmbuild/RPMS
rpmbuild -ba "${SPEC}"
