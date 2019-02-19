#!/usr/bin/env sh

VERSION=1.0.3
BASE_DIR=$(dirname $0)
ADAPTER_ARGS=

. ${BASE_DIR}/utils/base.sh
. ${BASE_DIR}/utils/options.sh
. ${BASE_DIR}/utils/output.sh
. ${BASE_DIR}/adapters/${ADAPTER}/impl.sh

usage()
{
	echo "${SCRIPT_NAME} [OPTIONS]..."
	echo "  Utility for testing adapters migrations"
	printf "${bold}%s${reset}:" "Options"
	adapterUsage
	echo "
  --help            This help message
  --debug           Runs script in BASH debug mode (set -x)
  -v, --version     Prints version"
}

while [ "$1" != "" ]; do
	case $1 in
		--help) usage >&2; exit;;
		-v|--version) version; exit;;
		--endopts) shift; break;;
		--debug) set -x;;
		*) ADAPTER_ARGS="${ADAPTER_ARGS} $1";;
	esac
	shift
done

exitStatus=0
errOut=
for test in ${BASE_DIR}/tests/${ADAPTER}/*/*.sh; do
	[ -f "${test}" ] || continue
	printf "$(basename "${test}" .sh) ...."
	testOut=$("${test}" ${ADAPTER_ARGS} 2>&1 1>/dev/null)
	if [ "$?" = 0 ]; then
		printf " ${green}%s${reset}\n" "OK"
	else
		exitStatus=1
		printf " ${red}%s${reset}\n" "FAIL"
		errOut="${errOut}\n${test}:\n${testOut}\n"
	fi
done

[ ${exitStatus} = 0 ] || toStdErr printf "${errOut}"
exit ${exitStatus}
