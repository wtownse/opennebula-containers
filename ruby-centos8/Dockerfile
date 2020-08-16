# CentOS
#
# VERSION               0.0.1

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

FROM base AS rubybuild
ARG RUBY_PATH
ARG RUBY_VERSION
ARG RUBY_CONFIGURE_OPTS
RUN git clone git://github.com/rbenv/ruby-build.git $RUBY_PATH/plugins/ruby-build \
&&  $RUBY_PATH/plugins/ruby-build/install.sh
RUN yum -y install jemalloc-devel
RUN RUBY_CONFIGURE_OPTS=$RUBY_CONFIGURE_OPTS ruby-build $RUBY_VERSION $RUBY_PATH/

FROM centos:8
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

