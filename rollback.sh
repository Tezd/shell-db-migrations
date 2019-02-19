#!/usr/bin/env sh

VERSION=1.0.3
BASE_DIR=$(dirname $0)
MIGRATION_DIR=${MIGRATION_DIR:-${BASE_DIR}/migrations}
DRYRUN=false
ARGS=
ROLLBACK_TO=
FOUND=false
ROLLBACK_VERSIONS=

. ${BASE_DIR}/utils/base.sh
. ${BASE_DIR}/utils/options.sh
. ${BASE_DIR}/utils/output.sh
. ${BASE_DIR}/adapters/${ADAPTER}/impl.sh

parseOptions()
{
	while [ "$1" != "" ]; do
		case $1 in
			--help) usage >&2; exit;;
			-v|--version) version; exit;;
			--dry-run) DRYRUN=true;;
			--endopts) shift; break ;;
			--debug) set -x;;
			-?*) parseAdapterOptions "$@"; shift;;
			*) ROLLBACK_TO=$1;;
		esac
		shift
	done
}

usage()
{
	echo "${SCRIPT_NAME} [OPTIONS]... migration_id"
	printf "  Utility for rolling back "
	printf "${bold}%s${reset} %s\n" "${ADAPTER}" "migrations"
	printf "${bold}%s${reset}:\n" "Arguments"
	echo "  migration_id      id of migration to rollback to or 0
                    to rollback everything"
	printf "${bold}%s${reset}:" "Options"
	adapterUsage
	echo "
  -v, --version     Prints version
  --dry-run         Output only. No execution
  --help            This help message
  --debug           Runs script in BASH debug mode (set -x)"
}

checkMigrationVersion()
{
	if [ -z "${ROLLBACK_TO}" ]; then
		toStdErr echo "Migration ID should be specified"
		return 1
	fi
	return 0
}

getMigrations()
{
	for file in ${MIGRATION_DIR}/*_*; do
		[ -e ${file} ] || continue
		basename ${file}
	done | sort -nr
}

run()
{
	. $1
	removeVersion $2
}

checkTools || exit 1
[ $# -eq 0 ] && set -- "--help"
parseOptions "$@"
validateOptions || exit 1
checkMigrationVersion || exit 1
prepareConnection
checkConnection || exit 1

MIGRATIONS_LIST=$(getMigrations)
VERSIONS_LIST=$(getVersions DESC)

executor=run
if ${DRYRUN}; then
	executor=show
fi

if [ "${ROLLBACK_TO}" -eq 0 ]; then
	ROLLBACK_VERSIONS="${VERSIONS_LIST}"
	FOUND=true
else
	for rollback in ${VERSIONS_LIST}; do
		if [ ${rollback} -eq ${ROLLBACK_TO} ]; then
			FOUND=true
			break
		fi
#			if ! echo "${MIGRATIONS_LIST}" | grep -q ${rollback}
#			then
#				echo "Rollback for migration ${rollback} doesnt exist"
#				exit 1
#			fi
		ROLLBACK_VERSIONS="${ROLLBACK_VERSIONS} ${rollback}"
	done
fi

if ! ${FOUND}; then
	toStdErr echo "Migration to rollback to wasn't found in applied migrations"
	toStdErr echo "List of applied migrations: "
	toStdErr echo "${VERSIONS_LIST}"
	toStdErr echo "Requested migration [${ROLLBACK_TO}]"
	exit 1
fi

if [ -z "${ROLLBACK_VERSIONS}" ]; then
	echo "Nothing to rollback. Exiting..."
	exit
fi

set -e
for rollback in ${ROLLBACK_VERSIONS}; do
	echo "----------------------------------------"
	echo "Rolling back migration [${rollback}]"
	echo "----------------------------------------"
	${executor} ${MIGRATION_DIR}/${rollback}_*/down.sh ${rollback}
done
