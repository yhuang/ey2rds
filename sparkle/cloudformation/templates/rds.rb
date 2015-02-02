hosted_zone_name = "brenv.net"
 
SparkleFormation.new(:rds) do
 
  description "MySQL RDS Master + Read Replicas"
 
  parameters.application do
    type "String"
    description "application name"
    default "br"
  end
 
  parameters.db_allocated_storage do
    type "Number"
    description "database size (GB)"
    default 512
    constraint_description "must be between 50GB and 3072GB"
    max_value 2048
    min_value 64
  end
 
  parameters.db_instance_class do
    type "String"
    description "database instance type"
    default "db.r3.2xlarge"
    constraint_description "must select a valid database instance type"
    allowed_values %w(
      db.t2.micro
      db.t2.small
      db.t2.medium
      db.m3.medium
      db.m3.large
      db.m3.xlarge
      db.m3.2xlarge
      db.r3.large
      db.r3.xlarge
      db.r3.2xlarge
      db.r3.4xlarge
      db.r3.8xlarge
    )
  end
 
  parameters.db_name do
    type "String"
    description "database name"
    default "bleacherreport_production"
    constraint_description "must begin with a letter and contain only alphanumeric characters"
    allowed_pattern "[a-zA-Z][a-zA-Z0-9_]*"
    max_length 64
    min_length 5
  end
 
  parameters.db_user do
    type "String"
    description "database administrator account"
    default "deploy"
    constraint_description "must begin with a letter and contain only alphanumeric characters"
    allowed_pattern "[a-zA-Z][a-zA-Z0-9_]*"
    no_echo true
    max_length 16
    min_length 6
  end
 
  parameters.db_password do
    type "String"
    description "database administrator password"
    constraint_description "must contain only alphanumeric characters"
    allowed_pattern "[a-zA-Z0-9_]*"
    no_echo true
    max_length 64
    min_length 10
  end
 
  parameters.environment do
    type "String"
    description "application environment"
    default "prod"
  end
 
  parameters.stack_number do
    type "String"
    description "s1, s2, s3, etc"
  end
 
  parameters.snapshot_id do
    type "String"
    description "snapshot to use as restore point"
    default ""
  end
 
  resources.db_parameter_group do
    type "AWS::RDS::DBParameterGroup"
    properties do
      description ref!("AWS::StackName")
      family "mysql5.6"
      parameters do
        explicit_defaults_for_timestamp 0
        innodb_buffer_pool_dump_at_shutdown 1
        innodb_buffer_pool_load_at_startup 1
        innodb_flush_log_at_trx_commit 2
        log_output "FILE"
        long_query_time 0.5
        max_allowed_packet 33554432
        performance_schema 1
        slave_parallel_workers 0
        slow_query_log 1
        sync_binlog 1
        sync_master_info 0
        sync_relay_log 0
        sync_relay_log_info 0
      end
      tags _array(
        -> {
          key "Name"
          value ref!("AWS::StackName")
        }
      )
    end
  end
 
  dynamic!(
    :alarms, 
    "MasterDb",
    cpu_limit: 60,
    read_iops_limit: 1500,
    write_iops_limit: 1500,
    replica_lag_limit: 10800,
    free_storage_space_limit: 64000000000
  )
 
  resources.master_db do
    type "AWS::RDS::DBInstance"
    deletion_policy "Delete"
    properties do
      engine "mysql"
      engine_version "5.6"
      master_username ref!(:db_user)
      master_user_pasword ref!(:db_password)
      allow_major_version_upgrade true
      backup_retention_period 1
      multi_AZ true
      db_instance_class ref!(:db_instance_class)
      db_parameter_group_name ref!(:db_parameter_group)
      db_security_groups _array(
      	"group",
        join!(
          { options: { delimiter: '-' } }, 
          ref!(:environment), 
          ref!(:application)
        )
      )
      db_name if!(
        :use_db_snapshot,
        ref!("AWS::NoValue"),
        ref!("DbName")
      )
      storage_type "gp2"
      tags _array(
        -> {
          key "Name"
          value ref!("AWS::StackName")
        }
      )
    end
  end

  resources.master_db_host_record do
    type "AWS::Route53::RecordSet"
    properties do
      comment "DNS name for the RDS master"
      hosted_zone_name "#{hosted_zone_name}."
      name join!(
        ref!("AWS::StackName"),
        ".#{hosted_zone_name}"
      )
      resource_records _array(
        attr!(:master_db, "Endpoint.Address")
      )
      TTL 30
      type "CNAME"
    end
  end

  conditions do
    use_db_snapshot not!(
      equals!(
        "",
        ref!(:snapshot_id)
      )
    )
  end

  outputs do
    master_db_hostname do
      description "Hostname for the RDS Master Server"
      value join!(
        ref!("AWS::StackName"),
        ".#{hosted_zone_name}"
      )
    end
  end

end