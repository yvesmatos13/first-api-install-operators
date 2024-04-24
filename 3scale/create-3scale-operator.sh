#!/bin/bash
# Login no Openshift
USER=admin
GUIDE="qxhp4"
SANDBOXID=2918
PASSWORDD=gDf2uaDmtUFkg30B
API_SERVER=https://api.cluster-$GUIDE.$GUIDE.sandbox$SANDBOXID.opentlc.com:6443
NAMESPACE="3scale"
CSV_NAME="3scale-operator.v0.8.6"

oc login -u $USER -p $PASSWORDD $API_SERVER --insecure-skip-tls-verify=true

oc apply -f yaml/namespace.yaml

oc project 3scale

oc apply -f yaml/operator-group.yaml

oc apply -f yaml/operator.yaml

sleep 20

while true; do
    # Run the oc command and store the output in a variable
    REASON=$(oc get ClusterServiceVersion $CSV_NAME -o jsonpath='{.status.conditions[?(@.phase=="Succeeded")].reason}' -n $NAMESPACE)
    echo $REASON

    # Check if the condition is met
    if [[ "$REASON" == "InstallSucceeded" ]]; then
        echo "Condition met. CSV $CSV_NAME has succeeded."
        break  # Exit the loop
    else
        echo "CSV $CSV_NAME is not yet in Succeeded state. Waiting..."
        sleep 10  # Wait for 10 seconds before checking again
    fi
done

oc apply -f yaml/core-resource-limits.yaml

oc apply -f yaml/api-manager.yaml

sleep 30

cd yaml

pvc_file=pvc.yaml

# Define the new ownerReferences:uid value

new_owner_references_uid=$(oc get apimanager 3scale-apimanager -o=jsonpath='{.metadata.uid}')

echo $new_owner_references_uid

#Update the ownerReferences:uid value in the PVC YAML file
sed  "s/uid: .*/uid: $new_owner_references_uid/" "$pvc_file" > new_pvc.yaml

oc delete pvc system-storage -n 3scale

oc apply -f new_pvc.yaml -n 3scale

oc get pods --namespace=3scale -l deploymentConfig=apicast-production -o jsonpath='{.items[0].metadata.name}'


cd ..

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

















#oc get packagemanifest 3scale-operator -n openshift-marketplace -o jsonpath='{.status.channels[?(@.name=="threescale-2.11")].currentCSV}'

#oc get subscription 3scale-operator -o jsonpath='{.status.conditions[?(@.reason=="AllCatalogSourcesHealthy")].reason}' -n 3scale

#oc get ClusterServiceVersion 3scale-operator.v0.8.6 -o jsonpath='{.status.conditions[?(@.phase=="Succeeded")].reason}' -n 3scale

#oc wait ClusterServiceVersion 3scale-operator.v0.8.6 -o jsonpath='{.status.conditions[?(@.phase=="Succeeded")].reason}' -n 3scale

#oc wait ClusterServiceVersion 3scale-operator.v0.8.6 --for=condition=Succeeded --timeout=300s

#VERIFICAR SE A INSTALAÇÃO CONCLUIU PARA IR PARA A PROXIMA ETAPA.

#oc apply -f core-resource-limits.yaml

#oc apply -f api-manager.yaml

# Replace <pvc-file.yaml> with the actual path to your PVC YAML file
#pvc_file=pvc.yaml

# Define the new ownerReferences:uid value

#new_owner_references_uid=$(oc get apimanager example-apimanager -o=jsonpath='{.metadata.uid}')

# Update the ownerReferences:uid value in the PVC YAML file
#sed  "s/uid: .*/uid: $new_owner_references_uid/" "$pvc_file" > new_pvc.yaml

#oc delete pvc system-storage -n 3scale

#oc apply -f new_pvc.yaml -n 3scale


# oc get packagemanifest 3scale-operator -n openshift-marketplace -o jsonpath='{.status.channels[?(@.name=="threescale-2.13")].currentCSV}'



