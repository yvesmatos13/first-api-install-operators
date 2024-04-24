#!/bin/sh

# Login no Openshift
USER=admin
GUIDE="qxhp4"
SANDBOXID=2918
PASSWORDD=gDf2uaDmtUFkg30B
NAMESPACE=microcks
DEPLOYMENT_CONFIG_NAME=sso
API_SERVER=https://api.cluster-$GUIDE.$GUIDE.sandbox$SANDBOXID.opentlc.com:6443


oc login -u $USER -p $PASSWORDD $API_SERVER --insecure-skip-tls-verify=true

MICROCKS_VERSION=$(oc get packagemanifest microcks -n openshift-marketplace -o jsonpath='{.status.channels[?(@.name=="stable")].currentCSV}')

echo $MICROCKS_VERSION

yaml_file=microcks-operator-chart/values.yaml

yq eval ".spec.startingCSV = \"$MICROCKS_VERSION\"" -i "$yaml_file"

MICROCKS_URL=$NAMESPACE.apps.cluster-$GUIDE.$GUIDE.sandbox$SANDBOXID.opentlc.com

yq eval ".microcks.url = \"$MICROCKS_URL\"" -i "$yaml_file"

#TODO GET RHSSO URL
RHSSO_URL=sso-rhsso.apps.cluster-$GUIDE.$GUIDE.sandbox$SANDBOXID.opentlc.com:443/auth

yq eval ".keycloak.url = \"$RHSSO_URL\"" -i "$yaml_file"

#criação do helm chart para o operador do MICROCKS
CHART_NAME=microcks-operator-chart
helm template $CHART_NAME --output-dir yaml
mv yaml/$CHART_NAME/templates/* yaml/ && rm -rf yaml/$CHART_NAME

cd yaml

oc create -f namespace.yaml

oc project $NAMESPACE

oc apply -f operator-group.yaml

oc apply -f operator.yaml


while true; do
    # Your condition checking logic here
    # For demonstration purposes, let's assume a variable named "condition" is being checked
    condition=$(oc get subscription microcks -o jsonpath='{.status.conditions[?(@.reason=="AllCatalogSourcesHealthy")].reason}' -n $NAMESPACE)

    if [ "$condition" == "AllCatalogSourcesHealthy" ]; then
        echo "Condition met, exiting loop"
        break
    else
        echo "Condition not met, waiting for 5 seconds..."
        sleep 5
    fi
done

sleep 30

oc apply -f microcks-reuse-keycloak.yaml

oc get pods -n $NAMESPACE

EXCLUDE_WORDS=("deploy" "hook")

echo "Waiting for all pods in namespace $NAMESPACE not containing '${EXCLUDE_WORDS[@]}' in their name to be ready..."

while true; do
    # Get the list of pods in the namespace not containing the exclude words in their name
    NOT_RUNNING_PODS=$(oc get pods --namespace="$NAMESPACE" --no-headers | awk -v exclude="${EXCLUDE_WORDS[*]}" '{
        exclude_word_found = 0;
        for (i=1; i<=split(exclude, exclude_array); i++) {
            if ($1 ~ exclude_array[i]) {
                exclude_word_found = 1;
                break;
            }
        }
        if (exclude_word_found == 0 && $3 != "Running") {
            print $1;
        }
    }')

    # If there are no pods not in a running state, exit the loop
    if [ -z "$NOT_RUNNING_PODS" ]; then
        echo "All pods in namespace $NAMESPACE not containing '${EXCLUDE_WORDS[@]}' in their name are ready."
        break
    else
        echo "Waiting for the following pods not containing '${EXCLUDE_WORDS[@]}' in their name to be ready:"
        echo "$NOT_RUNNING_PODS"
    fi

    sleep 10  # Wait for 10 seconds before checking again
done
