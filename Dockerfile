FROM       centos:centos7
MAINTAINER kramos <markosrendell@gmail.com>

ENV SONATYPE_WORK /sonatype-work
ENV NEXUS_LIFECYCLE_VERSION 1.20.0-02

ENV JAVA_HOME /opt/java
ENV JAVA_VERSION_MAJOR 8
ENV JAVA_VERSION_MINOR 74
ENV JAVA_VERSION_BUILD 02

RUN yum install -y \
  curl tar \
  && yum clean all

# install Oracle JRE
RUN mkdir -p /opt \
  && curl --fail --silent --location --retry 3 \
  --header "Cookie: oraclelicense=accept-securebackup-cookie; " \
  http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-b${JAVA_VERSION_BUILD}/server-jre-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz \
  | gunzip \
  | tar -x -C /opt \
  && ln -s /opt/jdk1.${JAVA_VERSION_MAJOR}.0_${JAVA_VERSION_MINOR} ${JAVA_HOME}

RUN mkdir -p /opt/sonatype/nexus-lifecycle \
  && curl --fail --silent --location --retry 3 \
    http://download.sonatype.com/clm/server/nexus-iq-server-${NEXUS_LIFECYCLE_VERSION}-bundle.tar.gz \
  | gunzip \
  | tar x -C /opt/sonatype/nexus-lifecycle/

RUN useradd -r -u 200 -m -c "nexus role account" -d ${SONATYPE_WORK} -s /bin/false nexus

VOLUME ${SONATYPE_WORK}

EXPOSE 8070

WORKDIR /opt/sonatype/nexus-lifecycle
USER nexus
ENV CONTEXT_PATH /
ENV MAX_PERM_SIZE 128m
ENV JAVA_OPTS -server -Djava.net.preferIPv4Stack=true
ENV LAUNCHER_CONF ./conf/jetty.xml ./conf/jetty-requestlog.xml
CMD ${JAVA_HOME}/bin/java \
  -XX:MaxPermSize=${MAX_PERM_SIZE} \
  -jar  nexus-iq-server-${NEXUS_LIFECYCLE_VERSION}.jar \
  server \
  config.yml
