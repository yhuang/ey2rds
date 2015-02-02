#!/bin/bash -e

. $PWD/lib/common.sh

function main {
	if [ $# -eq 0 ]; then
		exit_with_feedback "No account name was specified (br or ey)."
	fi

	local account_name=$1 ; shift

	if [ $account_name == 'ey' ]; then
		local ey_ssh="ssh -i $ENGINE_YARD_KEY ${ENGINE_YARD_RESOURCES['5.5.31']}"
		echo $ey_ssh
		$ey_ssh
	elif [ $account_name == 'br' ]; then
		local br_ssh="ssh -i $BR_USER_KEY $BR_USER@$BR_EC2_INSTANCE"
		echo $br_ssh
		$br_ssh
	else
		exit_with_feedback "Account name must be either br or ey"
	fi
}

main "$@"

