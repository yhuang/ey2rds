#!/bin/bash -e

. $PWD/lib/common.sh

function main {
    if [ $# -lt 2 ]; then
        exit_with_feedback "update-stack-policy.sh <update|clear> <stack_name>"
    fi

	local action=$1; shift
    local stack_name=$1 ; shift

    local stack_policy
    case "$action" in
      update)
		echo
		echo "Revising stack update policy..."
		echo

        stack_policy=stack_update_policy.json
        ;;
      clear)
		echo
		echo "Setting stack policy to default..."
		echo

        stack_policy=default_stack_update_policy.json
        ;;
      *)
        exit_with_feedback "update-stack-policy.sh <update|clear> <stack_name>"
        ;;
    esac

	aws cloudformation set-stack-policy \
	--stack-name $stack_name \
	--stack-policy-body file://$PWD/config/$stack_policy
}

main "$@"

