import sys
sys.path.append('cfn-pyplates')

import rdstemplate

cft = rdstemplate.RDSTemplate("MySQL RDS Master + Read Replicas", options)
cft.add_conditions()
cft.add_parameters()
cft.add_db_parameters()

topic_name = cft.get_topic_name()
cft.add_sns_topic(topic_name)
cft.add_master(topic_name)
cft.add_read_replias(options["NumberOfReplicas"], topic_name, options["Skip"])