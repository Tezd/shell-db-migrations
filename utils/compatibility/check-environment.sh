#!/usr/bin/env sh

VERSION=1.0.2
BASE_DIR=$(dirname $0)
DOCKER_PATH=${DOCKER_PATH:-$(which docker)}
TIMEOUT=${TIMEOUT:-50}
TEST_NETWORK="$1"
APP_DOCKER_FILE="$2"
DB_DOCKER_FILE="$3"
ADAPTER="$4"
EXIT_CODE=1

. "${BASE_DIR}"/../output.sh

if [ -z "${DOCKER_PATH}" ]; then
	toStdErr echo "No path to [${DOCKER_PATH}] was provided and wasn't able to locate it using which"
	toStdErr echo "You can provide custom path by prepending [DOCKER_PATH] before command"
	toStdErr echo "Ex: DOCKER_PATH=my/path/docker ./test-compatibility.sh"
	exit 1
fi

if [ -z "${TEST_NETWORK}" ]; then
	toStdErr echo "TEST_NETWORK should be specified as first argument"
	exit 1
fi

if [ -z "${APP_DOCKER_FILE}" ]; then
	toStdErr echo "APP_DOCKER_FILE should be specified as second argument"
	exit 1
fi

if [ -z "${DB_DOCKER_FILE}" ]; then
	toStdErr echo "DB_DOCKER_FILE should be specified as third argument"
	exit 1
fi

if [ -z "${ADAPTER}" ]; then
	toStdErr echo "ADAPTER should be specified as forth argument"
	exit 1
fi

assembleContainer()
{
	silent ${DOCKER_PATH} build --rm -t "$1" -f "$2" ${BASE_DIR}/../../
	${DOCKER_PATH} run --network "${TEST_NETWORK}" -d "$1" | cut -c -12
}

dismantleContainer()
{
	silent ${DOCKER_PATH} stop "$1" && silent ${DOCKER_PATH} rm "$1"
}

waitForIt()
{
	local containerHealth=
	for i in $(seq 1 ${TIMEOUT}); do
		containerHealth=$(${DOCKER_PATH} inspect --format='{{.State.Health}}' "$1" | awk '{print $1}')
		[ "${containerHealth}" = "{healthy" ] && return 0
		sleep 1
	done
	return 1
}

appOsPart=$(echo "${APP_DOCKER_FILE}" | awk -F/ '{print $((NF-2))}')
appVersionPart=$(echo "${APP_DOCKER_FILE}" | awk -F/ '{print $((NF-1))}')
appDbPart=$(echo "${APP_DOCKER_FILE}" | awk -F/ '{print $NF}' | awk -F- '{print $1}')

dbNamePart=$(echo "${DB_DOCKER_FILE}" | awk -F/ '{print $((NF-1))}')
dbVersionPart=$(echo "${DB_DOCKER_FILE}" | awk -F/ '{print $NF}' | awk -F- '{print $1}')

printf "ADAPTER [${bold}%s${reset}] OS [${bold}%s${reset}] DB [${bold}%s${reset}] ... " \
"${ADAPTER}" "${appOsPart}:${appVersionPart}" "${dbNamePart}:${dbVersionPart}"

APP_CONTAINER_NAME=$(assembleContainer "${appOsPart}-${appDbPart}:${appVersionPart}" "${APP_DOCKER_FILE}")
DB_CONTAINER_NAME=$(assembleContainer "${dbNamePart}:${dbVersionPart}" "${DB_DOCKER_FILE}")

OUTPUT=
if waitForIt "${DB_CONTAINER_NAME}"; then
	connArgs=$(HOST=${DB_CONTAINER_NAME} ${BASE_DIR}/../../tests/${ADAPTER}/connArgs.sh)
	OUTPUT=$(${DOCKER_PATH} exec -t "${APP_CONTAINER_NAME}" sh -c "ADAPTER=${ADAPTER} /app/test-adapter.sh ${connArgs}")
	EXIT_CODE=$?
else
	OUTPUT=$(printf "DB container was not ready after ${bold}%s${reset} seconds\n" ${TIMEOUT})
fi

dismantleContainer "${APP_CONTAINER_NAME}"
dismantleContainer "${DB_CONTAINER_NAME}"

if [ ${EXIT_CODE} -eq 0 ]; then
	printf "${green}%s${reset}\n" "OK"
else
	printf "${red}%s${reset}\n" "FAIL"
fi
echo "${OUTPUT}"
exit ${EXIT_CODE}
