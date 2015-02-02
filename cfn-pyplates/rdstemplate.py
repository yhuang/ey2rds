import random
import re
import string
from cfn_pyplates import core, functions

class RDSTemplate(core.CloudFormationTemplate):
	def get_topic_name(self):
		return "AlarmTopic%s" % ''.join([random.choice(string.ascii_uppercase + string.digits) for n in xrange(8)])

	def add_conditions(self):
		self.conditions.add(
			core.Condition(
				"UseDBSnapshot", {
					"Fn::Not": [
						{
							"Fn::Equals": [
								"",
								functions.ref("SnapshotId")
							]
						}
					]
				}
			)
		)


	def add_parameters(self):
		self.parameters.add(
			core.Parameter(
				"Application", "String",
				{
					"Description": "application name",
					"Default": "br"
				}	
			)	
		)

		self.parameters.add(
			core.Parameter(
				"DBAllocatedStorage", "Number",
				{
					"Description": "database size (GB)",
					"Default": "512",
					"ConstraintDescription": "must be between 50GB and 3072GB",
					"MaxValue": "2048",
					"MinValue": "64"
				}	
			)	
		)

		self.parameters.add(
			core.Parameter(
				"DBInstanceClass", "String",
				{
					"Description": "database instance type",
					"Default": "db.r3.2xlarge",
					"ConstraintDescription": "must select a valid database instance type",
					"AllowedValues": self.__allowed_instance_classes()
				}	
			)	
		)

		self.parameters.add(
			core.Parameter(
				"DBName", "String",
				{
					"Description": "database name",
					"Default": "bleacherreport_production",
					"ConstraintDescription": "must begin with a letter and contain only alphanumeric characters",
					"AllowedPattern": "[a-zA-Z][a-zA-Z0-9_]*",
					"MaxLength": "64",
					"MinLength": "5"
				}	
			)	
		)

		self.parameters.add(
			core.Parameter(
				"DBUser", "String",
				{
					"Description": "database administrator account",
					"Default": "deploy",
					"ConstraintDescription": "must begin with a letter and contain only alphanumeric characters",
					"AllowedPattern": "[a-zA-Z][a-zA-Z0-9_]*",
					"NoEcho": "true",
					"MaxLength": "16",
					"MinLength": "6"
		    	}	
			)	
		)

		self.parameters.add(
			core.Parameter(
				"DBPassword", "String",
				{
					"Description": "database administrator password",
					"ConstraintDescription": "must contain only alphanumeric characters",
					"AllowedPattern": "[a-zA-Z0-9_]*",
					"NoEcho": "true",
					"MaxLength": "64",
					"MinLength": "10"
				}	
			)	
		)

		self.parameters.add(
			core.Parameter(
				"Environment", "String",
				{
					"Description": "application environment",
					"Default": "prod",
				}	
			)	
		)

		self.parameters.add(
			core.Parameter(
				"StackNumber", "String",
				{
					"Description": "s1, s2, s3, etc"
				}		
			)
		)

		self.parameters.add(
			core.Parameter(
				"SnapshotId", "String",
				{
					"Description": "snapshot to use as restore point",
					"Default": ""
				}
			)
		)


	def add_db_parameters(self):
		self.resources.add(
			core.Resource(
				"DBParameterGroup",
				"AWS::RDS::DBParameterGroup",
				{
					"Description": functions.ref("AWS::StackName"),
					"Family": "mysql5.6",
					"Parameters": {
						"explicit_defaults_for_timestamp": 0,
						"innodb_buffer_pool_dump_at_shutdown": 1,
						"innodb_buffer_pool_load_at_startup": 1,
						"innodb_flush_log_at_trx_commit": 2,
						"log_output": "FILE",
						"long_query_time": 0.5,
						"max_allowed_packet": 33554432,
						"performance_schema": 1,
						"slave_parallel_workers": 0,
						"slow_query_log": 1,
						"sync_binlog": 1,
						"sync_master_info": 0,
						"sync_relay_log": 0,
						"sync_relay_log_info": 0
					},
					"Tags": [
						{
							"Key": "Name",
							"Value": functions.ref("AWS::StackName")
						}
					]
				}
			)
		)

	def add_sns_topic(self, topic_name):
		self.resources.add(
			core.Resource(
				topic_name,
				"AWS::SNS::Topic",
				{
					"DisplayName": functions.ref("AWS::StackName"),
					"Subscription": [
						{
							"Endpoint": "jhuang@bleacherreport.com",
							"Protocol": "email"
						}
					]
				}	
			)	
		)

	def add_master(self, topic_name):
		self.resources.add(
			core.Resource(
				"MasterDB",
				"AWS::RDS::DBInstance",		
				{
					"Engine": "mysql",
					"EngineVersion": "5.6",
					"MasterUsername": functions.ref("DBUser"),
					"MasterUserPassword": functions.ref("DBPassword"),
					"AllowMajorVersionUpgrade": "true",
					"BackupRetentionPeriod": 1,
					"MultiAZ": "true",
					"DBInstanceClass": functions.ref("DBInstanceClass"),
					"DBParameterGroupName": functions.ref("DBParameterGroup"),
					"DBSecurityGroups": [
						"global",
						functions.join(
							"-",
							functions.ref("Environment"),
							functions.ref("Application")
						)
					],
					"DBName": {
						"Fn::If": [
							"UseDBSnapshot",
							functions.ref("AWS::NoValue"),
							functions.ref("DBName")

						]
					},
					"DBSnapshotIdentifier": {
						"Fn::If": [
							"UseDBSnapshot",
							functions.ref("SnapshotId"),
							functions.ref("AWS::NoValue")
						]
					},
					"AllocatedStorage": {
						"Fn::If": [
							"UseDBSnapshot",
							functions.ref("AWS::NoValue"),
							functions.ref("DBAllocatedStorage")
						]
					},
					"StorageType": "gp2",
					"Tags": [
						{
							"Key": "Name",
							"Value": functions.ref("AWS::StackName")
						}
					]
				},
				core.DeletionPolicy("Delete")
			)
		)

		self.resources.add(
			core.Resource(
				"MasterDBHostRecord",
				"AWS::Route53::RecordSet",
				{
					"Comment": "DNS name for the RDS master",
					"HostedZoneName": "%s." % self.__hosted_zone_name(),
					"Name": functions.join(
						"",
						functions.ref("AWS::StackName"),
						".%s" % self.__hosted_zone_name()
					),
					"ResourceRecords": [
						functions.get_att(
							"MasterDB",
							"Endpoint.Address"
						)
					],
					"TTL": "30",
					"Type": "CNAME"
				}
			)
		)

		self.__add_alarms("MasterDB", topic_name)

		self.outputs.add(
			core.Output(
				"MasterDBHostname",
				functions.join(
					"",
					functions.ref("AWS::StackName"),
					".%s" % self.__hosted_zone_name()
				),
				"Hostname for the RDS Master Server"
			)
		)

	def add_read_replias(self, n, topic_name, skip=None):
		for i in range(0, n):
			if skip is not None:
				secondary_id = i / self.__replicas_per_master()
				if (i == skip) or (secondary_id == skip) or (secondary_id - skip == 10):
					continue
			replica_name = "ReplicaDB%d" % i
			read_replica_id = functions.join(
				"",
				functions.ref("AWS::StackName"),
				"-%d" % i
			)
			read_replica_host_name = functions.join(
				"",
				read_replica_id,
				".%s" % self.__hosted_zone_name()
			)
			self.resources.add(
				core.Resource(
					replica_name,
					"AWS::RDS::DBInstance",
					{
						"BackupRetentionPeriod": 1,
						"DBInstanceClass": functions.ref("DBInstanceClass"),
						"DBParameterGroupName": functions.ref("DBParameterGroup"),
						"SourceDBInstanceIdentifier": functions.ref(self.__source_db(i)),
						"StorageType": "gp2",
						"Tags": [
							{
								"Key": "Name",
								"Value": functions.ref("AWS::StackName")
							}
						]
					}
				)
			)

			self.resources.add(
				core.Resource(
					"%sHostRecord" % replica_name,
					"AWS::Route53::RecordSet",
					{
						"Comment": "DNS name for RDS read replica %d" % i,
						"HostedZoneName": "%s." % self.__hosted_zone_name(),
						"Name": read_replica_host_name,
						"ResourceRecords": [
							functions.get_att(
								"ReplicaDB%d" % i,
								"Endpoint.Address"
							)
						],
						"TTL": "30",
						"Type": "CNAME"
					}
				)
			)

			self.__add_alarms("ReplicaDB%d" % i, topic_name)

			self.outputs.add(
				core.Output(
					"%sHostname" % replica_name,
					read_replica_host_name,
					"Hostname for Mysql RDS Read Replica %d Server" % i
				)
			)

	# Private Methods
	def __replicas_per_master(self):
		return 10

	def __hosted_zone_name(self):
		return "brenv.net"

	def __allowed_instance_classes(self):
		return [
			"db.t2.micro",
			"db.t2.small",
			"db.t2.medium",
			"db.m3.medium",
			"db.m3.large",
			"db.m3.xlarge",
			"db.m3.2xlarge",
			"db.r3.large",
			"db.r3.xlarge",
			"db.r3.2xlarge",
			"db.r3.4xlarge",
			"db.r3.8xlarge"
		]

	def __limit_map(self):
		return {
			"CPULimit": 60,
			"ReadIOPSLimit": 1500,
			"WriteIOPSLimit": 1500,
			"ReplicaLagLimit": 10800,
			"FreeStorageSpaceLimit": 64000000000
		}

	def __source_db(self, i):
		if i < self.__replicas_per_master():
			return "MasterDB"
		elif i >= 100:
			return "ReplicaDB0"
		else:
			return "ReplicaDB%d" % (i / self.__replicas_per_master())
			
	def __add_alarms(self, name, topic_name):
		self.resources.add(
			core.Resource(
				"%sCPUAlarmHigh" % name,
				"AWS::CloudWatch::Alarm",
				{
					"AlarmActions": [
						functions.ref(topic_name)
					],
					"AlarmDescription": functions.join(
						"",
						"Alarm if ",
						functions.ref(name),
						" CPU > ",
						self.__limit_map()["CPULimit"],
						"% for 5 minutes"
						),
					"ComparisonOperator": "GreaterThanThreshold",
					"Dimensions": [
						{
							"Name": "DBInstanceIdentifier",
							"Value": functions.ref(name)
						}
					],
					"EvaluationPeriods": "5",
					"MetricName": "CPUUtilization",
					"Namespace": "AWS/RDS",
					"Period": "60",
					"Statistic": "Average",
					"Threshold": self.__limit_map()["CPULimit"]
				}
			)
		)

		self.resources.add(
			core.Resource(
				"%sReadIOPSHigh" % name,
				"AWS::CloudWatch::Alarm",
				{
					"AlarmActions": [
						functions.ref(topic_name)
					],
					"AlarmDescription": functions.join(
						"",
						"Alarm if ",
						functions.ref(name),
						" ReadIOPS > ",
						self.__limit_map()["ReadIOPSLimit"],
						" IOPS for 5 minutes"
					),
					"ComparisonOperator": "GreaterThanThreshold",
					"Dimensions": [
						{
							"Name": "DBInstanceIdentifier",
							"Value": functions.ref(name)
						}
					],
					"EvaluationPeriods": "5",
					"MetricName": "ReadIOPS",
					"Namespace": "AWS/RDS",
					"Period": "60",
					"Statistic": "Average",
					"Threshold": self.__limit_map()["ReadIOPSLimit"]
				}
			)
		)

		self.resources.add(
			core.Resource(
				"%sWriteIOPSHigh" % name,
				"AWS::CloudWatch::Alarm",
				{
					"AlarmActions": [
						functions.ref(topic_name)
					],
					"AlarmDescription": functions.join(
						"",
						"Alarm if ",
						functions.ref(name),
						" WriteIOPS > ",
						self.__limit_map()["WriteIOPSLimit"],
						" IOPS for 5 minutes"
					),
					"ComparisonOperator": "GreaterThanThreshold",
					"Dimensions": [
						{
							"Name": "DBInstanceIdentifier",
							"Value": functions.ref(name)
						}
					],
					"EvaluationPeriods": "5",
					"MetricName": "WriteIOPS",
					"Namespace": "AWS/RDS",
					"Period": "60",
					"Statistic": "Average",
					"Threshold": self.__limit_map()["WriteIOPSLimit"]
				}
			)
		)

		self.resources.add(
			core.Resource(
				"%sFreeStorageSpaceLow" % name,
				"AWS::CloudWatch::Alarm",
				{
					"AlarmActions": [
						functions.ref(topic_name)
					],
					"AlarmDescription": functions.join(
						"",
						"Alarm if ",
						functions.ref(name),
						" storage space <= ",
						self.__limit_map()["FreeStorageSpaceLimit"],
						" bytes for 5 minutes"
					),
					"ComparisonOperator": "LessThanOrEqualToThreshold",
					"Dimensions": [
						{
							"Name": "DBInstanceIdentifier",
							"Value": functions.ref(name)
						}
					],
					"EvaluationPeriods": "5",
					"MetricName": "FreeStorageSpace",
					"Namespace": "AWS/RDS",
					"Period": "60",
					"Statistic": "Average",
					"Threshold": self.__limit_map()["FreeStorageSpaceLimit"]
				}
			)
		)

		pattern = re.compile(r'replica', re.IGNORECASE)

		if pattern.match(name):
			self.resources.add(
				core.Resource(
					"%sReplicaLagHigh" % name,
					"AWS::CloudWatch::Alarm",
					{
						"AlarmActions": [
							functions.ref(topic_name)
						],
						"AlarmDescription": functions.join(
							"",
							"Alarm if ",
							functions.ref(name),
							" lag >= ",
							self.__limit_map()["ReplicaLagLimit"],
							" seconds for 5 minutes"
						),
						"ComparisonOperator": "GreaterThanOrEqualToThreshold",
						"Dimensions": [
							{
								"Name": "DBInstanceIdentifier",
								"Value": functions.ref(name)
							}
						],
						"EvaluationPeriods": "5",
						"MetricName": "ReplicaLag",
						"Namespace": "AWS/RDS",
						"Period": "60",
						"Statistic": "Average",
						"Threshold": self.__limit_map()["ReplicaLagLimit"]
					}
				)
			)