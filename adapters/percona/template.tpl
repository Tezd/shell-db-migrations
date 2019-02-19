#!/usr/bin/env sh
#Variables available in this file:
#	${MYSQL_CONNECTION}
#	${PERCONA_CONNECTION}
#Examples:
#	${MYSQL_CONNECTION} < migration.sql
#
#	${MYSQL_CONNECTION} -e"CREATE TABLE test (id INT PRIMARY KEY)"
#
#	${PERCONA_CONNECTION},t=system_agregator \
#	--alter "ADD callback_timeout_sec INT(10) UNSIGNED NOT NULL DEFAULT '0' AFTER \`send_zero_wins\`" \
#	--execute
