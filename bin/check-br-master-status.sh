#!/bin/bash -e

. $PWD/lib/common.sh

function main {
	if [ $# -eq 0 ]; then
		exit_with_feedback "No stack name was specified."
	fi

	local stack_name=$1 ; shift

	check_database_user
	check_database_user_password	

	local show_master_status="$(br_ssh) $(br_mysql $stack_name) -e 'show master status'"

	local timestamp_1=$(date -u "+%Y-%m-%d %H:%M:%S")
	local status_1=`$show_master_status | grep bin`

	sleep 3

	local timestamp_2=$(date -u "+%Y-%m-%d %H:%M:%S")
	local status_2=`$show_master_status | grep bin`

	echo "$timestamp_1:  $status_1"
	echo "$timestamp_2:  $status_2"
	echo

	if [[ $status_1 == $status_2 ]]; then
		echo 'MySQL 5.5.31 is NOT replicating from its MySQL 5.1.55 master.'
	else
		echo 'MySQL 5.5.31 is replicating from its MySQL 5.1.55 master.'
	fi
}

main "$@"