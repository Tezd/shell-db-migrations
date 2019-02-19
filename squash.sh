#!/usr/bin/env sh


exit
VERSION=1.0.0
BASE_DIR=${BASE_DIR:-.}
SNAPSHOT_NAME=$(date +"%s")
DRYRUN=
DEBUG=

. utils/options.sh
. utils/output.sh
. adapters/percona/impl.sh

usage()
{
	echo -n "${SCRIPT_NAME} [OPTIONS]...
  Utility for squashing migrations.

 ${bold}Options${reset}:"
	adapterUsage
	echo "
  --help            This help message
  --debug           Runs script in BASH debug mode (set -x)
  -v, --version     Prints version
"
}

getMigrations()
{
	for file in ${BASE_DIR}/migrations/*_*; do
		[[ -e ${file} ]] || continue
		basename ${file}
	done | sort -V
}

while [[ $1 = -?* ]]; do
	case $1 in
		--help) usage >&2; exit;;
		-v|--version) version; exit;;
		--dry-run) DRYRUN=--dry-run;;
		--debug) DEBUG=--debug; set -x;;
		--endopts) shift; break ;;
		*) parseAdapterOptions "$@"; shift;;
	esac
	shift
done

executor=run
if ${DRYRUN}; then
	executor=show
fi

#checkConnection

#getTables

#dumpStructure
mkdir -p ${BASE_DIR}/dumps/${SNAPSHOT_NAME}


