#!/usr/bin/env sh

ADAPTER_VERSION=1.0.2
MYSQL_BIN=mysql
MYSQL_PATH=${MYSQL_PATH:-$(which ${MYSQL_BIN})}
CONNECT_TIMEOUT=${CONNECT_TIMEOUT:-25}
USER=
PASS=
PORT=
DB=
HOST=
SOCKET=
MYSQL_CONNECTION=

adapterUsage()
{
	printf "
  -u, --username    Username
  -p, --password    User password
  -P, --port        Database port(default: 3306)
  -h, --host        Database host(default: 127.0.0.1)
  -d, --database    Database name(required)
  -s, --socket      Socket file to use for connection"
}

parseAdapterOptions()
{
	case $1 in
		-u|--username) shift; USER=$1;;
		-p|--password) shift; PASS=$1;;
		-P|--port) shift; PORT=$1;;
		-h|--host) shift; HOST=$1;;
		-d|--database) shift; DB=$1;;
		-s|--socket) shift; SOCKET=$1;;
	esac
}

validateOptions()
{
	if [ -z "${DB}" ]
	then
		echo >&2 "Database name should be provided by adding -d or --database"
		return 1
	fi
}

checkTools()
{
	broken=0
	if [ -z "${MYSQL_PATH}" ]
	then
		echo >&2 "No path to [${MYSQL_BIN}] was provided and wasnt able to locate it using which"
		echo >&2 "You can provide custom path by prepending [MYSQL_PATH] before command"
		echo >&2 "Ex: MYSQL_PATH=my/path/${MYSQL_BIN} <script>"
		broken=1
	fi

	return ${broken}
}

prepareConnection()
{
	if [ -z "${SOCKET}" ]; then
		tcpConnection
	else
		socketConnection
	fi
}

socketConnection()
{
	MYSQL_CONNECTION="${MYSQL_BIN} -D${DB} -S${SOCKET} --protocol=socket${USER:+ -u${USER}}${PASS:+ -p${PASS}}"
}

tcpConnection()
{
	HOST=${HOST:-127.0.0.1}
	PORT=${PORT:-3306}
	MYSQL_CONNECTION="${MYSQL_BIN} -D${DB} -h${HOST} -P${PORT}${USER:+ -u${USER}}${PASS:+ -p${PASS}}"
}

checkConnection()
{
	${MYSQL_CONNECTION} --connect-timeout=${CONNECT_TIMEOUT} -e "SELECT 1;" 1>/dev/null
	return=$?
	if [ ${return} -ne 0 ]
	then
		echo >&2 "Connection failed"
	fi
	return ${return}
}

ensureMigrationTableExists()
{
	${MYSQL_CONNECTION} -e "CREATE TABLE IF NOT EXISTS migration
	(id BIGINT UNSIGNED NOT NULL PRIMARY KEY, date DateTime NOT NULL) ENGINE=InnoDB"
}

getVersions()
{
	${MYSQL_CONNECTION} -N -e "SELECT id FROM migration ORDER BY id ${1}"
}

addVersion()
{
	${MYSQL_CONNECTION} -e "INSERT INTO migration VALUES($1, now())"
}

removeVersion()
{
	${MYSQL_CONNECTION} -e "DELETE FROM migration WHERE id = $1"
}

show()
{
	cat $1 | grep -v '#' | grep -v -e '^$' | sed \
	-e "s/\${MYSQL_CONNECTION}/${MYSQL_CONNECTION}/g"
}

