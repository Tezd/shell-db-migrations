#!/usr/bin/env sh

bold="\033[1m"
reset="\033[0m"
green="\033[32m"
red="\033[31m"

silent()
{
	"$@" 2>/dev/null >/dev/null
}

toStdErr()
{
	"$@" >&2
}
