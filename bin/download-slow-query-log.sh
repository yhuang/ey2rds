#!/bin/bash -e

. $PWD/lib/common.sh

function main {
	if [ $# -eq 0 ]; then
		exit_with_feedback "No stack name was specified."
	fi

	local stack_name=$1 ; shift
		
	echo "Determining $stack_name.brenv.net's RDS instance ID..."
	echo 
	local rds_master_instance_id=$(rds_master_instance_id $stack_name)
	local slow_query_log=$stack_name-slow-query-log-$(date -u "+%Y-%m-%d-%H-%M")

	echo "Writing slow query log ($slow_query_log) for $stack_name.brenv.net ($rds_master_instance_id)..."
	echo
	aws rds download-db-log-file-portion --db-instance-identifier $rds_master_instance_id --output text --log-file-name slowquery/mysql-slowquery.log > $slow_query_log
}

main "$@"
