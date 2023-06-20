export ENVIRONMENT_ID="env-XXXX"
export CLUSTER_ID="lkc-XXXX"
export SA_NAME="masterSA_${ENVIRONMENT_ID}_${CLUSTER_ID}"


confluent environment use ${ENVIRONMENT_ID}
confluent kafka cluster use ${CLUSTER_ID}

SR_OUTPUT=$(confluent schema-registry cluster describe -o json)
if [ "$SR_OUTPUT" == "" ]; then
 echo "***********"
 echo "Create Schema Registry First"
 echo "***********"
 exit
else
 echo "Schema Registry is enabled"
fi

SR_ID=$(echo "$SR_OUTPUT" | jq -r ".cluster_id")
SR_ENDPOINT=$(echo "$SR_OUTPUT" | jq -r ".endpoint_url")
SA_OUTPUT=$(confluent iam service-account create ${SA_NAME} --description "master service account ${ENVIRONMENT_ID} ${CLUSTER_ID}"  -o json)
SA_ID=$(echo "$SA_OUTPUT" | jq -r ".id")
echo creating master service account: ${SA_ID}

echo creating ACLSs for master service account: ${SA_ID}
confluent kafka acl create --allow --service-account ${SA_ID} --operations CREATE --topic '*'
confluent kafka acl create --allow --service-account ${SA_ID} --operations DELETE --topic '*'
confluent kafka acl create --allow --service-account ${SA_ID} --operations WRITE --topic '*'
confluent kafka acl create --allow --service-account ${SA_ID} --operations READ --topic '*'
confluent kafka acl create --allow --service-account ${SA_ID} --operations DESCRIBE --topic '*'
confluent kafka acl create --allow --service-account ${SA_ID} --operations DESCRIBE_CONFIGS --topic '*'

confluent kafka acl create --allow --service-account ${SA_ID} --operations READ --consumer-group '*'
confluent kafka acl create --allow --service-account ${SA_ID} --operations WRITE --consumer-group '*'
confluent kafka acl create --allow --service-account ${SA_ID} --operations CREATE --consumer-group '*'
confluent kafka acl create --allow --service-account ${SA_ID} --operations DESCRIBE --consumer-group '*'

confluent kafka acl create --allow --service-account ${SA_ID} --operations DESCRIBE --transactional-id '*'
confluent kafka acl create --allow --service-account ${SA_ID} --operations WRITE --transactional-id '*'

confluent kafka acl create --allow --service-account ${SA_ID} --operations IDEMPOTENT-WRITE --cluster-scope
confluent kafka acl create --allow --service-account ${SA_ID} --operations DESCRIBE --cluster-scope


echo creating API Key for service account: ${SA_ID}
echo creating KAFKA API Key 
confluent api-key create --resource ${CLUSTER_ID} --service-account ${SA_ID} --description "Kafka Key"
echo creating Schema Registry Key
confluent iam rbac role-binding create --principal User:${SA_ID} --role ResourceOwner --environment ${ENVIRONMENT_ID} --schema-registry-cluster ${SR_ID} --resource Subject:*
confluent api-key create --resource ${SR_ID} --service-account ${SA_ID} --description "Schema Registry Key"

echo "Environment ID: $ENVIRONMENT_ID"
echo "Schema Registry ID: $SR_ID"
echo "Schema Registry Endpoint: $SR_ENDPOINT"
echo "Cluster ID: $CLUSTER_ID"
echo "Service Account Name: $SA_NAME"
echo "Service Account ID: $SA_ID"

