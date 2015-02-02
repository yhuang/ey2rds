#!/bin/bash -e

. $PWD/lib/common.sh

function main {
	local start_slave="mysql -e 'start slave'"

	echo "On Engine Yard MySQL 5.5.31:  $start_slave"
	echo
	$(ey_ssh) $start_slave

	if [ -e $EY_BINLOG ]; then
		echo "Removing previous $EY_BINLOG..."
		echo
		rm $EY_BINLOG
	fi
}

main "$@"