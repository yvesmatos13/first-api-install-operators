#!/bin/sh

# Login no Openshift
USER=admin
GUIDE="qxhp4"
SANDBOXID=2918
PASSWORDD=gDf2uaDmtUFkg30B
NAMESPACE=design
API_SERVER=https://api.cluster-$GUIDE.$GUIDE.sandbox$SANDBOXID.opentlc.com:6443


oc login -u $USER -p $PASSWORDD $API_SERVER --insecure-skip-tls-verify=true

CHANNEL=fuse-apicurito-7.12.x

OPERATOR_VERSION=$(oc get packagemanifest fuse-apicurito -n design -o jsonpath='{.status.channels[?(@.name=="$CHANNEL")].currentCSV}')

echo $OPERATOR_VERSION

yaml_file=apicurio-design-operator-chart/values.yaml

yq eval ".spec.startingCSV = \"$OPERATOR_VERSION\"" -i "$yaml_file"

#criação do helm chart para o operador do REGISTRY
CHART_NAME=apicurio-design-operator-chart
helm template $CHART_NAME --output-dir yaml
mv yaml/$CHART_NAME/templates/* yaml/ && rm -rf yaml/$CHART_NAME

cd yaml

oc create -f apicurio-design-namespace.yaml

oc project $NAMESPACE

oc apply -f apicurio-design-operator-group.yaml

oc apply -f apicurio-design-operator.yaml

NAMESPACE_OPERATOR=design

sleep 15

while true; do
    # Your condition checking logic here
    # For demonstration purposes, let's assume a variable named "condition" is being checked
    condition=$(oc get subscription fuse-apicurito -o jsonpath='{.status.conditions[?(@.reason=="AllCatalogSourcesHealthy")].reason}' -n $NAMESPACE_OPERATOR)

    if [ "$condition" == "AllCatalogSourcesHealthy" ]; then
        echo "Condition met, exiting loop"
        break
    else
        echo "Condition not met, waiting for 5 seconds..."
        sleep 5
    fi
done


oc apply -f apicurio-design-instance.yaml


