SparkleFormation.dynamic(:replica) do |_name, _config={}|

  resources(_config[:replica_name]) do
    type "AWS::RDS::DBInstance"
    properties do
      backup_retention_period 1
      db_instance_class ref!(:db_instance_class)
      db_parameter_group_name ref!(:db_parameter_group)
      source_db_instance_identifier 
      storage_type "gp2"
      tags _array(
        -> {
          key "Name"
          value ref!("AWS::StackName")
        }
      )
    end
  end
end

	# def add_read_replias(self, n, topic_name, skip=None):
	# 	for i in range(0, n):
	# 		if skip is not None:
	# 			if (i == skip) or (i / self.__replicas_per_master() == skip):
	# 				continue
	# 		replica_name = "ReplicaDB%d" % i
	# 		read_replica_id = functions.join(
	# 			"",
	# 			functions.ref("AWS::StackName"),
	# 			"-%d" % i
	# 		)
	# 		read_replica_host_name = functions.join(
	# 			"",
	# 			read_replica_id,
	# 			".%s" % self.__hosted_zone_name()
	# 		)

	# 		self.resources.add(
	# 			core.Resource(
	# 				replica_name,
	# 				"AWS::RDS::DBInstance",
	# 				{
	# 					"BackupRetentionPeriod": 1,
	# 					"DBInstanceClass": functions.ref("DBInstanceClass"),
	# 					"DBParameterGroupName": functions.ref("DBParameterGroup"),
	# 					"SourceDBInstanceIdentifier": functions.ref(self.__source_db(i)),
	# 					"StorageType": "gp2",
	# 					"Tags": [
	# 						{
	# 							"Key": "Name",
	# 							"Value": functions.ref("AWS::StackName")
	# 						}
	# 					]
	# 				}
	# 			)
	# 		)

	# 		self.resources.add(
	# 			core.Resource(
	# 				"%sHostRecord" % replica_name,
	# 				"AWS::Route53::RecordSet",
	# 				{
	# 					"Comment": "DNS name for RDS read replica %d" % i,
	# 					"HostedZoneName": "%s." % self.__hosted_zone_name(),
	# 					"Name": read_replica_host_name,
	# 					"ResourceRecords": [
	# 						functions.get_att(
	# 							"ReplicaDB%d" % i,
	# 							"Endpoint.Address"
	# 						)
	# 					],
	# 					"TTL": "30",
	# 					"Type": "CNAME"
	# 				}
	# 			)
	# 		)

	# 		self.__add_alarms("ReplicaDB%d" % i, topic_name)

	# 		self.outputs.add(
	# 			core.Output(
	# 				"%sHostname" % replica_name,
	# 				read_replica_host_name,
	# 				"Hostname for Mysql RDS Read Replica %d Server" % i
	# 			)
	# 		)