#!/bin/bash -e

. $PWD/lib/common.sh

function main {
	if [ $# -lt 2 ]; then
        exit_with_feedback "generate-templates.sh <stack_name> <num_replicas> [skip]"
    fi

	local stack_name=$1; shift
	local num_replicas=$1; shift
	local skip=$1;

	local backup
	backup=$IFS
	IFS='-'

	local stack_name_array
	read -a stack_name_array <<< "${stack_name}"
	local environment=${stack_name_array[0]}
	local application=${stack_name_array[1]}
	local role=${stack_name_array[2]}
	local stack_number=${stack_name_array[3]}

	IFS=$backup

	local base=$environment-$application-mysql

	local parameter_file="/tmp/rds_template_parameters.yml"

	if [ -z "$skip" ]; then
		cat <<EOM > $parameter_file
NumberOfReplicas: $num_replicas
Skip:
EOM
	else
		cat <<EON > $parameter_file
NumberOfReplicas: $num_replicas
Skip: $skip
EON
	fi

	if [ ! -d "templates" ]; then
		mkdir templates
	fi

	for i in $base ${base}replica; do
		echo "cfn_py_generate cfn-pyplates/${i}.py -o ${parameter_file} > templates/${i}-${stack_number}.json"
		echo
		cfn_py_generate cfn-pyplates/$i.py -o $parameter_file > templates/$i-$stack_number.json
		[[ $num_replicas < 1 ]] && break		
	done

	rm -f $parameter_file
}

main "$@"