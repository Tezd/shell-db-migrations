#!/usr/bin/env sh

BASE_DIR=$(dirname $0)/../../..
BASE_MIGRATION_DIR=$(mktemp -d)
MIGRATION_NAME=$(mktemp -u XXXXXX)
FAILED=0

createMigration()
{
	echo ${MIGRATION_NAME} | MIGRATION_DIR=${BASE_MIGRATION_DIR} ADAPTER=mysql ${BASE_DIR}/create.sh
}

failWithMessage()
{
	FAILED=1
	echo >&2 $1
}

CREATED_MIGRATION_NAME=$(createMigration | awk -F'[][]' '{print $2}')

[ -d ${BASE_MIGRATION_DIR}/${CREATED_MIGRATION_NAME} ] \
|| failWithMessage "Directory [${BASE_MIGRATION_DIR}/${CREATED_MIGRATION_NAME}] was not created"
[ -f ${BASE_MIGRATION_DIR}/${CREATED_MIGRATION_NAME}/up.sh ] \
|| failWithMessage "No up.sh was created in [${BASE_MIGRATION_DIR}/${CREATED_MIGRATION_NAME}]"
[ -f ${BASE_MIGRATION_DIR}/${CREATED_MIGRATION_NAME}/down.sh ] \
|| failWithMessage "No down.sh was created in [${BASE_MIGRATION_DIR}/${CREATED_MIGRATION_NAME}]"

rm -r ${BASE_MIGRATION_DIR}

exit ${FAILED}
