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
	DROP TABLE IF EXISTS ${TABLE_NAME_SECOND};
	DROP TABLE migration"
}

failWithMessage()
{
	FAILED=1
	echo >&2 $1
}

createDownMigration()
{
	local MIGRATION_FULLPATH=${BASE_MIGRATION_DIR}/$2_$3
	mkdir ${MIGRATION_FULLPATH}
	echo "$1" >${MIGRATION_FULLPATH}/down.sh
}

checkTools || exit 1

while [ "$1" != "" ]; do
	parseAdapterOptions "$@"
	shift
done

validateOptions || exit 1
prepareConnection
checkConnection || exit 1

createDownMigration \
"\${MYSQL_CONNECTION} -e\"DROP TABLE ${TABLE_NAME_FIRST}\"" \
${MIGRATION_ID_FIRST} ${MIGRATION_NAME_FIRST}

createDownMigration \
"\${MYSQL_CONNECTION} -e\"DROP TABLE ${TABLE_NAME_SECOND}\"" \
 ${MIGRATION_ID_SECOND} ${MIGRATION_NAME_SECOND}

createDownMigration \
"\${PERCONA_CONNECTION},t=${TABLE_NAME_FIRST} --alter \"DROP pt_field\" --execute" \
 ${MIGRATION_ID_THIRD} ${MIGRATION_NAME_THIRD}

ensureMigrationTableExists

${MYSQL_CONNECTION} -e"CREATE TABLE ${TABLE_NAME_FIRST}
 (id INT PRIMARY KEY, pt_field INT(10) UNSIGNED NOT NULL DEFAULT '0')"
${MYSQL_CONNECTION} -e"CREATE TABLE ${TABLE_NAME_SECOND} (id INT PRIMARY KEY, test VARCHAR(20))"
${MYSQL_CONNECTION} -e"INSERT INTO migration VALUES
(${MIGRATION_ID_FIRST}, now()),
(${MIGRATION_ID_SECOND}, now()),
(${MIGRATION_ID_THIRD}, now())"

MIGRATION_DIR=${BASE_MIGRATION_DIR} ADAPTER=percona ${BASE_DIR}/rollback.sh \
${ARGS} ${MIGRATION_ID_FIRST} 2>/dev/null >/dev/null

CHECK=$(${MYSQL_CONNECTION} --skip-column-names \
	-e"SELECT count(*) FROM migration WHERE id = ${MIGRATION_ID_FIRST}\G" 2>&1 | tail -1)
[ "${CHECK}" = 1 ] || failWithMessage "Migration [${MIGRATION_ID_FIRST}] should not be reverted"

for migrationId in ${MIGRATION_ID_SECOND} ${MIGRATION_ID_THIRD}; do
	CHECK=$(${MYSQL_CONNECTION} --skip-column-names \
		-e"SELECT count(*) FROM migration WHERE id = ${migrationId}\G" 2>&1 | tail -1)
	[ "${CHECK}" = 0 ] || failWithMessage "Migration [${migrationId}] should be reverted"
done

CHECK=$(${MYSQL_CONNECTION} --skip-column-names \
	-e"SELECT count(*) FROM information_schema.tables WHERE table_schema='${DB}' and table_name='${TABLE_NAME_SECOND}'\G" \
	| tail -1)
[ "${CHECK}" = 0 ] || failWithMessage "Table [${TABLE_NAME_SECOND}] should be deleted"

CHECK=$(${MYSQL_CONNECTION} --skip-column-names \
	-e"SELECT count(*) FROM information_schema.tables WHERE table_schema='${DB}' and table_name='${TABLE_NAME_FIRST}'\G" \
	| tail -1)
[ "${CHECK}" = 1 ] || failWithMessage "Table [${TABLE_NAME_FIRST}] should not be deleted"

CHECK=$(${MYSQL_CONNECTION} --skip-column-names \
		-e"SELECT count(*) FROM information_schema.columns WHERE table_schema='${DB}' and table_name='${TABLE_NAME_FIRST}'
		and column_name='pt_field'\G" | tail -1)
	[ "${CHECK}" = 0 ] || failWithMessage "Column [${TABLE_NAME_FIRST}.pt_field] should be reverted"

cleanUp

exit ${FAILED}
