#!/bin/sh

# Login no Openshift
USER=admin
GUIDE="qxhp4"
SANDBOXID=2918
PASSWORDD=gDf2uaDmtUFkg30B
NAMESPACE=rhsso
DEPLOYMENT_CONFIG_NAME=sso
API_SERVER=https://api.cluster-$GUIDE.$GUIDE.sandbox$SANDBOXID.opentlc.com:6443


oc login -u $USER -p $PASSWORDD $API_SERVER --insecure-skip-tls-verify=true

RHSSO_VERSION=$(oc get packagemanifest rhsso-operator -n openshift-marketplace -o jsonpath='{.status.channels[?(@.name=="stable")].currentCSV}')

echo $RHSSO_VERSION

yaml_file=rhsso-operator-chart/values.yaml

yq eval ".spec.startingCSV = \"$RHSSO_VERSION\"" -i "$yaml_file"

#criação do helm chart para o operador do RHSSO
CHART_NAME=rhsso-operator-chart
helm template $CHART_NAME --output-dir yaml
mv yaml/$CHART_NAME/templates/* yaml/ && rm -rf yaml/$CHART_NAME

cd yaml

oc apply -f namespace.yaml

oc project $NAMESPACE

oc apply -f operator-group.yaml

oc apply -f operator.yaml


while true; do
    # Your condition checking logic here
    # For demonstration purposes, let's assume a variable named "condition" is being checked
    condition=$(oc get subscription rhsso-operator -o jsonpath='{.status.conditions[?(@.reason=="AllCatalogSourcesHealthy")].reason}' -n $NAMESPACE)

    if [ "$condition" == "AllCatalogSourcesHealthy" ]; then
        echo "Condition met, exiting loop"
        break
    else
        echo "Condition not met, waiting for 5 seconds..."
        sleep 5
    fi
done


# Criação da instância do RHSSO
oc new-app --template=sso75-ocp4-x509-postgresql-persistent --param=SSO_ADMIN_USERNAME=admin --param=SSO_ADMIN_PASSWORD=rhsso -l app=sso -n $NAMESPACE
sleep 20
pod_name=$(oc get pod --selector=deploymentConfig=$DEPLOYMENT_CONFIG_NAME --output jsonpath='{.items[0].metadata.name}' -n $NAMESPACE)

echo "Pod '$pod_name' is not READY."

status=$( oc get pod "$pod_name" -n "$NAMESPACE" --output jsonpath='{.status.containerStatuses[*].ready}')
echo $status

oc wait pod/$pod_name --for=condition=Ready --timeout=300s