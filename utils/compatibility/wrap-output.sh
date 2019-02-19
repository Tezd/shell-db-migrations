#!/usr/bin/env sh

OUTPUT_FILE=$(mktemp)
"$@" > ${OUTPUT_FILE}
EXIT_CODE=$?

until ln -s . lock; do :; done;
cat ${OUTPUT_FILE} && rm -f ${OUTPUT_FILE}
mv lock deleteme && rm deleteme

exit ${EXIT_CODE}
