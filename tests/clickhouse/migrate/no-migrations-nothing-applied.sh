#!/usr/bin/env sh

BASE_DIR=$(dirname $0)/../../..
BASE_MIGRATION_DIR=$(mktemp -d)
ARGS="$@"
FAILED=0

. ${BASE_DIR}/adapters/clickhouse/impl.sh

cleanUp()
{
	rm -rf ${BASE_MIGRATION_DIR}
	${CLICKHOUSE_CONNECTION} --query "DROP TABLE migration"
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

MIGRATION_DIR=${BASE_MIGRATION_DIR} ADAPTER=clickhouse ${BASE_DIR}/migrate.sh ${ARGS} 2>/dev/null >/dev/null

CHECK=$(${CLICKHOUSE_CONNECTION} --query "SELECT count(*) FROM migration" 2>&1)
[ "${CHECK}" = 0 ] || failWithMessage "Migration table suppose to be empty"

cleanUp

exit ${FAILED}
