#!/usr/bin/env sh

BASE_DIR=$(dirname $0)
BASE_MIGRATION_DIR=$(mktemp -d)
ARGS="$@"
MIGRATION_ID_FIRST=20181207122842
MIGRATION_NAME_FIRST=$(mktemp -u XXXXXX)
TABLE_NAME_FIRST=first_table
MIGRATION_ID_SECOND=20181207122843
MIGRATION_NAME_SECOND=$(mktemp -u XXXXXX)
TABLE_NAME_SECOND=second_table
MIGRATION_ID_THIRD=20181207122845
MIGRATION_NAME_THIRD=$(mktemp -u XXXXXX)
CHECK=
FAILED=0

. ${BASE_DIR}/../../../adapters/clickhouse/impl.sh

cleanUp()
{
	rm -rf ${BASE_MIGRATION_DIR}
	${CLICKHOUSE_CONNECTION} --multiquery --multiline --query  "
	DROP TABLE ${TABLE_NAME_FIRST};
	DROP TABLE ${TABLE_NAME_SECOND};
	DROP TABLE migration"
}

failWithMessage()
{
	FAILED=1
	echo >&2 $1
}

createUpMigration()
{
	local MIGRATION_FULLPATH=${BASE_MIGRATION_DIR}/$2_$3
	mkdir ${MIGRATION_FULLPATH}
	echo "$1" >${MIGRATION_FULLPATH}/up.sh
}

checkTools || exit 1

while [ "$1" != "" ]; do
	parseAdapterOptions "$@"
	shift
done

validateOptions || exit 1
prepareConnection
checkConnection || exit 1

createUpMigration \
"\${CLICKHOUSE_CONNECTION} --query \"CREATE TABLE ${TABLE_NAME_FIRST} (id Int32, date Date) Engine=MergeTree PARTITION BY toYYYYMM(date) ORDER BY (id, date)\"" \
${MIGRATION_ID_FIRST} ${MIGRATION_NAME_FIRST}

createUpMigration \
"\${CLICKHOUSE_CONNECTION} --query \"CREATE TABLE ${TABLE_NAME_SECOND} (id Int32, date Date, test String) Engine=MergeTree PARTITION BY toYYYYMM(date) ORDER BY (id, date)\"" \
 ${MIGRATION_ID_SECOND} ${MIGRATION_NAME_SECOND}

createUpMigration \
"\${CLICKHOUSE_CONNECTION} --query \"ALTER TABLE ${TABLE_NAME_FIRST} ADD COLUMN field UInt32 DEFAULT 0\"" \
 ${MIGRATION_ID_THIRD} ${MIGRATION_NAME_THIRD}

MIGRATION_DIR=${BASE_MIGRATION_DIR} ADAPTER=clickhouse ${BASE_DIR}/../../../migrate.sh ${ARGS} 2>/dev/null >/dev/null

for migrationId in ${MIGRATION_ID_FIRST} ${MIGRATION_ID_SECOND} ${MIGRATION_ID_THIRD}; do
	CHECK=$(${CLICKHOUSE_CONNECTION} --query "SELECT count(*) FROM migration WHERE id = ${migrationId}" 2>&1)
	[ "${CHECK}" = 1 ] || failWithMessage "Migration [${migrationId}] was not found in migration table"
done

for tableName in ${TABLE_NAME_FIRST} ${TABLE_NAME_SECOND}; do
	CHECK=$(${CLICKHOUSE_CONNECTION} \
		--query "SELECT count(*) FROM system.tables WHERE database='${DB}' and name='${tableName}'")
	[ "${CHECK}" = 1 ] || failWithMessage "Table [${tableName}] was not created"
done

for columnData in \
"${TABLE_NAME_FIRST}:id:Int32" \
"${TABLE_NAME_FIRST}:date:Date" \
"${TABLE_NAME_FIRST}:field:UInt32" \
"${TABLE_NAME_SECOND}:id:Int32" \
"${TABLE_NAME_SECOND}:date:Date" \
"${TABLE_NAME_SECOND}:test:String"; do
	tableName=$(echo "${columnData}" | awk -F: '{print $1}')
	columnName=$(echo "${columnData}" | awk -F: '{print $2}')
	columnType=$(echo "${columnData}" | awk -F: '{print $3}')
	CHECK=$(${CLICKHOUSE_CONNECTION} \
		--query "SELECT count(*) FROM system.columns WHERE database='${DB}' and table='${tableName}'
		and name='${columnName}' and type='${columnType}'")
	[ "${CHECK}" = 1 ] || failWithMessage "Table [${tableName}] doesn't have column [${columnName}($columnType)]"
done;

cleanUp

exit ${FAILED}

