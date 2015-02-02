#!/bin/bash -e

. $PWD/lib/common.sh

function main {
	if [ $# -eq 0 ]; then
        exit_with_feedback "No stack name was specified."
    fi

	local stack_name=$1 ; shift

	echo "Looking up sync_binlog for $stack_name..."

	local db_parameter_group=`aws rds describe-db-parameter-groups | jq .DBParameterGroups[].DBParameterGroupName | grep $stack_name | tr -d \"`
	aws rds describe-db-parameters --db-parameter-group-name $db_parameter_group | jq '.Parameters[] | select(.ParameterName == "sync_binlog")'
}

main "$@"
