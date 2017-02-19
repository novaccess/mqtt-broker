FROM centos:7.3.1611

MAINTAINER Valentin Delaye <valentin.delaye@novaccess.ch>

# Build arg
ARG version

# Env
ENV version=${version}

RUN yum install -y java-1.8.0-openjdk nc libselinux-python unzip && yum clean all && \
    groupadd -r artemis && useradd -r -g artemis artemis && \
    cd /opt && curl -O --silent http://mirror.switch.ch/mirror/apache/dist/activemq/activemq-artemis/${version}/apache-artemis-${version}-bin.tar.gz && \
	tar xsf apache-artemis-${version}-bin.tar.gz && \
	ln -s apache-artemis-${version} apache-artemis && \
	rm -f apache-artemis-${version}-bin.tar.gz  && \
	cd /var/lib && \
    /opt/apache-artemis-${version}/bin/artemis create artemis \
       --home /opt/apache-artemis \
       --user iot \
       --password iot \
       --role iot \
       --require-login \
       --cluster-user iot \
       --cluster-password iot

# Add config files
ADD bootstrap.xml /var/lib/artemis/etc
ADD logging.properties /var/lib/artemis/etc
ADD broker.xml /var/lib/artemis/etc

# Fix permissions
RUN chown -R artemis.artemis /var/lib/artemis
    
# Volumes
VOLUME ["/var/lib/artemis/data"]
VOLUME ["/var/lib/artemis/tmp"]

WORKDIR /var/lib/artemis/bin

EXPOSE 61616

COPY docker-entrypoint.sh /

HEALTHCHECK CMD (nc localhost 61616 < /dev/null) > /dev/null 2>&1 || exit 1

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["artemis-server"]
