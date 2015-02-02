import sys
sys.path.append('cfn-pyplates')

import rdstemplate

cft = rdstemplate.RDSTemplate("MySQL RDS Read Replicas", options)
cft.add_conditions()
cft.add_parameters()
cft.parameters.add(
	Parameter(
		"MasterDB", "String",
		{
			"Description": "replication source"
		}		
	)
)
cft.add_db_parameters()

topic_name = cft.get_topic_name()
cft.add_sns_topic(topic_name)
cft.add_read_replias(options["NumberOfReplicas"], topic_name)
