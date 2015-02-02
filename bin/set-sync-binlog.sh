#!/bin/bash -e

. $PWD/lib/common.sh

function main {
	if [ $# -lt 2 ]; then
		exit_with_feedback "set-sync-binlog.sh <stack_name> <true|1|false|0>"
	fi

	local stack_name=$1 ; shift
	local value=$1

	local bit

	case "$value" in
	  true)
		bit=1
	    ;;
	  1)
		bit=1
	    ;;	    
	  false)
		bit=0
	    ;;
	  0)
		bit=0
	    ;;	    
	  *)
		exit_with_feedback "set-sync-binlog.sh <stack_name> <true|false>"
	    ;;
	esac

	echo "Setting sync_binlog for $stack_name to $bit..."

	local db_parameter_group=`aws rds describe-db-parameter-groups | jq .DBParameterGroups[].DBParameterGroupName | grep $stack_name | tr -d \"`
	aws rds modify-db-parameter-group --db-parameter-group-name $db_parameter_group --parameters ParameterName=sync_binlog,ParameterValue=$bit,ApplyMethod=immediate
}

main "$@"
