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
	local db_snapshot=$stack_name-$(date -u "+%Y-%m-%d-%H-%M")

	echo "Creating a new database snapshot ($db_snapshot) for $stack_name.brenv.net ($rds_master_instance_id)..."
	echo
	aws rds create-db-snapshot --db-instance-identifier $rds_master_instance_id --db-snapshot-identifier $db_snapshot

	echo "When the database snapshot is done:"
	echo
	echo "  $ ./bin/cfn create <new stack name> 'SnapshotId=${db_snapshot};DBInstanceClass=db.r3.2xlarge'"
	echo
}

main "$@"
