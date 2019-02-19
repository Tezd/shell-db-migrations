#!/usr/bin/env sh

SCRIPT_NAME=$(basename $0)
VERSION=${VERSION:-1.0.0}
ADAPTER=${ADAPTER:- }
ADAPTER_VERSION=

version()
{
	echo ${SCRIPT_NAME} v${VERSION} \(adapter: ${ADAPTER}-${ADAPTER_VERSION}\)
}

getAdapters()
{
	for adapter in ${BASE_DIR}/adapters/*; do
		[ -e ${adapter} ] || continue
		basename ${adapter}
	done
}

ADAPTERS=$(getAdapters)

if ! echo "${ADAPTERS}" | grep -q "${ADAPTER}"; then
	echo >&2 "Provided adapter [${ADAPTER}] is invalid"
	echo >&2 "Adapter should be specified by adding ADAPTER=<adapter_name> before ${SCRIPT_NAME}"
	echo >&2 "<adapter_name> can be one of following: "
	echo >&2 "${ADAPTERS}"
	exit 1
fi
