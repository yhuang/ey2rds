topic_name = "AlarmTopic" + Array.new(8) { [*"A".."Z", *"0".."9"].sample }.join

SparkleFormation.dynamic(:alarms) do |_name, _config={}|

  resources(topic_name) do
    type "AWS::SNS::Topic"
    properties do
      display_name ref!("AWS::StackName")
      subscription _array(
        -> {
          end_point "jhuang@bleacherreport.com"
          protocol "email"
        }
      )
    end
  end

  resources("#{_name}CPUAlarmHigh") do
    type "AWS::CloudWatch::Alarm"
    properties do
      alarm_actions _array(ref!(topic_name))
      alarm_description join!(
        "Alarm if ",
        ref!(_name),
        " CPU > #{_config[:cpu_limit]}% for 5 minutes"
      )
      comparison_operator "GreaterThanThreshold"
      dimensions _array(
        -> {
          name "DBInstanceIdentifier"
          value ref!(_name)
        }
      )
      evaluation_periods 5
      metric_name "CPUUtilization"
      namespace "AWS/RDS"
      period 60
      statistic "Average"
      threshold _config[:cpu_limit]
    end
  end

  resources("#{_name}ReadIOPSHigh") do
    type "AWS::CloudWatch::Alarm"
    properties do
      alarm_actions _array(ref!(topic_name))
      alarm_description join!(
        "Alarm if ",
        ref!(_name),
        " ReadIOPS > #{_config[:read_iops_limit]} IOPS for 5 minutes"
      )
      comparison_operator "GreaterThanThreshold"
      dimensions _array(
        -> {
          name "DBInstanceIdentifier"
          value ref!(_name)
        }
      )
      evaluation_periods 5
      metric_name "ReadIOPS"
      namespace "AWS/RDS"
      period 60
      statistic "Average"
      threshold _config[:read_iops_limit]
    end
  end

  resources("#{_name}WriteIOPSHigh") do
    type "AWS::CloudWatch::Alarm"
    properties do
      alarm_actions _array(ref!(topic_name))
      alarm_description join!(
        "Alarm if ",
        ref!(_name),
        " WriteIOPS > #{_config[:write_iops_limit]} IOPS for 5 minutes"
      )
      comparison_operator "GreaterThanThreshold"
      dimensions _array(
        -> {
          name "DBInstanceIdentifier"
          value ref!(_name)
        }
      )
      evaluation_periods 5
      metric_name "WriteIOPS"
      namespace "AWS/RDS"
      period 60
      statistic "Average"
      threshold _config[:write_iops_limit]
    end
  end

  resources("#{_name}FreeStorageSpaceLow") do
    type "AWS::CloudWatch::Alarm"
    properties do
      alarm_actions _array(ref!(topic_name))
      alarm_description join!(
        "Alarm if ",
        ref!(_name),
        " storage space <= #{_config[:free_storage_space_limit]} bytes for 5 minutes"
      )
      comparison_operator "LessThanOrEqualToThreshold"
      dimensions _array(
        -> {
          name "DBInstanceIdentifier"
          value ref!(_name)
        }
      )
      evaluation_periods 5
      metric_name "FreeStorageSpace"
      namespace "AWS/RDS"
      period 60
      statistic "Average"
      threshold _config[:free_storage_space_limit]
    end
  end

  if _name =~ /replica/i
    resources("#{_name}ReplicaLagHigh") do
      type "AWS::CloudWatch::Alarm"
      properties do
        alarm_actions _array(ref!(topic_name))
        alarm_description join!(
          "Alarm if ",
          ref!(_name),
          " lag > #{_config[:replica_lag_limit]} seconds for 5 minutes"
        )
        comparison_operator "GreaterThanThreshold"
        dimensions _array(
          -> {
            name "DBInstanceIdentifier"
            value ref!(_name)
          }
        )
        evaluation_periods 5
        metric_name "ReplicaLag"
        namespace "AWS/RDS"
        period 60
        statistic "Average"
        threshold _config[:replica_lag_limit]
      end
    end
  end

end