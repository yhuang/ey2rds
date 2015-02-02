#!/bin/bash -e

. $PWD/lib/common.sh

function main {
	if [ $# -eq 0 ]; then
		exit_with_feedback "No stack name was specified."
	fi

	local stack_name=$1 ; shift

	check_database_user
	check_database_user_password
	check_replication_user
	check_replication_user_password

	if [ -e $EY_BINLOG ]; then
		local ey_binlog_data=`cat $EY_BINLOG`
		read -a ey_binlog_data <<< "${ey_binlog_data}"
		local binary_log_file_name=${ey_binlog_data[0]}
		local binary_log_file_location=${ey_binlog_data[1]}
	else
		echo "No binary log data is available."
		exit
	fi

	local set_external_master="$(br_ssh) $(br_mysql $stack_name) -e \"CALL mysql.rds_set_external_master('10.218.140.234', 3306, '$REPLICATION_USER', '$REPLICATION_USER_PASSWORD', '$binary_log_file_name', $binary_log_file_location, 1)\""
	local show_slave_status="$(br_ssh) $(br_mysql $stack_name) -e 'show slave status\G'"

	echo "Determining $stack_name.brenv.net's RDS instance ID..."
	echo 
	local rds_master_instance_id=$(rds_master_instance_id $stack_name)

	echo "On $stack_name.brenv.net ($rds_master_instance_id): CALL mysql.rds_set_external_master"
	echo

	$set_external_master; $show_slave_status | grep Seconds_Behind_Master; echo
}

main "$@"

