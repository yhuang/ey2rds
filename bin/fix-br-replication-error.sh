#!/bin/bash -e

. $PWD/lib/common.sh

function main {
	if [ $# -eq 0 ]; then
		exit_with_feedback "No stack name was specified."
	fi

	local stack_name=$1 ; shift

	check_database_user
	check_database_user_password	

	local show_slave_status="$(br_ssh) $(br_mysql $stack_name) -e 'show slave status\G'"
	local slave_status=`$show_slave_status | \
	lib/process-slave-status.rb | \
	jq "{ \
	Slave_IO_State: .Slave_IO_State, \
	Seconds_Behind_Master: .Seconds_Behind_Master, \
	Last_SQL_Errno: .Last_SQL_Errno, \
	Last_SQL_Error: .Last_SQL_Error, \
	Last_IO_Errno: .Last_IO_Errno, \
	Last_IO_Error: .Last_IO_Error, \
	Master_Log_File: .Master_Log_File
	}"`

	local last_sql_errno=`echo $slave_status | jq .Last_SQL_Errno`
	local last_sql_error=`echo $slave_status | jq .Last_SQL_Error`
	local last_io_errno=`echo $slave_status | jq .Last_IO_Errno`
	local last_io_error=`echo $slave_status | jq .Last_IO_Error`
	local master_log_file=`echo $slave_status | jq .Master_Log_File`

	if [ $last_io_errno == 0 ] && [ $last_sql_errno == 0 ]; then
		printf "$stack_name:  There is no error to fix.\n\n"
		exit
	fi

	if [ $last_io_errno != 1236 ] && [ $last_sql_errno != 1062 ]; then
		printf "$stack_name:  Cannot recover from error.\n\n"
		printf "$slave_status\n\n"
		exit
	fi

	if [ $last_io_errno == 1236 ]; then
		local current_master_log=`echo $master_log_file | grep -E -o [0-9]+ | sed 's/^0*//'`
		local sp_rds_next_master_log="CALL mysql.rds_next_master_log($current_master_log)"

		printf "$stack_name:  Running '$sp_rds_next_master_log' to fix Error 1236...\n\n"
		$(br_ssh) "$(br_mysql $stack_name) -e '$sp_rds_next_master_log'"
	fi

	if [ $last_sql_errno == 1062 ]; then
		local sp_rds_skip_repl_error="CALL mysql.rds_skip_repl_error"

		printf "$stack_name:  Running '$sp_rds_skip_repl_error' to skip Error $last_sql_errno ($last_sql_error)...\n\n"
		$(br_ssh) "$(br_mysql $stack_name) -e '$sp_rds_skip_repl_error'"
	fi

	if [ $last_io_errno != 0 ] || [ $last_sql_errno != 0 ]; then
		$PWD/bin/check-br-slave-status.sh $stack_name
	fi
}

main "$@"