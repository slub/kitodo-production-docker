#!/bin/bash

echo "Kill tomcat"
pkill -f catalina 

echo "Remove existing tomcat Kitodo webapp"
rm -rf $CATALINA_HOME/webapps/kitodo

echo "Deploy war to tomcat Kitodo webapp"
unzip -o -qq /tmp/kitodo/kitodo.war -d $CATALINA_HOME/webapps/kitodo

HIBERNATE_CONFIG=$CATALINA_HOME/webapps/kitodo/WEB-INF/classes/hibernate.cfg.xml
KITODO_CONFIG=$CATALINA_HOME/webapps/kitodo/WEB-INF/classes/kitodo_config.properties

echo "Wait for until unpacking is finished"
until [ -f $HIBERNATE_CONFIG -a -f $KITODO_CONFIG ]
do
     sleep 2
done

if [ "$(ls -A /tmp/kitodo/overwrites/config)" ]; then
  echo "Overwrite /usr/local/tomcat/webapps/kitodo/WEB-INF/classes/ with data of /tmp/kitodo/overwrites/config."
  cp -pr /tmp/kitodo/overwrites/config/* /usr/local/tomcat/webapps/kitodo/WEB-INF/classes/
fi

echo "Replace database config parameters with environment variables"
/bin/sed -i "s,\(jdbc:mysql://\)[^/]*\(/.*\),\1${DB_HOST}:${DB_PORT}\2," $HIBERNATE_CONFIG
/bin/sed -i "s/kitodo?useSSL=false/${DB_NAME}?useSSL=false\&amp;allowPublicKeyRetrieval=true\&amp;serverTimezone=UTC/g" $HIBERNATE_CONFIG
/bin/sed -i "s/hibernate.connection.username\">kitodo/hibernate.connection.username\">${DB_USER}/g" $HIBERNATE_CONFIG
/bin/sed -i "s/hibernate.connection.password\">kitodo/hibernate.connection.password\">${DB_PASSWORD}/g" $HIBERNATE_CONFIG

echo "Replace elasticsearch config parameters with environment variables"
/bin/sed -i "s,^\(elasticsearch.host\)=.*,\1=${ES_HOST}," $KITODO_CONFIG

echo "Replace activemq config parameters with environment variables"
/bin/sed -i "s/localhost:61616/${MQ_HOST}:${MQ_PORT}/g" $KITODO_CONFIG
/bin/sed -i "s/#activeMQ.hostURL=/activeMQ.hostURL=/g" $KITODO_CONFIG
/bin/sed -i "s/#activeMQ.results.topic=/activeMQ.results.topic=/g" $KITODO_CONFIG
/bin/sed -i "s/#activeMQ.results.timeToLive=/activeMQ.results.timeToLive=/g" $KITODO_CONFIG
/bin/sed -i "s/#activeMQ.finalizeStep.queue=/activeMQ.finalizeStep.queue=/g" $KITODO_CONFIG

if $JPDA; then
	echo "Starting tomcat in debug mode"
	/usr/local/tomcat/bin/catalina.sh jpda start 
else
	echo "Starting tomcat"
	/usr/local/tomcat/bin/catalina.sh start 
fi
