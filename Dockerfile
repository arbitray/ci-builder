FROM centos:7

# java
ENV JAVA_VERSIOIN 1.8.0

#---- base
# utils
RUN rpm -Uvh https://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/e/epel-release-7-14.noarch.rpm && \
  sed -i "s#enabled=1#enabled=0#g" /etc/yum/pluginconf.d/fastestmirror.conf && \
  yum install -y unzip \
  which \
  make \
  wget \
  zip \
  bzip2 \
  gcc \
  gcc-c++ \
  curl-devel \
  autoconf \
  expat-devel \
  gettext-devel \
  openssl-devel \
  perl-devel \
  zlib-devel \
  python-pip \
  java-${JAVA_VERSIOIN}-openjdk-devel java-${JAVA_VERSIOIN}-openjdk-devel.i686 \
  java-11-openjdk-devel java-11-openjdk-devel.i686

RUN wget --no-check-certificate https://mirrors.kernel.org/pub/software/scm/git/git-2.9.5.tar.gz && \
    tar zxf git-2.9.5.tar.gz --no-same-owner && \
    cd git-2.9.5 && \
    make configure && \
    ./configure prefix=/usr/local/git/ && \
    make && \
    make install && \
    mv /usr/local/git/bin/git /usr/bin/ && \
    cd ..&& \
    rm -rf git-2.9.5.tar.gz git-2.9.5 && \
    git version


# Set the locale(en_US.UTF-8)
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# USER jenkins
WORKDIR /home/jenkins

ENV SONAR_SCANNER_VERSION 3.3.0.1492

RUN curl -o sonar_scanner.zip https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}-linux.zip && \
    unzip sonar_scanner.zip && rm sonar_scanner.zip \
    && rm -rf sonar-scanner-$SONAR_SCANNER_VERSION-linux/jre && \
    sed -i 's/use_embedded_jre=true/use_embedded_jre=false/g' /home/jenkins/sonar-scanner-$SONAR_SCANNER_VERSION-linux/bin/sonar-scanner && \
    mv /home/jenkins/sonar-scanner-$SONAR_SCANNER_VERSION-linux /usr/bin

ENV PATH $PATH:/usr/bin/sonar-scanner-$SONAR_SCANNER_VERSION-linux/bin

COPY ./ ./
RUN chmod +x ./hack/*.sh && ./hack/base_install_utils.sh

#---- dotnet

RUN rpm -Uvh https://packages.microsoft.com/config/centos/7/packages-microsoft-prod.rpm

RUN yum install -y dotnet-sdk-5.0 dotnet-sdk-3.1

RUN dotnet tool install --global dotnet-sonarscanner

ENV PATH $PATH:/root/.nuget/tools:/root/.dotnet/tools:/usr/bin/sonar-scanner-3.3.0.1492-linux/bin

#---- go

RUN yum -y groupinstall 'Development Tools'  && yum -y clean all --enablerepo='*'

ENV GOLANG_VERSION 1.12.10

ENV PATH $PATH:/usr/local/go/bin
ENV PATH $PATH:/usr/local/
ENV GOROOT /usr/local/go
ENV GOPATH=/home/jenkins/go
ENV PATH $PATH:$GOPATH/bin

#COPY ./ ./
RUN ./hack/go_install_utils.sh

RUN mkdir -p $GOPATH/bin && mkdir -p $GOPATH/src && mkdir -p $GOPATH/pkg

#---- maven

# maven
ENV MAVEN_VERSION=3.8.3
RUN curl -f -L https://mirrors.bfsu.edu.cn/apache/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | tar -C /opt -xz
ENV M2_HOME /opt/apache-maven-$MAVEN_VERSION
ENV JAVA_HOME /usr/lib/jvm/java-${JAVA_VERSIOIN}-openjdk
ENV maven.home $M2_HOME
ENV M2 $M2_HOME/bin
ENV PATH $M2:$PATH:$JAVA_HOME/bin

# ant
ENV ANT_VERSION 1.10.11
RUN curl -f -L https://mirrors.bfsu.edu.cn/apache/ant/binaries/apache-ant-${ANT_VERSION}-bin.tar.gz|tar -C /opt/ -xz && \
    mv /opt/apache-ant-${ANT_VERSION} /opt/ant
ENV ANT_HOME /opt/ant
ENV PATH ${PATH}:/opt/ant/bin

# Set JDK to be 32bit
COPY usejava /usr/bin/
RUN chmod +x /usr/bin/usejava && /usr/bin/usejava java-${JAVA_VERSIOIN}-openjdk

#---- nodejs

ENV NODE_VERSION 10.16.3

RUN ARCH= && uArch="$(uname -m)" \
  && case "${uArch##*-}" in \
    x86_64) ARCH='x64';; \
    aarch64) ARCH='arm64';; \
    *) echo "unsupported architecture"; exit 1 ;; \
  esac \
  # gpg keys listed at https://github.com/nodejs/node#release-keys
  && set -ex \
  && for key in \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    77984A986EBC2AA786BC0F66B01FBB92821C587A \
    8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
    4ED778F539E3634C779C87C6D7062848A1AB005C \
    A48C2BEE680E841632CD4E44F07496B3EB3C1762 \
    B9E2F5981AA6E0CD28160D9FF13993A75599653C \
  ; do \
    gpg --batch --keyserver sks.srv.dumain.com --recv-keys "$key"; \
  done \
  && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-$ARCH.tar.xz" \
  && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
  && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
  && grep " node-v$NODE_VERSION-linux-$ARCH.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
  && tar -xJf "node-v$NODE_VERSION-linux-$ARCH.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
  && rm "node-v$NODE_VERSION-linux-$ARCH.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
  && ln -s /usr/local/bin/node /usr/local/bin/nodejs \
  && yum install -y nodejs GConf2 gtk2 chromedriver chromium xorg-x11-server-Xvfb

RUN npm i -g watch-cli vsce typescript

# Yarn
ENV YARN_VERSION 1.16.0
RUN curl -f -L -o /tmp/yarn.tgz https://github.com/yarnpkg/yarn/releases/download/v${YARN_VERSION}/yarn-v${YARN_VERSION}.tar.gz && \
	tar xf /tmp/yarn.tgz && \
	mv yarn-v${YARN_VERSION} /opt/yarn && \
	ln -s /opt/yarn/bin/yarn /usr/local/bin/yarn && \
	yarn config set cache-folder /root/.yarn

#---- python

# python3
ENV PYTHON_VERSION=3.7.11
RUN yum -y install bzip2-devel libffi-devel libsqlite3x-devel && \
    curl -fSL https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz -o /usr/src/Python-${PYTHON_VERSION}.tgz && \
    tar xzf /usr/src/Python-${PYTHON_VERSION}.tgz -C /usr/src/ --no-same-owner && \
    cd /usr/src/Python-${PYTHON_VERSION} && \
    ./configure --enable-optimizations --with-ensurepip=install --enable-loadable-sqlite-extensions && \
    make altinstall -j 2 && \
    cd ../ && \
    rm -rf /usr/src/Python-${PYTHON_VERSION}.tgz /usr/src/Python-${PYTHON_VERSION} && \
    ln -fs /usr/local/bin/python3.7 /usr/bin/python && \
    ln -fs /usr/local/bin/python3.7 /usr/bin/python3 && \
    ln -fs /usr/local/bin/pip3.7 /usr/bin/pip && \
    python3 -m pip install --upgrade pip && \
    sed -e 's|^#!/usr/bin/python|#!/usr/bin/python2.7|g' -i.bak /usr/bin/yum && \
    sed -e 's|^#! /usr/bin/python|#! /usr/bin/python2.7|g' -i.bak /usr/libexec/urlgrabber-ext-down && \
    yum -y remove bzip2-devel libffi-devel libsqlite3x-devel && \
    yum -y clean all

