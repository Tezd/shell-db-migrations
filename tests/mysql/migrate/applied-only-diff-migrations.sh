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

. ${BASE_DIR}/adapters/mysql/impl.sh

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
"\${MYSQL_CONNECTION} -e\"ALTER TABLE ${TABLE_NAME_FIRST} ADD field INT(10) UNSIGNED NOT NULL DEFAULT '0'\"" \
 ${MIGRATION_ID_THIRD} ${MIGRATION_NAME_THIRD}

ensureMigrationTableExists
${MYSQL_CONNECTION} -e"insert into migration values(${MIGRATION_ID_THIRD}, now())"

MIGRATION_OUTPUT=$(MIGRATION_DIR=${BASE_MIGRATION_DIR} ADAPTER=mysql ${BASE_DIR}/migrate.sh ${ARGS})

echo ${MIGRATION_OUTPUT} | grep -qv "${MIGRATION_ID_THIRD}" \
|| failWithMessage "Applied migration [${MIGRATION_ID_THIRD}] was re-executed"

echo ${MIGRATION_OUTPUT} | grep -q "${MIGRATION_ID_FIRST}" \
|| failWithMessage "Migration [${MIGRATION_ID_FIRST}] was not applied"

echo ${MIGRATION_OUTPUT} | grep -q "${MIGRATION_ID_SECOND}" \
|| failWithMessage "Migration [${MIGRATION_ID_SECOND}] was not applied"

cleanUp

exit ${FAILED}
