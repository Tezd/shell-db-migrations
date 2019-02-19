#!/usr/bin/env sh

ADAPTER_VERSION=1.0.0
CLICKHOUSE_BIN=clickhouse
CLICKHOUSE_PATH=${CLICKHOUSE_PATH:-$(which ${CLICKHOUSE_BIN})}
CONNECT_TIMEOUT=${CONNECT_TIMEOUT:-25}
USER=
PASS=
PORT=
DB=
HOST=
CLICKHOUSE_CONNECTION=

adapterUsage()
{
	printf "
  -u, --username    Username
  -p, --password    User password
  -P, --port        Database port(default: 9000)
  -h, --host        Database host(default: 127.0.0.1)
  -d, --database    Database name(default: default)"
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
	return 0
}

checkTools()
{
	broken=0
	if [ -z "${CLICKHOUSE_PATH}" ]
	then
		echo >&2 "No path to [${CLICKHOUSE_PATH}] was provided and wasnt able to locate it using which"
		echo >&2 "You can provide custom path by prepending [CLICKHOUSE_PATH] before command"
		echo >&2 "Ex: CLICKHOUSE_PATH=my/path/${CLICKHOUSE_PATH}  <script>"
		broken=1
	fi

	return ${broken}
}

prepareConnection()
{
	HOST=${HOST:-127.0.0.1}
	PORT=${PORT:-9000}
	DB=${DB:-default}
	CLICKHOUSE_CONNECTION="${CLICKHOUSE_BIN} client -d${DB} -h${HOST} --port=${PORT}${USER:+ -u${USER}}${PASS:+ --password=${PASS}}"
}

checkConnection()
{
	${CLICKHOUSE_CONNECTION} --connect_timeout ${CONNECT_TIMEOUT} --query "SELECT 1;" 1>/dev/null
	return=$?
	if [ ${return} -ne 0 ]
	then
		echo >&2 "Connection failed"
	fi
	return ${return}
}

ensureMigrationTableExists()
{
	${CLICKHOUSE_CONNECTION} --query "CREATE TABLE IF NOT EXISTS migration
	(id UInt64, date DateTime) Engine=MergeTree PARTITION BY toYYYYMM(date) ORDER BY (id, date)"
}

getVersions()
{
	${CLICKHOUSE_CONNECTION} --query "SELECT id FROM migration ORDER BY id ${1}"
}

addVersion()
{
	${CLICKHOUSE_CONNECTION} --query "INSERT INTO migration VALUES($1, now())"
}

removeVersion()
{
	${CLICKHOUSE_CONNECTION} --query "ALTER TABLE migration DELETE WHERE id = $1"
}

show()
{
	cat $1 | grep -v '#' | grep -v -e '^$' | sed \
	-e "s/\${CLICKHOUSE_CONNECTION}/${CLICKHOUSE_CONNECTION}/g"
}

