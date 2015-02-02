#!/bin/bash -e

. $PWD/lib/common.sh

function main {
	local stop_slave="mysql -e 'stop slave'"

	echo "On Engine Yard MySQL 5.5.31:  $stop_slave"
	echo
	$(ey_ssh) $stop_slave

	sleep 3

	local master_status="mysql -e 'show master status' | grep bin"

	echo "Writing $EY_BINLOG"
	echo
	$(ey_ssh) $master_status > $EY_BINLOG
}

main "$@"