#!/usr/bin/env sh

VERSION=1.0.1
MIGRATION_ID=$(date +"%Y%m%d%H%M%S")
BASE_DIR=$(dirname $0)
MIGRATION_DIR=${MIGRATION_DIR:-${BASE_DIR}/migrations}
MIGRATION_NAME=

. ${BASE_DIR}/utils/base.sh
. ${BASE_DIR}/utils/options.sh
. ${BASE_DIR}/utils/output.sh
. ${BASE_DIR}/adapters/${ADAPTER}/impl.sh

usage()
{
	echo "${SCRIPT_NAME} [OPTIONS]..."
	echo "  Utility for creating migrations"
	printf "${bold}%s${reset}:" "Options"
	echo "
  --help            This help message
  --debug           Runs script in BASH debug mode (set -x)
  -v, --version     Prints version"
}

while [ "$1" != "" ]; do
	case $1 in
		--help) usage >&2; exit;;
		-v|--version) version; exit;;
		--endopts) shift; break ;;
		--debug) set -x;;
	esac
	shift
done

while [ -z "${MIGRATION_NAME}" ]; do
	read -p "Give your migration a name: " MIGRATION_NAME
done

FULLNAME=${MIGRATION_ID}_${MIGRATION_NAME}
DIR=${MIGRATION_DIR}/${FULLNAME}
mkdir -p ${DIR}
cp ${BASE_DIR}/adapters/${ADAPTER}/template.tpl ${DIR}/up.sh && chmod +x ${DIR}/up.sh
cp ${BASE_DIR}/adapters/${ADAPTER}/template.tpl ${DIR}/down.sh && chmod +x ${DIR}/down.sh
echo "Migration [${FULLNAME}] created. Have fun!"
