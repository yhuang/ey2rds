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
	local slave_delay=`$show_slave_status | grep Seconds_Behind_Master; echo`

	printf "$stack_name\n$slave_delay\n\n"
}

main "$@"