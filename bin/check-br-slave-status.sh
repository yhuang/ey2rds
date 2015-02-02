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

	printf "$stack_name\n$slave_status\n\n"
}

main "$@"
