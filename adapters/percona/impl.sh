#!/usr/bin/env sh

ADAPTER_VERSION=1.1.1
PERCONA_BIN=pt-online-schema-change
PERCONA_PATH=${PERCONA_PATH:-$(which ${PERCONA_BIN})}
PERCONA_CONNECTION=

alias checkTools=mysqlCheckTools
alias socketConnection=mysqlSocketConnection
alias tcpConnection=mysqlTcpConnection
alias show=mysqlShow

. ${BASE_DIR}/adapters/mysql/impl.sh

unalias checkTools
unalias socketConnection
unalias tcpConnection
unalias show

checkTools()
{
	mysqlCheckTools
	broken=$?
	if [ -z "${PERCONA_PATH}" ]
	then
		echo >&2 "No path to [${PERCONA_BIN}] was provided and wasnt able to locate it using which"
		echo >&2 "You can provide custom path by prepending [PERCONA_PATH] before command"
		echo >&2 "Ex: PERCONA_PATH=my/path/${PERCONA_BIN} <script>"
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
	mysqlSocketConnection
	PERCONA_CONNECTION="${PERCONA_BIN} D=${DB},S=${SOCKET}${USER:+,u=${USER}}${PASS:+,p=${PASS}}"
}

tcpConnection()
{
	mysqlTcpConnection
	PERCONA_CONNECTION="${PERCONA_BIN} D=${DB},h=${HOST},P=${PORT}${USER:+,u=${USER}}${PASS:+,p=${PASS}}"
}

show()
{
	mysqlShow $1 | sed -e "s/\${PERCONA_CONNECTION}/${PERCONA_CONNECTION}/g"
}

