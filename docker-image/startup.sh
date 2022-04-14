#!/bin/bash
SSH_PRIVATE_KEY=/id_rsa
if [ -f "$SSH_PRIVATE_KEY" ]; then
	cat $SSH_PRIVATE_KEY >> /.ssh/id_rsa
fi

# removes read/write/execute permissions from group and others, but preserves whatever permissions the owner had
chmod go-rwx /.ssh/*

# Add ocrd manager as global known_hosts if env exist
if [ -n "${OCRD_MANAGER%:*}" ]; then
	ssh-keygen -R ${OCRD_MANAGER%:*} -f /etc/ssh/ssh_known_hosts
	ssh-keyscan -H ${OCRD_MANAGER%:*} >> /etc/ssh/ssh_known_hosts
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
echo "SELECT 1 FROM user LIMIT 1;" \
    | mysql -h "${KITODO_DB_HOST}" -P "${KITODO_DB_PORT}" -u ${KITODO_DB_USER} --password=${KITODO_DB_PASSWORD} ${KITODO_DB_NAME} >/dev/null 2>&1 \
    || mysql -h "${KITODO_DB_HOST}" -P "${KITODO_DB_PORT}" -u ${KITODO_DB_USER} --password=${KITODO_DB_PASSWORD} ${KITODO_DB_NAME} < /tmp/kitodo/kitodo.sql

if [ -z "$(ls -A /usr/local/kitodo)" ]; then
   cp -R /tmp/kitodo/kitodo-config-modules/. /usr/local/kitodo/
fi

/usr/bin/deploy.sh #deploy and start

tail -f /var/log/syslog
