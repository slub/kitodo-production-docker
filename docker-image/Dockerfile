FROM tomcat:9.0.62-jre11-openjdk-slim 

LABEL maintainer "Markus Weigelt <Markus.Weigelt@slub-dresden.de>"

ARG PROJECT_DIR

RUN if [[ -z "$PROJECT_DIR" ]] ; then echo PROJECT_DIR not provided ; else echo PROJECT_DIR is $PROJECT_DIR ; fi

ENV JAVA_OPTS="-Djava.awt.headless=true -XX:+UseConcMarkSweepGC -Xmx4G -XX:MaxPermSize=256m"
ENV JPDA=false
ENV JPDA_ADDRESS=*:5005

ENV KITODO_DB_HOST=localhost
ENV KITODO_DB_PORT=3306
ENV KITODO_DB_NAME=kitodo
ENV KITODO_DB_USER=kitodo
ENV KITODO_DB_PASSWORD=kitodo
ENV KITODO_ES_HOST=localhost
ENV KITODO_MQ_HOST=localhost
ENV KITODO_MQ_PORT=61616

# make apt run non-interactive during build
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && \
    apt-get install -y \
	apt-utils \
	net-tools \
	nano \
	unzip \ 
	procps \
	dos2unix \
	dnsutils \
	mariadb-client \
	openssh-client \
	imagemagick \
	rsyslog \
	--no-install-recommends

COPY ${PROJECT_DIR}/resources/kitodo.war /tmp/kitodo/kitodo.war
COPY ${PROJECT_DIR}/resources/kitodo-config-modules.zip /tmp/kitodo/kitodo-config-modules.zip
COPY ${PROJECT_DIR}/resources/kitodo.sql /tmp/kitodo/kitodo.sql 

COPY tomcat.conf /etc/rsyslog.d/
COPY startup.sh /usr/bin/
COPY deploy.sh /usr/bin/

RUN mkdir /.ssh && \
	cat > /etc/ssh/ssh_known_hosts && \
	dos2unix /usr/bin/startup.sh && \
	chmod +x /usr/bin/startup.sh && \
	dos2unix /usr/bin/deploy.sh && \
	chmod +x /usr/bin/deploy.sh

ADD https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh /tmp/wait-for-it.sh

RUN	unzip /tmp/kitodo/kitodo-config-modules.zip -x kitodo-config-modules/scripts/*.bat -d /tmp/kitodo/kitodo-config-modules && \
	rm -f /tmp/kitodo/kitodo-config-modules.zip && \
	chmod +x /tmp/wait-for-it.sh && \
	dos2unix /tmp/kitodo/kitodo-config-modules/scripts/*.sh && \
	chmod 544 /tmp/kitodo/kitodo-config-modules/scripts/*.sh

CMD ["/usr/bin/startup.sh"]	

EXPOSE 8080

# make apt run interactive during logins
ENV DEBIAN_FRONTEND teletype
