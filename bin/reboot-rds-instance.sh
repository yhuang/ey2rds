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

	echo "Rebooting the RDS bridge instance ($rds_master_instance_id) with forced failover..."
	echo
	aws rds reboot-db-instance --db-instance-identifier $rds_master_instance_id --force-failover
}

main "$@"