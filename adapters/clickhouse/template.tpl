#!/usr/bin/env sh
#Variables available in this file:
#	${CLICKHOUSE_CONNECTION}
#Note: you can have multiple query per file by adding --multiquery and --multiline if they are not in one line
#Examples:
#	echo "CREATE TABLE test (id INT, date Date) Engine=MergeTree PARTITION BY toYYYYMM(date) ORDER BY (id, date)" | ${CLICKHOUSE_CONNECTION}
#
#	${CLICKHOUSE_CONNECTION} --query "CREATE TABLE test (id INT, date Date) Engine=MergeTree PARTITION BY toYYYYMM(date) ORDER BY (id, date)"
#
#	${CLICKHOUSE_CONNECTION} < migration.sql

