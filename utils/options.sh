#!/usr/bin/env sh

unset options

while [ $# -ne 0 ]; do
	case $1 in
	-?*=*) options="${options} ${1%%=*} ${1#*=}" ;;
	-[!-]?*) param=$1; options="${options} $(echo "${param}" | cut -c1-2) $(echo "${param}" | cut -c3-)";;
	--) options="${options} --endopts " ;;
	*) options="${options} $1" ;;
	esac
	shift
done

set -- ${options}
unset options
