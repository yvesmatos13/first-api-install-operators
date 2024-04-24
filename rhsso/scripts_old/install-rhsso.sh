#!/bin/sh

# Login no Openshift
USER=admin
GUIDE=qxhp4
SANDBOXID=2550
PASSWORDD=gDf2uaDmtUFkg30B
API_SERVER=https://api.cluster-$qxhp4.$qxhp4.sandbox$SANDBOXID.opentlc.com:6443



NAMESPACE=rhsso
DEPLOYMENT_CONFIG_NAME=sso

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
sleep 10
pod_name=$(oc get pod --selector=deploymentConfig=$DEPLOYMENT_CONFIG_NAME --output jsonpath='{.items[0].metadata.name}' -n $NAMESPACE)

echo "Pod '$pod_name' is not READY."

status=$( oc get pod "$pod_name" -n "$NAMESPACE" --output jsonpath='{.status.containerStatuses[*].ready}')
echo $status

oc wait pod/$pod_name --for=condition=Ready --timeout=300s

cd ../cli

RHSSO_ROUTE=$(oc get route sso  -n rhsso --template='{{.spec.host}}')
RHSSO_ADMIN_USER=admin
RHSSO_ADMIN_PASSWORD=rhsso

#FIM DA ETAPA 4 DO DOCUMENTO


#INICIO DA ETAPA 7 DO DOCUMENTO

#Get RHSSO admin password

sh kcadm.sh config credentials --server https://$RHSSO_ROUTE/auth --realm master  --user $RHSSO_ADMIN_USER --password $RHSSO_ADMIN_PASSWORD

#sh kcadm.sh get realms

#create helms - 3scale-api 3scale-admin 3scale-devportal

sh kcadm.sh create realms -s realm=3scale-api -s enabled=true

sh kcadm.sh create realms -s realm=3scale-admin -s enabled=true

sh kcadm.sh create realms -s realm=3scale-devportal -s enabled=true

#create client for 3scale-api realm

REALM_NAME="3scale-api"
CLIENT_ID="3scale"
NAME="3scale AMP"
DESCRIPTION="3scale AMP"
CONSENT_REQUIRED="false"
CLIENT_PROTOCOL="openid-connect"
ACCESS_TYPE="confidential"
STANDARD_FLOW_ENABLED="false"
IMPLICIT_FLOW_ENABLED="false"
DIRECT_ACCESS_GRANTS_ENABLED="true"
AUTHORIZATION_ENABLED="false"
PUBLIC_CLIENT="false"

sh kcadm.sh create clients -r $REALM_NAME \
    -s clientId="$CLIENT_ID" \
    -s name="$NAME" \
    -s description="$DESCRIPTION" \
    -s consentRequired="$CONSENT_REQUIRED" \
    -s protocol="$CLIENT_PROTOCOL" \
    -s directAccessGrantsEnabled="$DIRECT_ACCESS_GRANTS_ENABLED" \
    -s standardFlowEnabled="$STANDARD_FLOW_ENABLED" \
    -s implicitFlowEnabled="$IMPLICIT_FLOW_ENABLED" \
    -s serviceAccountsEnabled=true \
    -s authorizationServicesEnabled="$AUTHORIZATION_ENABLED" \
    -s publicClient=$PUBLIC_CLIENT

#SERVICE ACCOUNT ROLE
sh kcadm.sh create clients/$CLIENT_ID/service-account-user -r $REALM_NAME \
  --service-account-roles realm-management/manage-clients


#GET CLIENT SECRET

touch secrets.json

sh kcadm.sh get clients -r $REALM_NAME --fields id,clientId,secret >> ../../json/secrets.json

cd ../../json/

json_file="secrets.json"

json_content=$(<"$json_file")


client_id="3scale"

result=$(echo "$json_content" | jq -r --arg client_id "$client_id" '.[] | select(.clientId == $client_id) | .id')

#CLIENT SECRET ID
echo $result

if [ -n "$result" ]; then
  echo "ID for clientId=$client_id: $result"
else
  echo "No matching entry found for clientId=$client_id"
fi

rm -rf secrets.json

cd ../cli

# CRIAÇÃO DE USUÁRIO 
USER_ID=$(sh kcadm.sh create users -r $REALM_NAME \
  -s username=johndoe \
  -s enabled=true \
  -s email=johndoe@foobar.co \
  -s firstName=john \
  -s lastName=doe \
  -s emailVerified=true \
  -s attributes.impersonate=impersonate \
  -i)

echo "User ID: $USER_ID"

# ATRIBUIÇÃO DE PASSWORD PARA O USUÁRIO
sh kcadm.sh set-password -r $REALM_NAME --username johndoe --new-password passwdtemp 
sh kcadm.sh update users/$USER_ID/reset-password -r $REALM_NAME -s type=password -s value=redhat -s temporary=false -n


