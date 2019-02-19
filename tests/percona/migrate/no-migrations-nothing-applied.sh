#!/usr/bin/env sh

BASE_DIR=$(dirname $0)/../../..
BASE_MIGRATION_DIR=$(mktemp -d)
ARGS="$@"
FAILED=0

. ${BASE_DIR}/adapters/percona/impl.sh

cleanUp()
{
	rm -rf ${BASE_MIGRATION_DIR}
	${MYSQL_CONNECTION} -e"DROP TABLE migration"
}

failWithMessage()
{
	FAILED=1
	echo >&2 $1
}

checkTools || exit 1

while [ "$1" != "" ]; do
	parseAdapterOptions "$@"
	shift
done

validateOptions || exit 1
prepareConnection
checkConnection || exit 1

MIGRATION_DIR=${BASE_MIGRATION_DIR} ADAPTER=percona ${BASE_DIR}/migrate.sh ${ARGS} 2>/dev/null >/dev/null

CHECK=$(${MYSQL_CONNECTION} --skip-column-names \
	-e"SELECT count(*) FROM migration\G" 2>&1 | tail -1)
[ "${CHECK}" = 0 ] || failWithMessage "Migration table suppose to be empty"

cleanUp

exit ${FAILED}
