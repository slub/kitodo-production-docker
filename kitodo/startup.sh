#!/bin/bash
SSH_PRIVATE_KEY=/id_rsa
if [ -f "$SSH_PRIVATE_KEY" ]; then
	cat $SSH_PRIVATE_KEY >> /.ssh/id_rsa
fi

# removes read/write/execute permissions from group and others, but preserves whatever permissions the owner had
chmod go-rwx /.ssh/*

# Add ocrd manager as global and known_hosts if env exist
if [ -n "$OCRD_MANAGER" ]; then
    OCRD_MANAGER_HOST=${OCRD_MANAGER%:*}
    OCRD_MANAGER_PORT=${OCRD_MANAGER#*:}
	OCRD_MANAGER_IP=$(nslookup $OCRD_MANAGER_HOST | grep 'Address\:' | awk 'NR==2 {print $2}')

    if test -e /etc/ssh/ssh_known_hosts; then
        ssh-keygen -R $OCRD_MANAGER_HOST -f /etc/ssh/ssh_known_hosts
		ssh-keygen -R $OCRD_MANAGER_IP -f /etc/ssh/ssh_known_hosts
    fi
    ssh-keyscan -H -p ${OCRD_MANAGER_PORT:-22} $OCRD_MANAGER_HOST,$OCRD_MANAGER_IP >> /etc/ssh/ssh_known_hosts
fi


# Replace imklog to prevent starting problems of rsyslog
/bin/sed -i '/imklog/s/^/#/' /etc/rsyslog.conf

# Add tomcat logging to syslog on line 23
/bin/sed -i '23i module(load="imfile" PollingInterval="10")' /etc/rsyslog.conf

echo "Starting rsyslog."
service rsyslog start

echo "Wait for database container."
/tmp/wait-for-it.sh -t 0 ${KITODO_DB_HOST}:${KITODO_DB_PORT}

echo "Initalize database."

if [ ! -f "/tmp/kitodo/kitodo_all_files.sql" ]; then
	cat /tmp/kitodo/kitodo.sql /tmp/kitodo/overwrites/sql/kitodo_post_init.sql > /tmp/kitodo/kitodo_all_files.sql

	EXITS_QUERY_RESULT=$(echo "SELECT 1 FROM user LIMIT 1" | mysql -h "${KITODO_DB_HOST}" -P "${KITODO_DB_PORT}" -u ${KITODO_DB_USER} --password=${KITODO_DB_PASSWORD} ${KITODO_DB_NAME} -N)

  if [ "$EXITS_QUERY_RESULT" -eq "1" ]; then
      # run only kitodo_post_init.sql if database and tables already exist
      mysql -h "${KITODO_DB_HOST}" -P "${KITODO_DB_PORT}" -u ${KITODO_DB_USER} --password=${KITODO_DB_PASSWORD} ${KITODO_DB_NAME} < /tmp/kitodo/overwrites/sql/kitodo_post_init.sql
  else
      mysql -h "${KITODO_DB_HOST}" -P "${KITODO_DB_PORT}" -u ${KITODO_DB_USER} --password=${KITODO_DB_PASSWORD} ${KITODO_DB_NAME} < /tmp/kitodo/kitodo_all_files.sql
  fi

fi

if [ -z "$(ls -A /usr/local/kitodo)" ]; then
   cp -r /tmp/kitodo/kitodo-config-modules/* /usr/local/kitodo/
   cp -r /tmp/kitodo/overwrites/data/* /usr/local/kitodo/
fi

/usr/bin/deploy.sh #deploy and start

tail -f /var/log/syslog
