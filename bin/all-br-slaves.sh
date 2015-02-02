#!/bin/bash -e

. $PWD/lib/common.sh

function main {
    if [ $# -lt 2 ]; then
        exit_with_feedback "all-br-slaves.sh <check|fix> <stack_name>"
    fi

	local action=$1; shift
    local stack_name=$1 ; shift

    local script
    case "$action" in
      fix)
        script=$PWD/bin/fix-br-replication-error.sh
        ;;
      check)
        script=$PWD/bin/check-br-slave-status.sh
        ;;
      *)
        exit_with_feedback "all-br-slaves.sh <check|fix> <stack_name>"
        ;;
    esac

    local host_check=`host $stack_name.brenv.net 2>&1 | grep -o 'not found'`

    if [[ $host_check != 'not found' ]]; then
        $script $stack_name &
	fi

    local replica_stack_name=$(replica_stack_name $stack_name)

    local replica_stack_resources=`aws cloudformation list-stack-resources --stack-name $replica_stack_name 2>&1`
    local replica_stack_resources_check=`echo $replica_stack_resources | grep -o 'does not exist'`

    local i=0
    local replica_count

    if [[ $replica_stack_resources_check != 'does not exist' ]]; then
        replica_count=`echo $replica_stack_resources | jq '[ .[][] | select(.ResourceType == "AWS::RDS::DBInstance") ] | length'`
    else
        local stack_resources=`aws cloudformation list-stack-resources --stack-name $stack_name 2>&1`
        local stack_resources_check=`echo $stack_resources | grep -o 'does not exist'`

        if [[ $stack_resources_check == 'does not exist' ]]; then
            exit_with_feedback "$stack_name does not exist."
        fi

        replica_stack_name=$stack_name
        replica_count=`echo $stack_resources | jq '[ .[][] | select(.ResourceType == "AWS::RDS::DBInstance") ] | length'`
        let replica_count=replica_count-1
    fi

    while [[ $i -lt $replica_count ]]; do
        $script $replica_stack_name-$i &
        let i=i+1 
    done

    wait
}

main "$@"