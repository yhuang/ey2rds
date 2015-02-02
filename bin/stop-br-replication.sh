#!/bin/bash -e

. $PWD/lib/common.sh

function main {
	if [ $# -eq 0 ]; then
		exit_with_feedback "No stack name was specified."
	fi

	local stack_name=$1 ; shift

	check_database_user
	check_database_user_password
	
	local sp_rds_stop_replication="CALL mysql.rds_stop_replication"
	local stop_replication="$(br_ssh) $(br_mysql $stack_name) -e '$sp_rds_stop_replication'"

	echo "Determining $stack_name.brenv.net's RDS instance ID..."
	echo
	local rds_master_instance_id=$(rds_master_instance_id $stack_name)

	echo "On $stack_name.brenv.net ($rds_master_instance_id):  $sp_rds_stop_replication"
	$stop_replication
	echo

	sleep 3

	local show_slave_status="$(br_ssh) $(br_mysql $stack_name) -e 'show slave status\G'"
	local slave_status=`$show_slave_status | grep Seconds_Behind_Master; echo`
	echo $slave_status
}

main "$@"
