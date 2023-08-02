#!/bin/bash

set -e

if [ -z "$BUILDER_GIT_REF" ]; then
  if [ -z "$BUILDER_GIT_REPOSITORY" ]; then
    echo "Syntax: docker-compose run kitodo [<BUILDER_GIT_REF>] [<BUILDER_GIT_REPOSITORY>]"
	  echo "Either BUILDER_GIT_REF or BUILDER_GIT_REPOSITORY must be given."
	  echo "Use \"master\" for BUILDER_GIT_REF to get the latest commit."
	  exit 1
  fi
  BUILDER_GIT_REF="master"
fi
if [ -z "$BUILDER_GIT_REPOSITORY" ]; then
  if [ $BUILDER_GIT_REF = "master" ]; then
	  BUILDER_GIT_SOURCE_URL="https://github.com/kitodo/kitodo-production/archive/master.zip"
  else
    BUILDER_GIT_SOURCE_URL="https://github.com/kitodo/kitodo-production/archive/$BUILDER_GIT_REF.zip"
  fi
elif [ `echo "$BUILDER_GIT_SOURCE_URL" | rev | cut -c 1-4` != 'piz.' ]; then
  if [ `echo "$BUILDER_GIT_SOURCE_URL" | rev | cut -c 1-1` != '/' ]; then
    BUILDER_GIT_SOURCE_URL="${BUILDER_GIT_SOURCE_URL}/"
  fi
  BUILDER_GIT_SOURCE_URL="${BUILDER_GIT_SOURCE_URL}archive/$BUILDER_GIT_REF.zip"
fi


echo "Download source files"
echo "using commit $BUILDER_GIT_REF"
echo "using $BUILDER_GIT_SOURCE_URL as download location"

curl $BUILDER_GIT_SOURCE_URL -L -o checkout.zip
unzip -q checkout.zip 

DIR=`ls -1 . | grep kitodo-prod`
if [ -z "$DIR" ]; then
  echo "No Kitodo Production directory found in zip"
  exit 1
fi
echo extracted to $DIR
if [ `echo "$DIR" | rev | cut -c 1-6` != 'retsam' ]; then
  mv $DIR kitodo-production-master
  echo renamed $DIR to kitodo-production-master
fi

echo "Start temporary MariaDB"
/usr/bin/mysqld_safe &

DB_HOST=localhost
DB_NAME=kitodo
DB_USER=kitodo
DB_USER_PASSWORD=kitodo

/wait-for-it.sh -t 0 -h localhost -p 3306

echo "Create database and user"
mysql -u root -e "create database $DB_NAME; create user '$DB_USER'@'$DB_HOST' identified by '$DB_USER_PASSWORD'; grant all on $DB_NAME.* to '$DB_USER'@'$DB_HOST';"

echo "Update Flyway configuration with database settings"
sed -i "s!flyway.url=jdbc:mysql://localhost/kitodo?useSSL=false!flyway.url=jdbc:mysql://$DB_HOST/$DB_NAME?useSSL=false\&allowPublicKeyRetrieval=true!;" kitodo-production-master/Kitodo-DataManagement/src/main/resources/db/config/flyway.properties

echo "Build Kitodo.Production using Maven"
(cd kitodo-production-master/ && mvn clean package -q '-P!development' -DskipTests)
mv kitodo-production-master/Kitodo/target/kitodo-*.war /data/kitodo.war

# Deprecated cause datamanagement use kitodo-api as provided scope in master
# For other no rebased branches it may still be needed
# create a fake repo for kitodo api jar. we need it when generating the sql dump
API_VERSION=`ls kitodo-production-master/Kitodo-API/target/kitodo-api*.jar | xargs basename -s .jar | cut -c 12-` 
mkdir -p maven-fake-repo/org/kitodo/kitodo-api/$API_VERSION
cp kitodo-production-master/Kitodo-API/target/kitodo-api*.jar maven-fake-repo/org/kitodo/kitodo-api/$API_VERSION
# register the repo in the kitodo main pom.xml
MAVEN_URL="file://`pwd`/maven-fake-repo"
REPO_DEF="<repository><id>localfs</id><name>Local System</name><layout>default</layout><url>$MAVEN_URL</url><snapshots><enabled>true</enabled></snapshots></repository>"
sed -i "s!<repositories>!<repositories>$REPO_DEF!;" kitodo-production-master/pom.xml

echo "Create schema and default tables"
cat kitodo-production-master/Kitodo/setup/schema.sql | mysql -u root -D $DB_NAME
cat kitodo-production-master/Kitodo/setup/default.sql | mysql -u root -D $DB_NAME

echo "Migrate database using Flyway"
(cd kitodo-production-master/Kitodo-DataManagement && mvn flyway:baseline -q  -Pflyway && mvn flyway:migrate -q -Pflyway)

echo "Create dump from database"
mysqldump --no-tablespaces -u root $DB_NAME > /data/kitodo.sql

echo "Stop temporary MariaDB"
killall -9 mysqld_safe   

echo "Create config modules zip"
mkdir -p zip/kitodo-config-modules
cd zip/kitodo-config-modules
mkdir -p config debug import logs messages metadata modules plugins plugins/command plugins/import plugins/opac plugins/step plugins/validation rulesets scripts swap temp users xslt diagrams
install -m 444 /kitodo-production-master/Kitodo/src/main/resources/kitodo_*.xml config
install -m 444 /kitodo-production-master/Kitodo/src/main/resources/docket*.xsl xslt
install -m 444 /kitodo-production-master/Kitodo/rulesets/*.xml rulesets
install -m 444 /kitodo-production-master/Kitodo/diagrams/*.xml diagrams
install -m 554 /kitodo-production-master/Kitodo/scripts/*.sh scripts
install -m 444 /kitodo-production-master/Kitodo/modules/*.jar modules
chmod -w config import messages plugins plugins/command plugins/import plugins/opac plugins/step plugins/validation rulesets scripts xslt
(cd /zip && zip -r /data/kitodo-config-modules.zip *)
