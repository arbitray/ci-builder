FROM ubuntu:22.10

#---- base
# utils
RUN apt update && \
  apt install -y --no-install-recommends \
    unzip bash which make wget zip bzip2 gcc g++ curl libcurl4-gnutls-dev autoconf libexpat1-dev openssl perl zip openjdk-8-jdk openjdk-11-jdk git jq

RUN wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq && \
    chmod +x /usr/bin/yq

# Set the locale(en_US.UTF-8)
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

#---- jenkins
RUN mkdir /home/jenkins
# # USER jenkins
WORKDIR /home/jenkins
# ENV SONAR_SCANNER_VERSION 3.3.0.1492
# RUN curl -o sonar_scanner.zip https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}-linux.zip && \
#     unzip -q sonar_scanner.zip && rm sonar_scanner.zip \
#     && rm -rf sonar-scanner-$SONAR_SCANNER_VERSION-linux/jre && \
#     sed -i 's/use_embedded_jre=true/use_embedded_jre=false/g' /home/jenkins/sonar-scanner-$SONAR_SCANNER_VERSION-linux/bin/sonar-scanner && \
#     mv /home/jenkins/sonar-scanner-$SONAR_SCANNER_VERSION-linux /usr/bin
# ENV PATH $PATH:/usr/bin/sonar-scanner-$SONAR_SCANNER_VERSION-linux/bin
COPY ./ ./
RUN chmod +x ./hack/*.sh && ./hack/base_install_utils.sh

#---- dotnet
# RUN curl -vskS https://dot.net/v1/dotnet-install.sh > /root/dotnet-install.sh && chmod +x /root/dotnet-install.sh
# RUN bash --verbose /root/dotnet-install.sh -c 5.0
# RUN bash --verbose /root/dotnet-install.sh -c 3.1
# ENV PATH $PATH:/root/.nuget/tools:/root/.dotnet/tools:/usr/bin/sonar-scanner-3.3.0.1492-linux/bin

#---- go
RUN apt install -y --no-install-recommends golang
ENV GOLANG_VERSION 1.18.7
ENV PATH $PATH:/usr/local/go/bin
ENV PATH $PATH:/usr/local/
ENV GOROOT /usr/local/go
ENV GOPATH=/home/jenkins/go
ENV PATH $PATH:$GOPATH/bin
COPY ./ ./
# RUN ./hack/go_install_utils.sh
RUN mkdir -p $GOPATH/bin && mkdir -p $GOPATH/src && mkdir -p $GOPATH/pkg

#---- maven

# java
ENV JAVA_VERSIOIN 1.8.0
# maven
ENV MAVEN_VERSION=3.8.6
RUN curl -f -L https://dlcdn.apache.org/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | tar -C /opt -xz
ENV M2_HOME /opt/apache-maven-$MAVEN_VERSION
ENV JAVA_HOME /usr/lib/jvm/java-${JAVA_VERSIOIN}-openjdk
ENV maven.home $M2_HOME
ENV M2 $M2_HOME/bin
ENV PATH $M2:$PATH:$JAVA_HOME/bin

# ant
ENV ANT_VERSION 1.10.12
RUN curl -f -L https://dlcdn.apache.org/ant/binaries/apache-ant-${ANT_VERSION}-bin.tar.gz|tar -C /opt/ -xz && \
  mv /opt/apache-ant-${ANT_VERSION} /opt/ant
ENV ANT_HOME /opt/ant
ENV PATH ${PATH}:/opt/ant/bin

# Set JDK to be 32bit
COPY usejava /usr/bin/
RUN chmod +x /usr/bin/usejava && /usr/bin/usejava java-${JAVA_VERSIOIN}-openjdk

#---- nodejs
ENV NODE_VERSION 16.14.2-r0

RUN ARCH= && uArch="$(uname -m)" && apt install -y --no-install-recommends gpg gpg-agent gnupg2 \
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
    gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$key"; \
  done \
  && apt install -y --no-install-recommends nodejs \
  && apt install -y --no-install-recommends npm \
  && apt install -y --no-install-recommends chromium-chromedriver chromium-browser \
  && npm i -g watch-cli vsce typescript --unsafe

# Yarn
ENV YARN_VERSION 1.22.17-r0
RUN npm i -g yarn && yarn config set cache-folder /root/.yarn

#---- python
# python3
ENV PYTHON_VERSION=3.7.11
RUN apt install -y --no-install-recommends libbz2-dev libzip-dev libffi-dev libsqlite-dev && \
  wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz && \
  mkdir -p /usr/src && \
  tar xvzf Python-${PYTHON_VERSION}.tgz -C /usr/src/ --no-same-owner && \
  cd /usr/src/Python-${PYTHON_VERSION} && \
  ./configure --enable-optimizations --with-ensurepip=install --enable-loadable-sqlite-extensions && \
  make altinstall -j 2 && \
  cd ../ && \
  rm -rf /usr/src/Python-${PYTHON_VERSION}.tgz /usr/src/Python-${PYTHON_VERSION} && \
  ln -fs /usr/local/bin/python3.7 /usr/bin/python && \
  ln -fs /usr/local/bin/python3.7 /usr/bin/python3 && \
  ln -fs /usr/local/bin/pip3.7 /usr/bin/pip && \
  python3 -m pip install --upgrade pip
