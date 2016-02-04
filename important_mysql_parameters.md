###Important MySQL Parameters

1.	`innodb_support_xa = ON`

	Enables InnoDB support for two-phase commit in distributed transactions (XA transactions), causing an extra disk flush for transaction preparation. This setting is the default.  The XA mechanism is used internally and is essential for any server that has its binary log turned on and is accepting changes to its data from more than one thread.  If you turn it off, transactions can be written to the binary log in a different order from the one in which the live database is committing them.  As a result, the replication slave may end up having different data when the binary log is replayed. Do not turn it off on a replication master server unless you have an unusual setup where only one thread is able to change data.

2.	`innodb_flush_log_at_trx_commit = 2`

	If the value of `innodb_flush_log_at_trx_commit` is 0, the log buffer is written out to the log file once per second and the flush to disk operation is performed on the log file, but nothing is done at a transaction commit.  When the value is the default value of 1, the log buffer is written out to the log file at each transaction commit and the flush to disk operation is performed on the log file.  When the value is 2, the log buffer is written out to the file at each commit, but the flush to disk operation is not performed on it.  The flushing on the log file, instead, takes place once per second when the value is 2.  The once-per-second flushing, however, is not guaranteed to happen every second, due to process scheduling issues.
	
	The default value of 1 is required for full ACID compliance.  You can achieve better performance by setting the value to something other than 1, but that change can result in the loss of one second worth's of transactions in a crash.  With a value of 0, any mysqld process crash can erase the last second of transactions.  With a value of 2, only an operating system crash or a power outage can erase the last second of transactions.  InnoDB's crash recovery works regardless of the value.

3.	`sync_binlog = 0`

	If the value of this variable is greater than 0, the MySQL server synchronizes its binary log to disk (using `fdatasync()`) after every sync_binlog writes to the binary log. There is one write to the binary log per statement if autocommit is enabled, and one write per transaction otherwise. The default value of sync_binlog is 0, which does no synchronizing to disk—in this case, the server relies on the operating system to flush the binary log's contents from time to time as for any other file. A value of 1 is the safest choice because in the event of a crash you lose at most one statement or transaction from the binary log. However, it is also the slowest choice (unless the disk has a battery-backed cache, which makes synchronization very fast).

4.	`sync_master_info = 0`

	The effects of this variable on a replication slave depend on whether the slave's `master_info_repository` is set to `FILE` or `TABLE`, as explained in the following paragraphs.
	
	`master_info_repository = FILE`.  If the value of `sync_master_info` is greater than 0, the slave synchronizes its `master.info` file to disk (using `fdatasync()`) after every `sync_master_info` event.  If the value of `sync_master_info` is 0, the MySQL server performs no synchronization of the `master.info` file to disk; instead, the server relies on the operating system to flush its contents periodically as with any other file.
	
	`master_info_repository = TABLE`.  If the value of `sync_master_info` is greater than 0, the slave updates its master info repository table after every `sync_master_info` event.  If the value of `sync_master_info` is 0, the table is never updated.
	
	The default value for `sync_master_info` is 10000 as of MySQL 5.6.6, 0 before that.
	
	```
	mysql> SHOW global VARIABLES like "master_info_repository";
	+------------------------+-------+
	| Variable_name          | Value |
	+------------------------+-------+
	| master_info_repository | TABLE |
	+------------------------+-------+
	1 row in set (0.00 sec)	
	```
	
5.	`sync_relay_log = 0`

	If the value of this variable is greater than 0, the MySQL server synchronizes its relay log to disk (using `fdatasync()`) after every `sync_relay_log` event is written to the relay log.

	Setting `sync_relay_log` to 0 causes no synchronization to be done to disk; in this case, the server relies on the operating system to flush the relay log's contents from time to time as for any other file.

	Prior to MySQL 5.6.6, 0 was the default for this variable. In MySQL 5.6. and later, the default is 10000.

	A value of 1 is the safest choice because in the event of a crash you lose at most one event from the relay log; however, it is also the slowest option (unless the disk has a battery-backed cache, which makes synchronization very fast).
	
6.	`sync_relay_log_info = 0`

	The effects of this variable on the slave depend on the server's `relay_log_info_repository` setting (`FILE` or `TABLE`).  If the value of `relay_log_info_repository` is `TABLE`, the storage engine used by the relay log info table (InnoDB or MyISAM) has additional impact on the server's behavior.
	
	```
	mysql> SHOW global VARIABLES like "relay_log_info_repository";
	+---------------------------+-------+
	| Variable_name             | Value |
	+---------------------------+-------+
	| relay_log_info_repository | TABLE |
	+---------------------------+-------+
	1 row in set (0.00 sec)
	
	mysql> SHOW global VARIABLES like "storage_engine";
	+----------------+--------+
	| Variable_name  | Value  |
	+----------------+--------+
	| storage_engine | InnoDB |
	+----------------+--------+
	1 row in set (0.00 sec)
	```
	
	For the read replica servers Bleacher Report will be spinning up, the relay log info table is transactional, which means the table will be updated after each transaction.
	
7.	`performance_schema = 1`

	The Performance Schema is intended to provide access to useful information about server execution while having minimal impact on server performance.  The value of this variable is ON or OFF to indicate whether the Performance Schema is enabled.  By default, the value is ON as of MySQL 5.6.6 and OFF before that.  At server startup, you can specify this variable with no value or a value of ON or 1 to enable it, or with a value of OFF or 0 to disable it.
	
8.	`long_query_time = 0.5; slow_query_log  = 1`

	These two settings tell the server to log slow queries that take longer than half a second to execute.
	
9.	`slave_parallel_workers = 0`

	This option sets the number of slave worker threads for executing replication events (transactions) in parallel.  Setting this variable to the default value of 0 disables parallel execution. The maximum is 1024.

	When parallel execution is enabled, the slave SQL thread acts as the coordinator for the slave worker threads, among which transactions are distributed on a per-database basis. This means that a worker thread on the slave slave can process successive transactions on a given database without waiting for updates to other databases to complete. The current implementation of multi-threading on the slave assumes that the data is partitioned per database, and that updates within a given database occur in the same relative order as they do on the master, in order to work correctly. However, transactions do not need to be coordinated between any two databases.
	
10.	`explicit_defaults_for_timestamp = 0`

	When replicating from MySQL 5.5 to MySQL 5.6, thrads on [StackOverflow](http://stackoverflow.com/questions/21911557/mysql-5-5-5-6-default-values) and [StackExchange](http://dba.stackexchange.com/questions/78095/mysql-5-6-explicit-defaults-for-timestamp) recommend turning `explicit_defaults_for_timestamp` off.
	
11.	`innodb_buffer_pool_dump_at_shutdown = 1`

	This option specifies whether to record the pages cached in the InnoDB buffer pool when the MySQL server is shut down, so the warmup process at the next restart may be shortened.  This setting is typically used in conjunction with `innodb_buffer_pool_load_at_startup`.

12.	`innodb_buffer_pool_load_at_startup = 1`

	This option specifies that, on MySQL server startup, the InnoDB buffer pool is automatically warmed up by loading the same pages it held at an earlier time.  This setting is typically used in conjunction with `innodb_buffer_pool_dump_at_shutdown` for faster restart.
	
13.	`max_allowed_packet = 33554432`

	The maximum size in bytes of one packet or any generated/intermediate string.  `max_allowed_packet` must be increased if database tables contain large BLOB columns or long strings.  The protocol limit for `max_allowed_packet` is 1G.  Specified in multiples of 1024, `max_allowed_packet` is set to 32MB.
	
14.	`log_output = FILE`

	The destination for general query log and slow query log output.  The value can be a comma-separated list of one or more of the words TABLE (log to tables), FILE (log to files), or NONE (do not log to tables or files).  The default value is FILE. NONE, if present, takes precedence over any other specifiers.  If the value is NONE log entries are not written even if the logs are enabled.  If the logs are not enabled, no logging occurs even if the value of log_output is not NONE.
