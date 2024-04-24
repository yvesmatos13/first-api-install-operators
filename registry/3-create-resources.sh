#!/bin/sh

# Login no Openshift
USER=admin
GUIDE="qxhp4"
SANDBOXID=2918
PASSWORDD=gDf2uaDmtUFkg30B
NAMESPACE=registry
API_SERVER=https://api.cluster-$GUIDE.$GUIDE.sandbox$SANDBOXID.opentlc.com:6443

oc project registry

oc apply -f yaml/amq-streams-registry-kafka.yaml

while true; do
    # Run the oc command and store the output in a variable
    oc get kafka my-cluster -o=jsonpath='{.status.conditions[?(@.type=="Ready")].status}'
    REASON=$(oc get kafka my-cluster -o=jsonpath='{.status.conditions[?(@.type=="Ready")].status}' -n $NAMESPACE)
    echo $REASON

    # Check if the condition is met
    if [[ "$REASON" == "True" ]]; then
        echo "Condition met. Kafka Cluster has succeeded."
        break  # Exit the loop
    else
        echo "Kafka Cluster is not yet in Succeeded state. Waiting..."
        sleep 10  # Wait for 10 seconds before checking again
    fi
done

oc apply -f yaml/registry-apicurio-registry.yaml

sleep 10

LABEL=apicurio-registry

pod_name=$(oc get pods -n "$NAMESPACE" -l  app=$LABEL --output jsonpath='{.items[0].metadata.name}')

echo "Pod '$pod_name' is not READY."

oc wait pod/$pod_name --for=condition=Ready --timeout=300s

echo "POD IS RUNNING ++++++++++++++++++++++++++++++++++++"


