#!/bin/sh

# Login no Openshift
USER=admin
GUIDE="qxhp4"
SANDBOXID=2918
PASSWORD=gDf2uaDmtUFkg30B
NAMESPACE=registry
API_SERVER=https://api.cluster-$GUIDE.$GUIDE.sandbox$SANDBOXID.opentlc.com:6443


oc login -u $USER -p $PASSWORD $API_SERVER --insecure-skip-tls-verify=true

OPERATOR_VERSION=$(oc get packagemanifest amq-streams -n registry -o jsonpath='{.status.channels[?(@.name=="stable")].currentCSV}')

echo $OPERATOR_VERSION

yaml_file=amq-streams-operator-chart/values.yaml

yq eval ".spec.startingCSV = \"$OPERATOR_VERSION\"" -i "$yaml_file"

#criação do helm chart para o operador do REGISTRY
CHART_NAME=amq-streams-operator-chart
helm template $CHART_NAME --output-dir yaml
mv yaml/$CHART_NAME/templates/* yaml/ && rm -rf yaml/$CHART_NAME

cd yaml

oc create -f amq-streaams-registry-namespace.yaml

oc project $NAMESPACE

oc apply -f amq-streaams-registry-operator-group.yaml

oc apply -f amq-streaams-registry-operator.yaml

NAMESPACE_OPERATOR=openshift-operators

while true; do
    # Your condition checking logic here
    # For demonstration purposes, let's assume a variable named "condition" is being checked
    condition=$(oc get subscription amq-streams -o jsonpath='{.status.conditions[?(@.reason=="AllCatalogSourcesHealthy")].reason}')

    if [ "$condition" == "AllCatalogSourcesHealthy" ]; then
        echo "Condition met, exiting loop"
        break
    else
        echo "Condition not met, waiting for 5 seconds..."
        sleep 5
    fi
done


