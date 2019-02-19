#!/usr/bin/env sh

VERSION=1.0.0
BASE_DIR=$(dirname $0)

for adapterTest in ${BASE_DIR}/../../tests/*; do
	adapterName=$(basename ${adapterTest})
	for appImageFile in ${BASE_DIR}/../../docker/app/*/*/${adapterName}-dockerfile; do
		[ -f "${appImageFile}" ] || continue
		DB_LIST="${adapterName}
		$([ -f "${BASE_DIR}/../../tests/${adapterName}/allowedDbs.txt" ] \
		&& cat "${BASE_DIR}/../../tests/${adapterName}/allowedDbs.txt")"
		for allowedDb in ${DB_LIST}; do
			for dbImageFile in ${BASE_DIR}/../../docker/db/${allowedDb}/*-dockerfile; do
				[ -f "${dbImageFile}" ] || continue
				echo "${appImageFile} ${dbImageFile} ${adapterName}"
			done
		done
	done
done
