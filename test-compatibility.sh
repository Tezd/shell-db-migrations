#!/usr/bin/env bash

VERSION=1.0.2
BASE_DIR=$(dirname $0)
DOCKER_PATH=${DOCKER_PATH:-$(which docker)}
ENVIRONMENTS_SOURCE=${BASE_DIR}/utils/compatibility/list-test-environments.sh
ENVIRONMENT_TESTER=${BASE_DIR}/utils/compatibility/check-environment.sh
OUTPUT_WRAPPER=${BASE_DIR}/utils/compatibility/wrap-output.sh
TEST_NETWORK=snappy-test-network
PROCESSES=${1:-$(($(nproc) /2 +1))}
EXIT_CODE=1

if [ -z "${DOCKER_PATH}" ]; then
	echo >&2 "No path to [${DOCKER_PATH}] was provided and wasn't able to locate it using which"
	echo >&2 "You can provide custom path by prepending [DOCKER_PATH] before command"
	echo >&2 "Ex: DOCKER_PATH=my/path/docker ./test-compatibility.sh"
	exit 1
fi

. ${BASE_DIR}/utils/output.sh

silent docker network create "${TEST_NETWORK}"

${ENVIRONMENTS_SOURCE} | xargs -L1 -P${PROCESSES} "${OUTPUT_WRAPPER}" "${ENVIRONMENT_TESTER}" "${TEST_NETWORK}"

EXIT_CODE=$?

silent docker network rm "${TEST_NETWORK}"

silent docker system prune -f

silent docker volume prune -f

exit ${EXIT_CODE}
