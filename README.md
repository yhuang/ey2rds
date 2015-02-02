This series of scripts simplifies and streamlines the [process of creating new RDS bridge instances](https://github.com/br/dev/wiki/Creating-a-New-MySQL-RDS-Bridge).


###System Requirements

* GNU bash, version 4.0+
* AWS Command Line Interface (CLI), version 1.6.4 
* Python/2.7.6

All the above requirements have been [dockerized](https://registry.hub.docker.com/u/bleacher/ey2rds/dockerfile/) and [figified](https://github.com/br/ey2rds/blob/master/fig.yml), so the project's scripts may be run inside the container.


###AWS Configuration

Please make sure the AWS CLI's configuration file includes a specific profile for Engine Yard `[profile ey]`.

```
[default]
region = us-east-1
aws_access_key_id = XXXXX
aws_secret_access_key = XXXXX
output = json

[profile ey]
region = us-east-1
aws_access_key_id = XXXXX
aws_secret_access_key = XXXXX
output = json
```

###Startup Instructions

1.	Make sure the following environment variables are defined

	* `BR_DATABASE_USER`
	* `BR_DATABASE_USER_PASSWORD`
	* `REPLICATION_USER`
	* `REPLICATION_USER_PASSWORD`

2.	All the scripts in the EY2RDS project can be run from within the `composer` container, which depends on the `code` container and the `credential` container.  All three containers can be launched and linked with the help of fig.

	```
	$ fig up; fig run --rm composer /bin/bash
	Creating ey2rds_credentials_1...
	Creating ey2rds_code_1...
	Creating ey2rds_composer_1...
	Attaching to ey2rds_composer_1
	docker@2bad34f5e3bb:/app$
	```

###Example Run

1.	Check to make sure the replication chain on Engine Yard is running without delay.

	```
	$ ./bin/check-ey-chain.sh 
	MySQL 5.1.55
	    Seconds_Behind_Master: 0
	
	MySQL 5.0.51
	    Seconds_Behind_Master: 0
	
	MySQL 5.5.31
	    Seconds_Behind_Master: 0
	```

	
2.	Check to make sure the currently running RDS bridge instance is replicating from the MySQL 5.5.31 instance on Engine Yard without delay.  In this example, the RDS bridge instance is `prod-br-mysql-s1`.

	```
	$ ./bin/check-br-slave-delay.sh prod-br-mysql-s3
        Seconds_Behind_Master: 0
	```


3.	Stop replication on both the MySQL 5.5.31 instance on Engine Yard and the currently running RDS bridge instance.

	```
	$ ./bin/stop-br-replication.sh prod-br-mysql-s3; ./bin/stop-ey-replication.sh
	Determining prod-br-mysql-s3.brenv.net's RDS instance ID...

	On prod-br-mysql-s3.brenv.net (pmphxgqu6jc93y):  CALL mysql.rds_stop_replication
	Message
	Slave is down or disabled

	Seconds_Behind_Master: NULL
	On Engine Yard MySQL 5.5.31:  mysql -e 'stop slave'

	Writing /app/.ey_binlog
	```


4.	Start the database snapshot of the currently running RDS bridge instance from the local laptop using AWS CLI.

	```
	$ ./bin/create-db-snapshot.sh prod-br-mysql-s3
	Determining prod-br-mysql-s3.brenv.net's RDS instance ID...

	Creating a new database snapshot (prod-br-mysql-s3-2014-12-30-04-32) for prod-br-mysql-s3.brenv.net (pmphxgqu6jc93y)...

	{
	    "DBSnapshot": {
	        "Engine": "mysql", 
	        "Status": "creating", 
	        "AvailabilityZone": "us-east-1e", 
	        "MasterUsername": "deploy", 
	        "LicenseModel": "general-public-license", 
	        "StorageType": "gp2", 
	        "PercentProgress": 0, 
	        "DBSnapshotIdentifier": "prod-br-mysql-s3-2014-12-30-04-32", 
	        "InstanceCreateTime": "2014-11-30T23:35:14.702Z", 
	        "OptionGroupName": "default:mysql-5-6", 
	        "AllocatedStorage": 512, 
	        "EngineVersion": "5.6.19a", 
	        "SnapshotType": "manual", 
	        "Port": 3306, 
	        "DBInstanceIdentifier": "pmphxgqu6jc93y"
	    }
	}

	When the database snapshot is done:

	  $ ./bin/cfn create <new stack name> 'SnapshotId=prod-br-mysql-s3-2014-12-30-04-32;DBInstanceClass=db.r3.2xlarge'

	```


5.	Once the database snapshot of the currently running RDS bridge instance becomes available, create the new RDS bridge instance with the freshly minted database snapshot.

	```
	$ ./bin/cfn create prod-br-mysql-s2 0 'SnapshotId=prod-br-mysql-s3-2014-12-30-04-32;DBInstanceClass=db.r3.2xlarge'

	```


6.	Open the security group of the MySQL 5.5.31 instance on Engine Yard to network traffic from the new RDS bridge instance.

	```
	$ ./bin/grant-security-group-ingress.sh prod-br-mysql-s2
	Determining prod-br-mysql-s2.brenv.net's RDS instance IP Address...

	Opening Engine Yard MySQL 5.5.31's security group to prod-br-mysql-s2.brenv.net (54.163.50.36)...
	```


7.	Set the MySQL 5.5.31 instance on Engine Yard as the new RDS bridge instance's external master.

	```
	$ ./bin/set-br-ey-master.sh prod-br-mysql-s2
	Determining prod-br-mysql-s2.brenv.net's RDS instance ID...

	On prod-br-mysql-s2.brenv.net (pmlcvuj38lwl4h): CALL mysql.rds_set_external_master

        Seconds_Behind_Master: NULL
	```


8.	Restart replication on the currently running RDS bridge instance and the MySQL 5.5.31 instance on Engine Yard.

	``` 
	$ ./bin/start-br-replication.sh prod-br-mysql-s3; ./bin/start-ey-replication.sh
	On prod-br-mysql-s3.brenv.net (pmphxgqu6jc93y):  CALL mysql.rds_start_replication
	Message
	Slave running normally.
		Seconds_Behind_Master: 0
	
	On Engine Yard MySQL 5.5.31:  mysql -e 'start slave'
	
		Seconds_Behind_Master: 3221
	
	Removing previous /Users/jimmyhuang/src/ey2rds/.ey_binlog
	```
	

9.	Start replication on the newly created RDS bridge instance.

	```
	$ ./bin/start-br-replication.sh prod-br-mysql-s2
	On prod-br-mysql-s2.brenv.net (pmlcvuj38lwl4h):  CALL mysql.rds_start_replication
	Message
	Slave running normally.
        Seconds_Behind_Master: 45
    ````


10.	Obtain the new RDS bridge instance's ID.

	```
	$ ./bin/get-rds-instance-info.sh prod-br-mysql-s2
	MasterDB

	  pmlcvuj38lwl4h (54.163.50.36)

	ReplicaDB

	  pr1tkt1zrs1k7kt (54.197.216.124)

	  pr1sch9mnsf92ap (54.234.41.240)

	  prxqpbdizjv4nw (54.167.181.189)

	  pr10ociiced6hvf (54.235.63.106)

	```


####Adjust the Number of Read Replicas
	
1.	Wait for all the read replicas to catch up.

	```
	$ ./bin/all-br-slaves.sh check prod-br-mysql-s2
	prod-br-mysql-s2
	{
	  "Slave_IO_State": "Waiting for master to send event",
	  "Seconds_Behind_Master": 0,
	  "Last_SQL_Errno": 0,
	  "Last_SQL_Error": null,
	  "Last_IO_Errno": 0,
	  "Last_IO_Error": null,
	  "Master_Log_File": "master-bin.000915"
	}

	prod-br-mysql-s2-1
	{
	  "Slave_IO_State": "Waiting for master to send event",
	  "Seconds_Behind_Master": 0,
	  "Last_SQL_Errno": 0,
	  "Last_SQL_Error": null,
	  "Last_IO_Errno": 0,
	  "Last_IO_Error": null,
	  "Master_Log_File": "mysql-bin-changelog.002220"
	}

	prod-br-mysql-s2-4
	{
	  "Slave_IO_State": "Waiting for master to send event",
	  "Seconds_Behind_Master": 0,
	  "Last_SQL_Errno": 0,
	  "Last_SQL_Error": null,
	  "Last_IO_Errno": 0,
	  "Last_IO_Error": null,
	  "Master_Log_File": "mysql-bin-changelog.002166"
	}

	prod-br-mysql-s2-3
	{
	  "Slave_IO_State": "Waiting for master to send event",
	  "Seconds_Behind_Master": 0,
	  "Last_SQL_Errno": 0,
	  "Last_SQL_Error": null,
	  "Last_IO_Errno": 0,
	  "Last_IO_Error": null,
	  "Master_Log_File": "mysql-bin-changelog.002166"
	}

	prod-br-mysql-s2-2
	{
	  "Slave_IO_State": "Waiting for master to send event",
	  "Seconds_Behind_Master": 0,
	  "Last_SQL_Errno": 0,
	  "Last_SQL_Error": null,
	  "Last_IO_Errno": 0,
	  "Last_IO_Error": null,
	  "Master_Log_File": "mysql-bin-changelog.002166"
	}
	```


2.	Update the number of read replicas for a given RDS bridge instance.  In this example, the number of read replicas specified is 20.  The maximum number of read replicas per master is 10 under Bleacher Report's account on AWS.  The first 10 read replicas, or primary read replicas, will be directly attached to the RDS bridge instance, since the `add_read_replicas` method in `cfn-pyplates/rdstemplate.py` has been implemented to spin read replicas up in a breadth-first fashion.  The other 10 read replicas, or secondary read replicas, will be launched with their source database set to one of the primary read replicas.  Because secondary read replicas cannot have slaves of their own, the maximum number of read replicas per MySQL RDS stack is 110.

	```
	$ bin/cfn update prod-br-mysql-s2 20
	```
	![](https://s3.amazonaws.com/br-blog/screenshots/general/mysql-res-read-replicas.jpg)
	
	
	
	Consistent with the way read replicas are spun up in a breadth-first fashion, the EY2RDS project relies on a slave's numbering to differentiate between primary read replicas and secondary read replicas.  Below is the complete enumeration of all 110 read replicas.
	
	```
	ReplicaDB1   (primary)       ReplicaDB2   (primary)
	ReplicaDB10  (secondary)     ReplicaDB20  (secondary)
	ReplicaDB11  (secondary)     ReplicaDB21  (secondary)
	ReplicaDB12  (secondary)     ReplicaDB22  (secondary)
	ReplicaDB13  (secondary)     ReplicaDB23  (secondary)
	ReplicaDB14  (secondary)     ReplicaDB24  (secondary)
	ReplicaDB15  (secondary)     ReplicaDB25  (secondary)
	ReplicaDB16  (secondary)     ReplicaDB26  (secondary)
	ReplicaDB17  (secondary)     ReplicaDB27  (secondary)
	ReplicaDB18  (secondary)     ReplicaDB28  (secondary)
	ReplicaDB19  (secondary)     ReplicaDB29  (secondary)
	
	ReplicaDB3   (primary)       ReplicaDB4   (primary)
	ReplicaDB30  (secondary)     ReplicaDB40  (secondary)
	ReplicaDB31  (secondary)     ReplicaDB41  (secondary)
	ReplicaDB32  (secondary)     ReplicaDB42  (secondary)
	ReplicaDB33  (secondary)     ReplicaDB43  (secondary)
	ReplicaDB34  (secondary)     ReplicaDB44  (secondary)
	ReplicaDB35  (secondary)     ReplicaDB45  (secondary)
	ReplicaDB36  (secondary)     ReplicaDB46  (secondary)
	ReplicaDB37  (secondary)     ReplicaDB47  (secondary)
	ReplicaDB38  (secondary)     ReplicaDB48  (secondary)
	ReplicaDB39  (secondary)     ReplicaDB49  (secondary)
	
	ReplicaDB5   (primary)       ReplicaDB6   (primary)
	ReplicaDB50  (secondary)     ReplicaDB60  (secondary)
	ReplicaDB51  (secondary)     ReplicaDB61  (secondary)
	ReplicaDB52  (secondary)     ReplicaDB62  (secondary)
	ReplicaDB53  (secondary)     ReplicaDB63  (secondary)
	ReplicaDB54  (secondary)     ReplicaDB64  (secondary)
	ReplicaDB55  (secondary)     ReplicaDB65  (secondary)
	ReplicaDB56  (secondary)     ReplicaDB66  (secondary)
	ReplicaDB57  (secondary)     ReplicaDB67  (secondary)
	ReplicaDB58  (secondary)     ReplicaDB68  (secondary)
	ReplicaDB59  (secondary)     ReplicaDB69  (secondary)
	
	ReplicaDB7   (primary)       ReplicaDB8   (primary)
	ReplicaDB70  (secondary)     ReplicaDB80  (secondary)
	ReplicaDB71  (secondary)     ReplicaDB81  (secondary)
	ReplicaDB72  (secondary)     ReplicaDB82  (secondary)
	ReplicaDB73  (secondary)     ReplicaDB83  (secondary)
	ReplicaDB74  (secondary)     ReplicaDB84  (secondary)
	ReplicaDB75  (secondary)     ReplicaDB85  (secondary)
	ReplicaDB76  (secondary)     ReplicaDB86  (secondary)
	ReplicaDB77  (secondary)     ReplicaDB87  (secondary)
	ReplicaDB78  (secondary)     ReplicaDB88  (secondary)
	ReplicaDB79  (secondary)     ReplicaDB89  (secondary)
	
	ReplicaDB9   (primary)       ReplicaDB0   (primary)
	ReplicaDB90  (secondary)     ReplicaDB100 (secondary)
	ReplicaDB91  (secondary)     ReplicaDB101 (secondary)
	ReplicaDB92  (secondary)     ReplicaDB102 (secondary)
	ReplicaDB93  (secondary)     ReplicaDB103 (secondary)
	ReplicaDB94  (secondary)     ReplicaDB104 (secondary)
	ReplicaDB95  (secondary)     ReplicaDB105 (secondary)
	ReplicaDB96  (secondary)     ReplicaDB106 (secondary)
	ReplicaDB97  (secondary)     ReplicaDB107 (secondary)
	ReplicaDB98  (secondary)     ReplicaDB108 (secondary)
	ReplicaDB99  (secondary)     ReplicaDB109 (secondary)
	```
	
####Fix RDS Bridge Instance Replication Delay

Until Bleacher Report can completely migrate its database tier from Engine Yard to MySQL RDS, any RDS bridge instance launched will have to set its external master to the MySQL 5.5.31 instance on Engine Yard.  By default RDS bridge instances are created with `sync_binlog` set to `true` in order to reduce the occurrence of `fatal error 1236` after a Multi-AZ failover on the RDS bridge instance.

Setting `sync_binlog` to `true` may slow down replcation from the MySQL 5.5.31 instance on Engine Yard to the MySQL RDS bridge instance.  To help the RDS bridge instance catch up, try changing `sync_binlog` to `false`.

1.	Check slave delay.

	```
	$ ./bin/check-br-slave-delay.sh prod-br-mysql-s3
	prod-br-mysql-s3
	        Seconds_Behind_Master: 123130
	```
	
2.	Verify the `sync_binlog` setting is `true` or `1`.

	```
	$ ./bin/get-sync-binlog.sh prod-br-mysql-s3
	Looking up sync_binlog for prod-br-mysql-s3...
	{
	  "Description": "Sync binlog (MySQL flush to disk or rely on OS)",
	  "DataType": "integer",
	  "IsModifiable": true,
	  "AllowedValues": "0-18446744073709547520",
	  "Source": "user",
	  "ParameterValue": "1",
	  "ParameterName": "sync_binlog",
	  "ApplyType": "dynamic"
	}
	```
	
3.	Set `sync_binlog` for prod-br-mysql-s3's RDS bridge instance to `false` or `0`.

	```
	$ ./bin/set-sync-binlog.sh prod-br-mysql-s3 false
	Setting sync_binlog for prod-br-mysql-s3 to 0...
	{
	    "DBParameterGroupName": "prod-br-mysql-s3-dbparametergroup-iqkvuog41jfw"
	}
	```
	
4.	Verify the `sync_binlog` setting is `false` or `0`.

	```
	$ ./bin/get-sync-binlog.sh prod-br-mysql-s3
	Looking up sync_binlog for prod-br-mysql-s3...
	{
	  "Description": "Sync binlog (MySQL flush to disk or rely on OS)",
	  "DataType": "integer",
	  "IsModifiable": true,
	  "AllowedValues": "0-18446744073709547520",
	  "Source": "user",
	  "ParameterValue": "0",
	  "ParameterName": "sync_binlog",
	  "ApplyType": "dynamic"
	}
	```
		
####MySQL RDS Stack Update Policy

The MySQL RDS CloudFormation stack is created with a specific stack update policy `config/stack_update_policy.json`.  This policy ensures that the RDS bridge instance will NOT be replaced during a stack update operation to scale up or scale down read replicas.

```
{
  "Statement" : [
    {
      "Effect" : "Deny",
      "Action" : "Update:Replace",
      "Principal": "*",
      "Resource" : "LogicalResourceId/MasterDB*"
    },
    {
      "Effect" : "Allow",
      "Action" : "Update:*",
      "Principal": "*",
      "Resource" : "*"
    }
  ]
}
```