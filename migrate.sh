#!/usr/bin/env sh

#TODO Trap signals
#TODO make timestamp unique

VERSION=1.0.3
BASE_DIR=$(dirname $0)
MIGRATION_DIR=${MIGRATION_DIR:-${BASE_DIR}/migrations}
DRYRUN=false

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
			*) parseAdapterOptions "$@"; shift;;
		esac
		shift
	done
}

usage()
{
	echo "${SCRIPT_NAME} [OPTIONS]..."
	printf "  Utility for running "
	printf "${bold}%s${reset} %s\n" "${ADAPTER}" "migrations"
	printf "${bold}%s${reset}:" "Options"
	adapterUsage
	echo "
  -v, --version     Prints version
  --dry-run         Output only. No execution
  --help            This help message
  --debug           Runs script in BASH debug mode (set -x)"
}

getMigrations()
{
	for file in ${MIGRATION_DIR}/*_*; do
		[ -e ${file} ] || continue
		basename ${file}
	done | sort -n
}

run()
{
	. $1
	addVersion $2
}

checkTools || exit 1
[ $# -eq 0 ] && set -- "--help"
parseOptions "$@"
validateOptions || exit 1
prepareConnection
checkConnection || exit 1
ensureMigrationTableExists

MIGRATION_TMP_FILE=$(mktemp)
VERSIONS_TMP_FILE=$(mktemp)

getMigrations | awk -F_ '{print $1}' > ${MIGRATION_TMP_FILE}
getVersions ASC > ${VERSIONS_TMP_FILE}

executor=run
if ${DRYRUN}; then
	executor=show
fi

DIFF=$(comm -32 ${MIGRATION_TMP_FILE} ${VERSIONS_TMP_FILE})
rm -f ${MIGRATION_TMP_FILE} ${VERSIONS_TMP_FILE}

if [ -z "${DIFF}" ]; then
	echo "No migrations to execute. Exiting..."
	exit
fi

set -e
for migration in ${DIFF}; do
	echo "----------------------------------------"
	echo "Applying migration [${migration}]"
	echo "----------------------------------------"
	${executor} ${MIGRATION_DIR}/${migration}_*/up.sh ${migration}
done
