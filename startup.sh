#!/bin/bash
SSH_PRIVATE_KEY=/id_rsa
if [ -f "$SSH_PRIVATE_KEY" ]; then
  cat $SSH_PRIVATE_KEY >>/.ssh/id_rsa
fi

# removes read/write/execute permissions from group and others, but preserves whatever permissions the owner had
chmod go-rwx /.ssh/*

# Add ocrd manager as global and known_hosts if env exist
if [ -n "$OCRD_MANAGER" ]; then
  OCRD_MANAGER_HOST=${OCRD_MANAGER%:*}
  OCRD_MANAGER_PORT=${OCRD_MANAGER#*:}
  
  echo "Wait for ocrd manager ssh."
  /wait-for-it.sh -t 0 ${OCRD_MANAGER_HOST}:${OCRD_MANAGER_PORT:-22}
  
  OCRD_MANAGER_IP=$(nslookup $OCRD_MANAGER_HOST | grep 'Address\:' | awk 'NR==2 {print $2}')

  if test -e /etc/ssh/ssh_known_hosts; then
    ssh-keygen -R $OCRD_MANAGER_HOST -f /etc/ssh/ssh_known_hosts
    ssh-keygen -R $OCRD_MANAGER_IP -f /etc/ssh/ssh_known_hosts
  fi

  ssh-keyscan -H -p ${OCRD_MANAGER_PORT:-22} $OCRD_MANAGER_HOST,$OCRD_MANAGER_IP >>/etc/ssh/ssh_known_hosts
fi

# Replace imklog to prevent starting problems of rsyslog
/bin/sed -i '/imklog/s/^/#/' /etc/rsyslog.conf

# Add tomcat logging to syslog on line 23
/bin/sed -i '23i module(load="imfile" PollingInterval="10")' /etc/rsyslog.conf

echo "Starting rsyslog."
service rsyslog start

echo "Wait for external database container."
/wait-for-it.sh -t 0 ${DB_HOST}:${DB_PORT}

ALL_FILES=/tmp/kitodo/all_files.sql
# check if all_files.sh already exist else the initialization process has already been completed
if [ ! -f "$ALL_FILES" ]; then
  echo "Initialisation of environment"
  cat /tmp/kitodo/kitodo.sql /tmp/kitodo/overwrites/sql/post_init.sql > $ALL_FILES

  TBL_QUERY_RESULT=$(echo "SHOW TABLES LIKE 'user'" | mysql -h "${DB_HOST}" -P "${DB_PORT}" -u ${DB_USER} --password=${DB_PASSWORD} ${DB_NAME} -N)

  if [ "$TBL_QUERY_RESULT" != "user" ]; then # check if table already exits
    echo "Initialize database."
    mysql -h "${DB_HOST}" -P "${DB_PORT}" -u ${DB_USER} --password=${DB_PASSWORD} ${DB_NAME} < $ALL_FILES
  elif [ -s /tmp/kitodo/overwrites/sql/post_init.sql ]; then
    echo "Overwrite exiting database with sql file /tmp/kitodo/overwrites/sql/post_init.sql"
    mysql -h "${DB_HOST}" -P "${DB_PORT}" -u ${DB_USER} --password=${DB_PASSWORD} ${DB_NAME} < /tmp/kitodo/overwrites/sql/post_init.sql
  fi

  echo "Initialize config modules directory."
  cp -pr /tmp/kitodo/kitodo-config-modules/* /usr/local/kitodo/

  if [ "$(ls -A /tmp/kitodo/overwrites/data)" ]; then
    echo "Overwrite /usr/local/kitodo/ with data of /tmp/kitodo/overwrites/data."
    cp -pr /tmp/kitodo/overwrites/data/* /usr/local/kitodo/
  fi

else
    echo "Initialisation of environment already completed"
fi

/usr/bin/deploy.sh #deploy and start

tail -f /var/log/syslog
