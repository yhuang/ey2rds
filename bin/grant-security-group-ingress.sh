#!/bin/bash -e

. $PWD/lib/common.sh

function main {
	if [ $# -eq 0 ]; then
		exit_with_feedback "No stack name was specified."
	fi

	local stack_name=$1 ; shift

	echo "Determining $stack_name.brenv.net's RDS instance IP Address..."
	echo 
	rds_instance_ip_address=$(rds_instance_ip_address $stack_name)

	echo "Opening Engine Yard MySQL 5.5.31's security group to $stack_name.brenv.net ($rds_instance_ip_address)..."
	echo

	aws ec2 authorize-security-group-ingress \
	--profile ey \
	--group-id sg-207fb74a \
	--protocol tcp \
	--cidr $rds_instance_ip_address/0 \
	--port 3306
}

main "$@"