#!/bin/bash
REGION=
CLUSTER=
TASK_INDEX=0
SERVICE_NAME=$1
JUMP_HOST=

TASKID=`aws ecs list-tasks --service-name ${SERVICE_NAME} --cluster ${CLUSTER} --region ${REGION} | jq -j ".taskArns[${TASK_INDEX}]"`
INSTANCE_ARN=`aws ecs describe-tasks --tasks ${TASKID} --region ${REGION} --cluster ${CLUSTER} | jq -j '.tasks[0].containerInstanceArn'`
INSTANCE_ID=`aws ecs describe-container-instances --container-instances ${INSTANCE_ARN} --region ${REGION} --cluster ${CLUSTER} | jq -j '.containerInstances[0].ec2InstanceId'`
INSTANCE_IP=`aws ec2 describe-instances --instance-ids ${INSTANCE_ID} | jq -j '.Reservations[0].Instances[0].NetworkInterfaces[0].PrivateIpAddress'`

echo "Connecting to service ${SERVICE_NAME} on ${INSTANCE_ID} @ ${INSTANCE_IP} via ${JUMP_HOST}"
ssh -t -t -A ${JUMP_HOST} ssh ec2-user@${INSTANCE_IP}
