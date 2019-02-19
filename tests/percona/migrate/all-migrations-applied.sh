#!/usr/bin/env sh

BASE_DIR=$(dirname $0)/../../..
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

. ${BASE_DIR}/adapters/percona/impl.sh

cleanUp()
{
	rm -rf ${BASE_MIGRATION_DIR}
	${MYSQL_CONNECTION} -e"
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
"\${MYSQL_CONNECTION} -e\"CREATE TABLE ${TABLE_NAME_FIRST} (id INT PRIMARY KEY)\"" \
${MIGRATION_ID_FIRST} ${MIGRATION_NAME_FIRST}

createUpMigration \
"\${MYSQL_CONNECTION} -e\"CREATE TABLE ${TABLE_NAME_SECOND} (id INT PRIMARY KEY, test VARCHAR(20))\"" \
 ${MIGRATION_ID_SECOND} ${MIGRATION_NAME_SECOND}

createUpMigration \
"\${PERCONA_CONNECTION},t=${TABLE_NAME_FIRST} --alter \"ADD pt_field INT(10) UNSIGNED NOT NULL DEFAULT '0'\" --execute" \
 ${MIGRATION_ID_THIRD} ${MIGRATION_NAME_THIRD}

MIGRATION_DIR=${BASE_MIGRATION_DIR} ADAPTER=percona ${BASE_DIR}/migrate.sh ${ARGS} 2>/dev/null >/dev/null

for migrationId in ${MIGRATION_ID_FIRST} ${MIGRATION_ID_SECOND} ${MIGRATION_ID_THIRD}; do
	CHECK=$(${MYSQL_CONNECTION} --skip-column-names \
		-e"SELECT count(*) FROM migration WHERE id = ${migrationId}\G" 2>&1 | tail -1)
	[ "${CHECK}" = 1 ] || failWithMessage "Migration [${migrationId}] was not found in migration table"
done

for tableName in ${TABLE_NAME_FIRST} ${TABLE_NAME_SECOND}; do
	CHECK=$(${MYSQL_CONNECTION} --skip-column-names \
		-e"SELECT count(*) FROM information_schema.tables WHERE table_schema='${DB}' and table_name='${tableName}'\G" \
		| tail -1)
	[ "${CHECK}" = 1 ] || failWithMessage "Table [${tableName}] was not created"
done

for columnData in \
"${TABLE_NAME_FIRST}:id:int(11)" \
"${TABLE_NAME_FIRST}:pt_field:int(10) unsigned" \
"${TABLE_NAME_SECOND}:id:int(11)" \
"${TABLE_NAME_SECOND}:test:varchar(20)"; do
	tableName=$(echo "${columnData}" | awk -F: '{print $1}')
	columnName=$(echo "${columnData}" | awk -F: '{print $2}')
	columnType=$(echo "${columnData}" | awk -F: '{print $3}')
	CHECK=$(${MYSQL_CONNECTION} --skip-column-names \
		-e"SELECT count(*) FROM information_schema.columns WHERE table_schema='${DB}' and table_name='${tableName}'
		and column_name='${columnName}' and column_type='${columnType}'\G" | tail -1)
	[ "${CHECK}" = 1 ] || failWithMessage "Table [${tableName}] doesn't have column [${columnName}($columnType)]"
done;

cleanUp

exit ${FAILED}

