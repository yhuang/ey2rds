function exit_with_feedback {
	echo
	echo $1
	echo
	exit
}

function check_bash_version {
	local current_bash_version=${BASH_VERSION%%[^0-9]*}
	[ $current_bash_version -ge 4 ] || exit_with_feedback 'Please upgrade bash to Version 4.'
}

function check_database_user {
	[ ! -z "$BR_DATABASE_USER" ] || exit_with_feedback "Environment variable BR_DATABASE_USER is not set."
}

function check_database_user_password {
	[ ! -z "$BR_DATABASE_USER_PASSWORD" ] || exit_with_feedback "Environment variable BR_DATABASE_USER_PASSWORD is not set"
}

function ey_ssh {
	echo "ssh -T -i $ENGINE_YARD_KEY ${ENGINE_YARD_RESOURCES[5.5.31]}"
}

function ey_slave_delay {
	echo "mysql -e 'show slave status\G' | grep Seconds_Behind_Master; echo"
}

function br_ssh {
	echo "ssh -T -i $BR_USER_KEY $BR_USER@$BR_EC2_INSTANCE"
}

function br_mysql {		
	echo "mysql -u$BR_DATABASE_USER -p$BR_DATABASE_USER_PASSWORD -h$1.brenv.net"
}

function replica_stack_name {
	IFS='-' read -a params_array <<< $1
	local replica_stack_name=${params_array[0]}-${params_array[1]}-mysqlreplica-${params_array[3]}
	echo $replica_stack_name
}

function rds_master_instance_id {
	echo `aws cloudformation list-stack-resources --stack-name $1 | \
	jq '.[][] | select(.ResourceType == "AWS::RDS::DBInstance") | select(.LogicalResourceId == "MasterDB") | .PhysicalResourceId' | \
	tr -d \"`
}

function rds_instance_ip_address {
	echo `host $1.brenv.net | \
	grep -o 'address [0-9.]*' | \
	tail -n 1 | \
	tr -d "address " | \
	tr -d \"`
}

function check_replication_user {
	[ ! -z "$REPLICATION_USER" ] || exit_with_feedback "Environment variable REPLICATION_USER is not set."
}

function check_replication_user_password {
	[ ! -z "$REPLICATION_USER_PASSWORD" ] || exit_with_feedback "Environment variable REPLICATION_USER_PASSWORD is not set."
}


check_bash_version

declare -A ENGINE_YARD_RESOURCES

ENGINE_YARD_RESOURCES['5.0.51']=root@ec2-54-196-184-140.compute-1.amazonaws.com
ENGINE_YARD_RESOURCES['5.1.55']=root@ec2-54-80-108-8.compute-1.amazonaws.com
ENGINE_YARD_RESOURCES['5.5.31']=root@ec2-50-17-166-153.compute-1.amazonaws.com

ENGINE_YARD_KEY=$HOME/.ssh/id_rsa-ey
EY_BINLOG=$PWD/.ey_binlog

BR_USER=deploy
BR_USER_KEY=$HOME/.ssh/id_rsa
BR_EC2_INSTANCE=prod-br-scheduler-s2.brenv.net
