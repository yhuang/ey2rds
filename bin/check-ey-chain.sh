#!/bin/bash -e

. $PWD/lib/common.sh

function main {
	local i=''	
	for i in "${!ENGINE_YARD_RESOURCES[@]}"; do
		echo "MySQL $i"
		$(ey_ssh) $(ey_slave_delay)
	done
}

main "$@"