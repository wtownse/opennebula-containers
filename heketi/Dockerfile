# set author and base
FROM fedora
MAINTAINER Heketi Developers <heketi-devel@gluster.org>

LABEL version="1.3.1"
LABEL description="Development build"

# let's setup all the necessary environment variables
ENV BUILD_HOME=/build
ENV GOPATH=$BUILD_HOME/golang
ENV PATH=$GOPATH/bin:$PATH
# where to clone from
ENV HEKETI_REPO="https://github.com/heketi/heketi.git"
ENV HEKETI_BRANCH="master"
ENV HEKETI_TAG="v10.0.0"

# install optional CA certs
RUN mkdir -p  /etc/pki/ca-trust/source/anchors/
RUN update-ca-trust enable
COPY anchors/* /etc/pki/ca-trust/source/anchors/
RUN update-ca-trust extract

# install dependencies, build and cleanup
RUN mkdir $BUILD_HOME $GOPATH && \
    dnf -y install glide golang git make mercurial findutils && \
    dnf -y clean all && \
    mkdir -p $GOPATH/src/github.com/heketi && \
    cd $GOPATH/src/github.com/heketi && \
    git clone $HEKETI_REPO -b $HEKETI_BRANCH && \
    cd $GOPATH/src/github.com/heketi/heketi && \
    glide install -v && \
    make && \
    mkdir -p /etc/heketi /var/lib/heketi && \
    make install prefix=/usr && \
    cp /usr/share/heketi/container/heketi-start.sh /usr/bin/heketi-start.sh && \
    cp /usr/share/heketi/container/heketi.json /etc/heketi/heketi.json && \
    glide cc && \
    cd && rm -rf $BUILD_HOME && \
    dnf -y remove git glide golang mercurial && \
    dnf -y autoremove && \
    dnf -y clean all && \
    mkdir -p /conforig && \
    cp /usr/share/heketi/container/heketi.json /conforig/heketi.json

VOLUME /etc/heketi /var/lib/heketi
COPY docker-entrypoint.sh ./docker-entrypoint.sh
RUN chmod +x ./docker-entrypoint.sh

# expose port, set user and set entrypoint with config option
ENTRYPOINT ["./docker-entrypoint.sh"]
#ENTRYPOINT ["/usr/bin/heketi-start.sh"]
EXPOSE 8080
