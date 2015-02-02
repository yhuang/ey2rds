#!/bin/bash -e

. $PWD/lib/common.sh

function main {
    if [ $# -eq 0 ]; then
        exit_with_feedback "No stack name was specified."
    fi

    local stack_name=$1 ; shift
    
    local stack_resources=`aws cloudformation list-stack-resources --stack-name $stack_name 2>&1`
    local master_id=`echo $stack_resources | jq '[ .[][] | select(.ResourceType == "AWS::RDS::DBInstance") | select(.LogicalResourceId == "MasterDB") ]' | jq '.[].PhysicalResourceId' | tr -d \"`

    if [ ! -z "$master_id" ]; then
        local master_instance_url=`aws rds describe-db-instances --db-instance-identifier $master_id | jq '.DBInstances[].Endpoint.Address' | tr -d \"`
        local master_instance_ip=`host $master_instance_url | grep -oE 'address \S+' | awk '{print $2}'`

        echo "MasterDB"
        echo
        echo "  $master_id ($master_instance_ip)"
        echo
    fi

    local replica_stack_name=$(replica_stack_name $stack_name)
    local replica_stack_resources=`aws cloudformation list-stack-resources --stack-name $replica_stack_name 2>&1`
    local stack_resources_check=`echo $replica_stack_resources | grep -o 'does not exist'`

    local i=0
    local replica_ids

    if [[ $stack_resources_check != 'does not exist' ]]; then
        replica_ids=`echo $replica_stack_resources | jq '[ .[][] | select(.ResourceType == "AWS::RDS::DBInstance") | select(.LogicalResourceId != "MasterDB") ]' | jq '.[].PhysicalResourceId' | tr -d \"`
    else
        replica_ids=`echo $stack_resources | jq '[ .[][] | select(.ResourceType == "AWS::RDS::DBInstance") | select(.LogicalResourceId != "MasterDB") ]' | jq '.[].PhysicalResourceId' | tr -d \"`
    fi

    echo "ReplicaDB"
    echo
    for i in $replica_ids; do
        local rds_instance_url=`aws rds describe-db-instances --db-instance-identifier $i | jq '.DBInstances[].Endpoint.Address' | tr -d \"`
        local rds_instance_ip=`host $rds_instance_url | grep -oE 'address \S+' | awk '{print $2}'`
        echo "  $i ($rds_instance_ip)"
        echo
    done
}

main "$@"
