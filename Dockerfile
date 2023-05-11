ARG BUILDER_TYPE=release

# Kitodo.Production Release Local
FROM alpine:latest AS kitodo-builder-local

RUN apk update

ARG BUILDER_LOCAL_WAR=build-resources/kitodo.war
ARG BUILDER_LOCAL_SQL=build-resources/kitodo.sql
ARG BUILDER_LOCAL_CONFIG_MODULES_ZIP=build-resources/kitodo-config-modules.zip

COPY ${BUILDER_LOCAL_WAR} /data/kitodo.war
COPY ${BUILDER_LOCAL_SQL} /data/kitodo.sql
COPY ${BUILDER_LOCAL_CONFIG_MODULES_ZIP} /data/kitodo-config-modules.zip


# Kitodo.Production Release Builder
FROM alpine:latest AS kitodo-builder-release

RUN apk update && \
	apk --no-cache add curl

ARG BUILDER_RELEASE_VERSION=3.5.0
ARG BUILDER_RELEASE_WAR=kitodo-3.5.0.war
ARG BUILDER_RELEASE_SQL=kitodo_3-5-0.sql
ARG BUILDER_RELEASE_CONFIG_MODULES_ZIP=kitodo_3-5-0_config_modules.zip

COPY build-release.sh build.sh

RUN mkdir /data/ && \
	chmod +x /build.sh && \
	sh build.sh


# Kitodo.Production Git Builder
FROM maven:3.8.5-openjdk-11 AS kitodo-builder-git

RUN apt-get update && \
	apt-get install -y \
	zip \
	unzip \
	mariadb-server \
	wget
	
ARG BUILDER_GIT_COMMIT=master
ARG BUILDER_GIT_SOURCE_URL=https://github.com/kitodo/kitodo-production/

ENV JAVA_OPTS="-Djava.awt.headless=true -XX:+UseConcMarkSweepGC -Xmx2048m -Xms1024m -XX:MaxPermSize=512m"

COPY wait-for-it.sh /wait-for-it.sh
COPY build-git.sh /build.sh

RUN mkdir /data/ && \
	chmod +x /build.sh && \
	chmod +x /wait-for-it.sh && \
	sh build.sh


# Kitodo Builder - alias for builder type cause COPY --from does not allow build arguments
FROM kitodo-builder-${BUILDER_TYPE} AS kitodo-builder


# Kitodo.Production
FROM tomcat:9.0.62-jre11-openjdk-slim AS kitodo

MAINTAINER markus.weigelt@slub-dresden.de

ARG GH_REF
ARG GH_REPOSITORY
ARG BUILD_DATE

LABEL \
    maintainer="https://slub-dresden.de" \
    org.label-schema.vendor="Saxon State and University Library Dresden" \
    org.label-schema.name="Kitodo.Production" \
    org.label-schema.vcs-ref=$GH_REF \
    org.label-schema.vcs-url="https://github.com/${GH_REPOSITORY}/" \
    org.label-schema.build-date=$BUILD_DATE \
    org.opencontainers.image.vendor="Saxon State and University Library Dresden" \
    org.opencontainers.image.title="Kitodo.Production" \
    org.opencontainers.image.description="Kitodo.Production is the workflow management module in the Kitodo suite." \
    org.opencontainers.image.source="https://github.com/${GH_REPOSITORY}/" \
    org.opencontainers.image.documentation="https://github.com/${GH_REPOSITORY}/blob/${GH_REF}/README.md" \
    org.opencontainers.image.revision=$GH_REF \
    org.opencontainers.image.created=$BUILD_DATE

ENV JAVA_OPTS="-Djava.awt.headless=true -XX:+UseConcMarkSweepGC -Xmx2048m -Xms1024m -XX:MaxPermSize=512m"
ENV JPDA=false
ENV JPDA_ADDRESS=*:5005

ENV DB_HOST=localhost
ENV DB_PORT=3306
ENV DB_NAME=kitodo
ENV DB_USER=kitodo
ENV DB_PASSWORD=kitodo
ENV ES_HOST=localhost
ENV MQ_HOST=localhost
ENV MQ_PORT=61616

# make apt run non-interactive during build
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && \
    apt-get install -y \
	apt-utils \
	net-tools \
	nano \
	unzip \
	procps \
	dnsutils \
	mariadb-client \
	openssh-client \
	imagemagick \
	rsyslog \
	--no-install-recommends

# copy build resources of kitodo-builder stage
COPY --from=kitodo-builder /data /tmp/kitodo

COPY tomcat.conf /etc/rsyslog.d/
COPY startup.sh /usr/bin/
COPY deploy.sh /usr/bin/
COPY wait-for-it.sh /wait-for-it.sh

# system configs
RUN mkdir /.ssh && \
    cat > /etc/ssh/ssh_known_hosts && \
    cat > /usr/bin/before_startup.sh && \
    chmod +x /usr/bin/before_startup.sh && \
    chmod +x /usr/bin/startup.sh && \
    chmod +x /usr/bin/deploy.sh && \
    chmod +x /wait-for-it.sh

# application configs
RUN unzip /tmp/kitodo/kitodo-config-modules.zip -x *.bat -d /tmp/kitodo/kitodo-config-modules-unzipped && \
    chmod -R go+w /tmp/kitodo/kitodo-config-modules-unzipped && \
    mkdir -p /tmp/kitodo/kitodo-config-modules /tmp/kitodo/overwrites/data /tmp/kitodo/overwrites/config /tmp/kitodo/overwrites/sql && \
    touch /tmp/kitodo/overwrites/sql/post_init.sql && \
    mv /tmp/kitodo/kitodo-config-modules-unzipped/*/* /tmp/kitodo/kitodo-config-modules/ && \
    chmod 544 /tmp/kitodo/kitodo-config-modules/scripts/*.sh && \
    rm /tmp/kitodo/kitodo-config-modules.zip && \
    rm -fr /tmp/kitodo/kitodo-config-modules-unzipped

CMD ["/bin/bash", "-c", "/usr/bin/before_startup.sh && /usr/bin/startup.sh"]

EXPOSE 8080

# make apt run interactive during logins
ENV DEBIAN_FRONTEND teletype
